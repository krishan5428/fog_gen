<?php
/**
 * FOGSHIELD — Per-App 4G/MQTT Alert Handler
 *
 * Ported from firenex/mqtt_4gcom_alert.php: tables, function prefixes
 * (fsh4g_/fogshield_) and the FCM project ('fogshield') renamed; users and
 * tokens come from tbl_fogshield_users / tbl_fogshield_device_tokens (FogShield own users, as FireNex).
 * Function names must stay unique: the root router can load this file and
 * firenex/connect handlers in the same request.
 *
 * Called by the root router (app_services/mqtt_4gcom_alert.php) via require.
 * Receives from root router scope:
 * $con      — active SQL Server connection
 * $imei     — device IMEI
 * $topic    — MQTT topic
 * $packet   — raw ST* packet string
 * $routeRow — ['panel_id', 'app_name', 'usr_id'] from tbl_pnl_map
 *
 * Still directly reachable at this same URL for direct testing/back-compat,
 * in which case it falls back to resolving imei -> panel itself.
 *
 * fogshield (like firenex) has no panel-sharing feature (unlike connect), so notifications
 * only ever go to the single owning usr_id — no all_user_ids fan-out.
 */
require_once(__DIR__ . '/event_filter.php');
require_once(__DIR__ . '/log_helper.php');
require_once(__DIR__ . '/config_loader.php');

function fsh4g_log($msg) {
    $dir = fogshield_log_root() . '/mqtt/4gcom';
    if (!is_dir($dir)) mkdir($dir, 0777, true);
    file_put_contents($dir . '/4gcom_' . date('Y-m-d') . '.txt',
        "[" . date('H:i:s') . "] $msg" . PHP_EOL, FILE_APPEND);
}

// ── Auto-purge old mqtt/4gcom logs (once per day, 30-day retention) ────────
(function () {
    $dir = fogshield_log_root() . '/mqtt/4gcom';
    $sentinel = $dir . '/.last_purge';
    if (is_file($sentinel) && trim(file_get_contents($sentinel)) === date('Y-m-d')) {
        return; // already ran today
    }
    $cutoff = strtotime('-30 days');
    foreach (glob($dir . '/*.txt') as $file) {
        if (preg_match('/(\d{4}-\d{2}-\d{2})/', basename($file), $m)) {
            if (strtotime($m[1]) < $cutoff) {
                @unlink($file);
            }
        }
    }
    if (!is_dir($dir)) mkdir($dir, 0777, true);
    file_put_contents($sentinel, date('Y-m-d'));
})();

// ── Dashboard (001) — Application Login Alert, 15-min dedup ────────────────
function fsh4g_dashboardLoginAlert($con, $usr_id, $panel_id, $site_name, $c_on) {
    // Compare against $c_on (PHP-computed) rather than SQL Server's GETDATE()
    // — if the app and DB server clocks/timezones ever drift, a GETDATE()
    // comparison against a PHP-written c_on can end up permanently
    // true/false, silently disabling this alert forever for a panel.
    $loginCheckStmt = sqlsrv_query($con,
        "SELECT TOP 1 id FROM tbl_fogshield_logs
         WHERE panel_id = ? AND usr_id = ? AND event_code = 'SETTING' AND event_name = 'SYNC:DASHBOARD_4G' AND DATEDIFF(minute, c_on, ?) < 15",
        [$panel_id, $usr_id, $c_on]
    );
    $recentlyCalled = $loginCheckStmt ? (sqlsrv_fetch_array($loginCheckStmt, SQLSRV_FETCH_ASSOC) !== null) : false;

    sqlsrv_query($con,
        "INSERT INTO tbl_fogshield_logs (usr_id, panel_id, site_name, event_code, event_name, status, c_on)
         VALUES (?, ?, ?, ?, ?, ?, ?)",
        [$usr_id, $panel_id, $site_name, 'SETTING', 'SYNC:DASHBOARD_4G', 'LOGGED', $c_on]
    );

    // Distinct from the panel's own automatic check-in (which only updates
    // tbl_fogshield_4gcom_panel_state.updated_at) — this marks a genuine
    // app-initiated dashboard open, used by the watchdog to tell the two apart.
    sqlsrv_query($con,
        "UPDATE tbl_panel_fogshield SET last_login_at = ? WHERE pnl_acc_no = ?",
        [$c_on, $panel_id]
    );

    if ($recentlyCalled) {
        fsh4g_log("Application Login: deduped, already alerted within 15 min");
        return;
    }

    $nameStmt  = sqlsrv_query($con, "SELECT TOP 1 name FROM tbl_fogshield_users WHERE usr_id = ?", [$usr_id]);
    $nameRow   = $nameStmt ? sqlsrv_fetch_array($nameStmt, SQLSRV_FETCH_ASSOC) : null;
    $user_name = !empty($nameRow['name']) ? $nameRow['name'] : 'User';

    $title       = "Alert — $site_name";
    $displayTime = date('h:i A d/m/Y');
    $event_name  = "Application Logged in by $user_name";
    $body        = "$event_name\n$displayTime";

    $tokStmt = sqlsrv_query($con, "SELECT device_token FROM tbl_fogshield_device_tokens WHERE user_id = ?", [$usr_id]);
    $tokens = [];
    if ($tokStmt) {
        while ($r = sqlsrv_fetch_array($tokStmt, SQLSRV_FETCH_ASSOC)) {
            if (!empty($r['device_token'])) $tokens[] = $r['device_token'];
        }
    }
    $tokens = array_unique($tokens);

    $logStmt = sqlsrv_query($con,
        "INSERT INTO tbl_fogshield_logs
         (usr_id, panel_id, site_name, event_code, event_name, device_token, notification_title, notification_body, status, c_on)
         OUTPUT INSERTED.id
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [$usr_id, $panel_id, $site_name, 'UTILITY_LOGIN', $event_name, fogshield_truncateTokenList($tokens), $title, $body, empty($tokens) ? 'NO_TOKENS' : 'PENDING', $c_on]
    );
    $log_id = null;
    if ($logStmt && $logRow = sqlsrv_fetch_array($logStmt, SQLSRV_FETCH_ASSOC)) {
        $log_id = $logRow['id'];
    }

    if (empty($tokens)) {
        fsh4g_log("Application Login: No tokens");
        return;
    }

    $customData = ['panel_id' => $panel_id, 'site_name' => $site_name, 'event' => 'UTILITY_LOGIN', 'dt' => $displayTime, 'app' => 'fogshield', 'log_id' => $log_id !== null ? (string)$log_id : ''];
    $result = sendFCMNotification($tokens, $title, $body, $customData, 'fogshield');

    foreach ($result['invalid_tokens'] as $badToken) {
        sqlsrv_query($con, "DELETE FROM tbl_fogshield_device_tokens WHERE device_token = ?", [$badToken]);
    }

    if ($log_id) {
        $final = $result['sent'] > 0 ? 'SENT' : 'FAILED';
        sqlsrv_query($con, "UPDATE tbl_fogshield_logs SET status=?, fcm_response=? WHERE id=?",
            [$final, "sent={$result['sent']} failed={$result['failed']}", $log_id]);
    }
    fsh4g_log("Application Login FCM sent: sent={$result['sent']} failed={$result['failed']}");
}

// ── Dashboard (001) — state-diff alerts (arm/disarm, panic, mains, battery, zones) ──
function fsh4g_dashboardStateDiff($con, $usr_id, $panel_id, $site_name, $imei,
    $securityState, $powerStatus, $batteryStatus, $panicState, $deviceMode, $inputs, $c_on) {

    $stmt = sqlsrv_query($con,
        "SELECT security_state, power_status, battery_status, panic_state, device_mode, input_states FROM tbl_fogshield_4gcom_panel_state WHERE panel_id = ?",
        [$panel_id]
    );
    $prev = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;

    $inputStatesStr = implode(',', array_map(fn($i) => $i['status'], $inputs));

    if (!$prev) {
        // First snapshot for this panel — record baseline, don't alert
        sqlsrv_query($con,
            "INSERT INTO tbl_fogshield_4gcom_panel_state (panel_id, security_state, power_status, battery_status, panic_state, device_mode, input_states, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [$panel_id, $securityState, $powerStatus, $batteryStatus, $panicState, $deviceMode, $inputStatesStr, $c_on]
        );
        return;
    }

    $changes = [];
    if ($securityState !== '' && $securityState !== (string)$prev['security_state']) {
        $changes[] = ['security_state', $securityState, ''];
    }
    if ($powerStatus !== (string)$prev['power_status']) {
        $changes[] = ['power_status', $powerStatus, ''];
    }
    if ($batteryStatus !== (string)$prev['battery_status']) {
        $changes[] = ['battery_status', $batteryStatus, ''];
    }
    if ($panicState !== (string)$prev['panic_state']) {
        $changes[] = ['panic_state', $panicState, ''];
    }
    if ($deviceMode !== '' && $deviceMode !== (string)$prev['device_mode']) {
        $changes[] = ['device_mode', $deviceMode, ''];
    }

    $prevInputs = ($prev['input_states'] !== null && $prev['input_states'] !== '')
        ? explode(',', $prev['input_states']) : [];
    foreach ($inputs as $idx => $input) {
        $prevStatus = $prevInputs[$idx] ?? null;
        if ($prevStatus !== null && $prevStatus !== $input['status']) {
            $changes[] = ['input_state', $input['status'], $input['name']];
        }
    }

    foreach ($changes as [$field, $code, $extra]) {
        $notification = FogshieldEventFilter::fourgDashboard($field, $code, $site_name, $extra);
        if ($notification === null) {
            fsh4g_log("SKIP: $field=$code not notifiable");
            continue;
        }

        $title     = $notification['title'];
        $body      = $notification['body'];
        $eventCode = $notification['event'];

        // Zone/input alerts can also be reported by the TCP/SIA listener
        // (sync_panel_log.php) as NBA*/NBR* for the same physical trip.
        // Debounce against that so the user doesn't get two pushes. This
        // packet's own event_code has no zone identity (it's just
        // INPUT_STATE_1/0), so the match is direction-only — an Alert
        // here won't be suppressed by an unrelated zone's Restore, or
        // vice versa, even though it can't tell zones apart from each other.
        $is_duplicate_zone_alert = ($field === 'input_state' && fogshield_recentZoneAlertExists($con, $panel_id, $code === '1'));

        $tokStmt = sqlsrv_query($con, "SELECT device_token FROM tbl_fogshield_device_tokens WHERE user_id = ?", [$usr_id]);
        $tokens = [];
        if ($tokStmt) {
            while ($r = sqlsrv_fetch_array($tokStmt, SQLSRV_FETCH_ASSOC)) {
                if (!empty($r['device_token'])) $tokens[] = $r['device_token'];
            }
        }
        $tokens = array_unique($tokens);

        $rowStatus = $is_duplicate_zone_alert ? 'SKIPPED_DUPLICATE' : (empty($tokens) ? 'NO_TOKENS' : 'PENDING');

        $logStmt = sqlsrv_query($con,
            "INSERT INTO tbl_fogshield_logs
             (usr_id, panel_id, site_name, event_code, event_name, device_token, notification_title, notification_body, status, c_on)
             OUTPUT INSERTED.id
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [$usr_id, $panel_id, $site_name, $eventCode, explode("\n", $body)[0], fogshield_truncateTokenList($tokens), $title, $body, $rowStatus, $c_on]
        );
        $log_id = null;
        if ($logStmt && $logRow = sqlsrv_fetch_array($logStmt, SQLSRV_FETCH_ASSOC)) {
            $log_id = $logRow['id'];
        }

        if ($is_duplicate_zone_alert) {
            fsh4g_log("FCM SKIPPED ($eventCode): duplicate zone alert already sent via another pipeline within debounce window");
            continue;
        }

        if (empty($tokens)) {
            fsh4g_log("FCM SKIPPED ($eventCode): no tokens for usr_id=$usr_id");
            continue;
        }

        $customData = ['panel_id' => $panel_id, 'imei' => $imei, 'site_name' => $site_name, 'event' => $eventCode, 'app' => 'fogshield', 'log_id' => $log_id !== null ? (string)$log_id : ''];
        $result = sendFCMNotification($tokens, $title, $body, $customData, 'fogshield');

        foreach ($result['invalid_tokens'] as $badToken) {
            sqlsrv_query($con, "DELETE FROM tbl_fogshield_device_tokens WHERE device_token = ?", [$badToken]);
        }

        if ($log_id) {
            $final = $result['sent'] > 0 ? 'SENT' : 'FAILED';
            sqlsrv_query($con, "UPDATE tbl_fogshield_logs SET status=?, fcm_response=? WHERE id=?",
                [$final, "sent={$result['sent']} failed={$result['failed']}", $log_id]);
        }
        fsh4g_log("FCM RESULT ($eventCode): sent={$result['sent']} failed={$result['failed']} tokens=" . count($tokens));
    }

    sqlsrv_query($con,
        "UPDATE tbl_fogshield_4gcom_panel_state SET security_state=?, power_status=?, battery_status=?, panic_state=?, device_mode=?, input_states=?, updated_at=? WHERE panel_id=?",
        [$securityState, $powerStatus, $batteryStatus, $panicState, $deviceMode, $inputStatesStr, $c_on, $panel_id]
    );
}

// ── Shared FCM sender for settings/control write-response packets ─────────
function fsh4g_sendSettingsNotification($con, $usr_id, $panel_id, $site_name, $imei, $packetId, $notification, $c_on) {
    $title     = $notification['title'];
    $body      = $notification['body'];
    $eventCode = $notification['event'];

    $tokStmt = sqlsrv_query($con, "SELECT device_token FROM tbl_fogshield_device_tokens WHERE user_id = ?", [$usr_id]);
    $tokens = [];
    if ($tokStmt) {
        while ($r = sqlsrv_fetch_array($tokStmt, SQLSRV_FETCH_ASSOC)) {
            if (!empty($r['device_token'])) $tokens[] = $r['device_token'];
        }
    }
    $tokens = array_unique($tokens);

    $logStmt = sqlsrv_query($con,
        "INSERT INTO tbl_fogshield_logs
         (usr_id, panel_id, site_name, event_code, event_name, device_token, notification_title, notification_body, status, c_on)
         OUTPUT INSERTED.id
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [$usr_id, $panel_id, $site_name, $eventCode, explode("\n", $body)[0], fogshield_truncateTokenList($tokens), $title, $body, empty($tokens) ? 'NO_TOKENS' : 'PENDING', $c_on]
    );
    $log_id = null;
    if ($logStmt && $logRow = sqlsrv_fetch_array($logStmt, SQLSRV_FETCH_ASSOC)) {
        $log_id = $logRow['id'];
    }

    if (empty($tokens)) {
        fsh4g_log("FCM SKIPPED ($eventCode): no tokens for usr_id=$usr_id");
        return;
    }

    $customData = ['panel_id' => $panel_id, 'imei' => $imei, 'site_name' => $site_name, 'event_code' => $eventCode, 'app' => 'fogshield', 'log_id' => $log_id !== null ? (string)$log_id : ''];
    $result = sendFCMNotification($tokens, $title, $body, $customData, 'fogshield');

    foreach ($result['invalid_tokens'] as $badToken) {
        sqlsrv_query($con, "DELETE FROM tbl_fogshield_device_tokens WHERE device_token = ?", [$badToken]);
    }

    if ($log_id) {
        $final = $result['sent'] > 0 ? 'SENT' : 'FAILED';
        sqlsrv_query($con, "UPDATE tbl_fogshield_logs SET status=?, fcm_response=? WHERE id=?",
            [$final, "sent={$result['sent']} failed={$result['failed']}", $log_id]);
    }
    fsh4g_log("FCM RESULT ($eventCode): sent={$result['sent']} failed={$result['failed']} tokens=" . count($tokens));
}

// ══════════════════════════════════════════════════════════════════════════════

$__standalone = !isset($routeRow);

function fsh4g_finish($val, $standalone, $con) {
    global $json;
    $json = $val;
    if ($standalone) {
        echo json_encode($json);
        sqlsrv_close($con);
        exit;
    }
}

if (!isset($con)) {
    require_once("../../common/db.php");
}

if ($__standalone) {
    $raw  = file_get_contents('php://input');
    $data = json_decode($raw, true);

    fsh4g_log("Raw: $raw");

    // Shared secret from config.php (g4_secret). Blank → refuse everything.
    $fsh4g_secret = fogshield_config('g4_secret');
    if (empty($data) || $fsh4g_secret === ''
        || !hash_equals($fsh4g_secret, (string)($data['secret'] ?? ''))) {
        http_response_code(401);
        fsh4g_log("Unauthorized");
        fsh4g_finish(['status' => false, 'msg' => 'Unauthorized'], true, $con);
        return;
    }

    $imei   = trim($data['imei']   ?? '');
    $topic  = trim($data['topic']  ?? '');
    $packet = trim($data['packet'] ?? '');

    if (empty($imei) || empty($packet)) {
        fsh4g_log("ERROR: Missing data");
        fsh4g_finish(['status' => false, 'msg' => 'Missing data'], true, $con);
        return;
    }

    $panelStmt = sqlsrv_query($con, "SELECT pnl_acc_no, usr_id FROM tbl_panel_fogshield WHERE panel_imei = ? AND " . fogshield_live_status_sql(), [$imei]);
    $panelRow  = $panelStmt ? sqlsrv_fetch_array($panelStmt, SQLSRV_FETCH_ASSOC) : null;
    if (!$panelRow) {
        fsh4g_log("No panel for IMEI=$imei");
        fsh4g_finish(['status' => false, 'msg' => 'Panel not found'], true, $con);
        return;
    }
    $routeRow = ['panel_id' => $panelRow['pnl_acc_no'], 'usr_id' => $panelRow['usr_id']];
}

// Panel-offline watchdog disabled: packet 001 (dashboard) is only ever sent
// as a response to an app-initiated read while the dashboard screen is open
// (per 4GCOM_PACKET_COMMANDS_REFERENCE.txt — there is no autonomous periodic
// check-in from the panel over MQTT), so tbl_fogshield_4gcom_panel_state.updated_at
// really measures "was the dashboard screen recently opened," not "is the
// panel connected." That produced false "Panel Offline" alerts for panels
// that were fine but simply not being actively viewed. Leaving
// fogshield_runPanelWatchdogSweep()/fogshield_notifyPanelOffline() in
// log_helper.php in place, just not calling it — re-enable only once there's
// a real panel-originated heartbeat to key off of.

fsh4g_log("IMEI=$imei topic=$topic");
fsh4g_log("Packet=$packet");

// Parse ST Packet
$clean        = str_replace(['ST*', '*ED'], '', $packet);
$parts        = explode('$', $clean);
$packetType   = $parts[2] ?? '';
$responseType = $parts[3] ?? '';
$packetId     = $parts[4] ?? '';
$functionId   = $parts[5] ?? '';

fsh4g_log("Parsed — packetType=$packetType packetId=$packetId functionId=$functionId");

if ($packetType !== '03' && $packetType !== '04') {
    fsh4g_log("Skipping — not a response");
    fsh4g_finish(['status' => true, 'msg' => 'Skipped'], $__standalone, $con);
    return;
}

if ($responseType === '00') {
    fsh4g_log("Skipping — Nack");
    fsh4g_finish(['status' => true, 'msg' => 'Nack skipped'], $__standalone, $con);
    return;
}

if ($packetType === '03' && $packetId !== '001') {
    fsh4g_log("Read response packetId=$packetId — silent");
    fsh4g_finish(['status' => true, 'msg' => 'Skipped'], $__standalone, $con);
    return;
}

$panel_id = $routeRow['panel_id'];
$usr_id   = (int)$routeRow['usr_id'];
$c_on     = date('Y-m-d H:i:s');

$siteStmt = sqlsrv_query($con, "SELECT TOP 1 site_name, pnl_type FROM tbl_panel_fogshield WHERE pnl_acc_no = ? AND " . fogshield_live_status_sql() . " ORDER BY pnl_id DESC", [$panel_id]);
$siteRow  = $siteStmt ? sqlsrv_fetch_array($siteStmt, SQLSRV_FETCH_ASSOC) : null;
$site_name = !empty($siteRow['site_name']) ? $siteRow['site_name'] : 'Site';
$pnl_type  = $siteRow['pnl_type'] ?? '';

fsh4g_log("Panel: panel_id=$panel_id site=$site_name usr_id=$usr_id pnl_type=$pnl_type");

// MQTT/4G is only authoritative for panels registered as 4GCOM — TCP panels
// (FIRE PANEL / FIRE DIALERS, i.e. the "I" and "G4I" variants) report over
// sync_panel_log.php instead. A stray/mis-provisioned MQTT packet for a
// non-4GCOM panel_id must never reach tbl_fogshield_logs or FCM.
if ($pnl_type !== '4GCOM') {
    fsh4g_log("SKIP: panel_id=$panel_id registered as pnl_type='$pnl_type', not 4GCOM — MQTT packet ignored");
    fsh4g_finish(['status' => true, 'msg' => 'Not a 4GCOM panel — skipped'], $__standalone, $con);
    return;
}

// ── Dashboard (001) read response ─────────────────────────────────────────
if ($packetId === '001' && $packetType === '03') {
    $deviceMode    = trim($parts[8]  ?? '');
    $powerStatus   = trim($parts[9]  ?? '0');
    $batteryStatus = trim($parts[10] ?? '0');
    $panicState    = trim($parts[11] ?? '0');
    $securityState = trim($parts[12] ?? '');
    $inputDataRaw  = trim($parts[14] ?? '');

    $inputs = [];
    if ($inputDataRaw !== '') {
        foreach (explode(';', $inputDataRaw) as $entry) {
            $seg = explode('|', $entry, 2);
            if (count($seg) === 2) {
                $inputs[] = ['status' => trim($seg[0]), 'name' => trim($seg[1])];
            }
        }
    }

    fsh4g_dashboardLoginAlert($con, $usr_id, $panel_id, $site_name, $c_on);
    fsh4g_dashboardStateDiff($con, $usr_id, $panel_id, $site_name, $imei,
        $securityState, $powerStatus, $batteryStatus, $panicState, $deviceMode, $inputs, $c_on);

    fsh4g_log("Dashboard processed: security=$securityState power=$powerStatus battery=$batteryStatus panic=$panicState deviceMode=$deviceMode inputs=" . count($inputs));

    fsh4g_finish(['status' => true, 'msg' => 'Dashboard processed'], $__standalone, $con);
    return;
}

// ── Write responses (04) — settings / control notifications ───────────────
if ($packetType === '04') {
    fsh4g_log("Write response received: packetId=$packetId");

    if ($packetId === '011') {
        // PHP-computed $c_on rather than GETDATE() — see the note in
        // fsh4g_dashboardLoginAlert() for why mixing the two is unsafe.
        $dedupStmt = sqlsrv_query($con,
            "SELECT TOP 1 id FROM tbl_fogshield_logs
             WHERE panel_id = ? AND event_code = 'PKT011_OUTPUT_SETTINGS'
             AND DATEDIFF(second, c_on, ?) < 30",
            [$panel_id, $c_on]
        );
        if ($dedupStmt && sqlsrv_fetch_array($dedupStmt, SQLSRV_FETCH_ASSOC) !== null) {
            fsh4g_log("PKT011 dedup — already sent within 30s, skipping");
            fsh4g_finish(['status' => true, 'msg' => 'Dedup skipped'], $__standalone, $con);
            return;
        }
    }

    $notification = FogshieldEventFilter::fourgWriteResponse($packetId, $parts, $site_name);

    // The app pulses outputs ON then OFF 9s later; both acks look identical
    // ($04$01$012$08N), so only the first push per output within 12s goes out.
    if ($packetId === '012' && $notification !== null) {
        $dedupStmt = sqlsrv_query($con,
            "SELECT TOP 1 id FROM tbl_fogshield_logs
             WHERE panel_id = ? AND event_code = ?
             AND DATEDIFF(second, c_on, ?) < 12",
            [$panel_id, $notification['event'], $c_on]
        );
        if ($dedupStmt && sqlsrv_fetch_array($dedupStmt, SQLSRV_FETCH_ASSOC) !== null) {
            fsh4g_log("PKT012 dedup — {$notification['event']} already sent within 12s, skipping");
            fsh4g_finish(['status' => true, 'msg' => 'Dedup skipped'], $__standalone, $con);
            return;
        }
    }

    if ($notification === null) {
        fsh4g_log("SKIP: packetId=$packetId — no notification defined in XML");
        fsh4g_finish(['status' => true, 'msg' => 'No notification'], $__standalone, $con);
        return;
    }

    fsh4g_log("NOTIFY: packetId=$packetId → title='{$notification['title']}' body='{$notification['body']}'");
    fsh4g_sendSettingsNotification($con, $usr_id, $panel_id, $site_name, $imei, $packetId, $notification, $c_on);

    fsh4g_finish(['status' => true, 'msg' => 'Settings notification sent'], $__standalone, $con);
    return;
}

fsh4g_log("Unhandled: packetType=$packetType packetId=$packetId");
fsh4g_finish(['status' => true, 'msg' => 'Unhandled'], $__standalone, $con);
?>
