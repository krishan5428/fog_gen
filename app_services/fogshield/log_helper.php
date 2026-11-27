<?php
// log_helper.php — logging for the fogshield/ folder.
// Date-stamped files under fogshield/logs/<category>/, purged after 30 days
// (checked once per day per category). Same scheme as firenex/log_helper.php.

// Log root: fogshield/logs, or FOGSHIELD_LOG_DIR when set (tests).
function fogshield_log_root() {
    return getenv('FOGSHIELD_LOG_DIR') ?: __DIR__ . '/logs';
}

function fogshield_log_write($category, $entry) {
    $dir = fogshield_log_root() . '/' . $category;
    if (!is_dir($dir)) mkdir($dir, 0777, true);
    file_put_contents($dir . '/' . $category . '_' . date('Y-m-d') . '.txt', $entry, FILE_APPEND);
    fogshield_log_purge($category);
}

// Structured entry: "[time] message" + optional JSON data + separator.
// Never pass passwords or admin codes in $data.
function fogshield_log($category, $message, $data = []) {
    $entry = '[' . date('Y-m-d H:i:s') . "] $message\n";
    if (!empty($data)) {
        $entry .= "Data: " . json_encode($data, JSON_PRETTY_PRINT) . "\n";
    }
    $entry .= str_repeat('-', 80) . "\n";
    fogshield_log_write($category, $entry);
}

// tbl_fogshield_logs.device_token has the FireNex column size (varchar 255):
// join tokens through this so a user with many devices can't make the
// INSERT fail.
function fogshield_truncateTokenList($tokens) {
    $str = implode(',', $tokens);
    if (strlen($str) > 250) {
        $str = substr($str, 0, 247) . '...';
    }
    return $str;
}

function fogshield_log_purge($category) {
    $dir = fogshield_log_root() . '/' . $category;
    $sentinel = $dir . '/.last_purge';
    if (file_exists($sentinel) && date('Y-m-d', filemtime($sentinel)) === date('Y-m-d')) {
        return;
    }
    $cutoff = time() - 30 * 24 * 60 * 60;
    foreach (glob($dir . '/*.txt') ?: [] as $file) {
        if (filemtime($file) < $cutoff) @unlink($file);
    }
    @touch($sentinel);
}

// Panel statuses that mean "gone" (soft-deleted rows stay for id reuse).
function fogshield_live_status_sql($alias = '') {
    $col = $alias === '' ? 'status' : "$alias.status";
    return "ISNULL(LOWER(LTRIM(RTRIM($col))), '') NOT IN ('inactive', 'deleted')";
}

// ── Alert helpers ported from firenex/log_helper.php (names/tables renamed) ──

function fogshield_recentZoneAlertExists($con, $panel_id, $isAlert, $zoneSlot = null, $windowSeconds = 10) {
    $now = date('Y-m-d H:i:s');

    if ($zoneSlot !== null) {
        $slotDigits = ($zoneSlot === 'fire') ? '5' : (string)$zoneSlot;
        $siaCode    = ($isAlert ? 'NBA10' : 'NBR10') . $slotDigits;
        $siaOperator = '=';
    } else {
        $siaCode     = $isAlert ? 'NBA%' : 'NBR%';
        $siaOperator = 'LIKE';
    }
    $mqttCode = $isAlert ? 'INPUT_STATE_1' : 'INPUT_STATE_0';

    $stmt = sqlsrv_query($con,
        "SELECT TOP 1 id FROM tbl_fogshield_logs
         WHERE panel_id = ?
           AND status IN ('SENT', 'PENDING')
           AND (event_code $siaOperator ? OR event_code = ?)
           AND ABS(DATEDIFF(second, c_on, ?)) <= ?",
        [$panel_id, $siaCode, $mqttCode, $now, $windowSeconds]
    );
    return $stmt ? (sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) !== null) : false;
}

// 15-minute panel watchdog. Piggybacks on normal traffic hitting
// mqtt_4gcom_alert.php, self-throttled so the sweep runs at most
// once every $intervalMinutes.
function fogshield_runPanelWatchdogSweep($con, $windowMinutes = 15, $intervalMinutes = 5, $excludePanelId = null) {
    $sentinel = __DIR__ . '/logs/.last_watchdog_sweep';
    if (is_file($sentinel) && (time() - filemtime($sentinel)) < $intervalMinutes * 60) {
        return;
    }
    touch($sentinel);

    // Compare against a PHP-computed "now" rather than SQL Server's GETDATE()
    // — if the app server and DB server clocks/timezones ever drift (PHP is
    // forced to Asia/Kolkata in db.php; the DB server's own timezone isn't
    // guaranteed to match), a GETDATE()-based comparison can end up
    // permanently true or permanently false, silently disabling the
    // stale-panel sweep for every panel forever. Same reasoning as
    // fogshield_recentZoneAlertExists() below, which already avoids GETDATE().
    $now = date('Y-m-d H:i:s');

    // $excludePanelId is the panel that's actively hitting mqtt_4gcom_alert.php
    // right now, if any — it's proving liveness by definition (this very
    // request is about to update its own state a few lines below), so it
    // must never be flagged OFFLINE from the state row that's about to be
    // superseded. Without this, a panel that just reconnected after a quiet
    // spell gets a contradictory "Panel Offline" alert fired by its own
    // check-in, one request before that same check-in marks it fresh again.
    $staleSql = "SELECT p.pnl_id, p.usr_id, p.pnl_acc_no, p.site_name
         FROM tbl_panel_fogshield p
         JOIN tbl_fogshield_4gcom_panel_state s ON s.panel_id = p.pnl_acc_no
         WHERE DATEDIFF(minute, s.updated_at, ?) >= ?
           AND (p.status IS NULL OR p.status <> 'OFFLINE')
           AND ISNULL(LOWER(LTRIM(RTRIM(p.status))), '') NOT IN ('inactive', 'deleted')";
    // ^ FogShield: never touch deleted panels (FireNex's query would mark a
    //   deleted panel OFFLINE, which counts as live, and bring it back).
    $staleParams = [$now, $windowMinutes];
    if ($excludePanelId !== null) {
        $staleSql .= " AND p.pnl_acc_no <> ?";
        $staleParams[] = $excludePanelId;
    }
    $staleStmt = sqlsrv_query($con, $staleSql, $staleParams);
    $staleCount = 0;
    if ($staleStmt) {
        while ($panel = sqlsrv_fetch_array($staleStmt, SQLSRV_FETCH_ASSOC)) {
            $staleCount++;
            fogshield_notifyPanelOffline($con, $panel, $windowMinutes);
        }
        fogshield_log_write('watchdog', "[" . date('H:i:s') . "] Sweep ran: $staleCount stale panel(s) found" . PHP_EOL);
    } else {
        fogshield_log_write('watchdog', "[" . date('H:i:s') . "] ERROR: stale-panel query failed - " . print_r(sqlsrv_errors(), true) . PHP_EOL);
    }

    sqlsrv_query($con,
        "UPDATE p
         SET p.status = 'ONLINE'
         FROM tbl_panel_fogshield p
         JOIN tbl_fogshield_4gcom_panel_state s ON s.panel_id = p.pnl_acc_no
         WHERE DATEDIFF(minute, s.updated_at, ?) < ?
           AND p.status = 'OFFLINE'",
        [$now, $windowMinutes]
    );
}

function fogshield_notifyPanelOffline($con, $panel, $windowMinutes) {
    $panel_id  = $panel['pnl_acc_no'];
    $usr_id    = (int)$panel['usr_id'];
    $site_name = $panel['site_name'] ?: 'Site';

    sqlsrv_query($con, "UPDATE tbl_panel_fogshield SET status = 'OFFLINE' WHERE pnl_id = ?", [$panel['pnl_id']]);

    $tokStmt = sqlsrv_query($con, "SELECT device_token FROM tbl_fogshield_device_tokens WHERE user_id = ?", [$usr_id]);
    $tokens = [];
    if ($tokStmt) {
        while ($r = sqlsrv_fetch_array($tokStmt, SQLSRV_FETCH_ASSOC)) {
            if (!empty($r['device_token'])) $tokens[] = $r['device_token'];
        }
    }
    $tokens = array_unique($tokens);

    $title       = "Alert - " . $site_name;
    $displayTime = date('h:i A d/m/Y');
    $event_name  = "Panel Offline";
    $body        = "No update received from panel for {$windowMinutes} minutes\n$displayTime";
    $c_on        = date('Y-m-d H:i:s');

    $logStmt = sqlsrv_query($con,
        "INSERT INTO tbl_fogshield_logs
         (usr_id, panel_id, site_name, event_code, event_name, device_token, notification_title, notification_body, status, c_on)
         OUTPUT INSERTED.id
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [$usr_id, $panel_id, $site_name, 'PANEL_OFFLINE', $event_name, fogshield_truncateTokenList($tokens), $title, $body, empty($tokens) ? 'NO_TOKENS' : 'PENDING', $c_on]
    );
    $log_id = null;
    if ($logStmt && $logRow = sqlsrv_fetch_array($logStmt, SQLSRV_FETCH_ASSOC)) {
        $log_id = $logRow['id'];
    }

    if (empty($tokens)) {
        fogshield_log_write('watchdog', "[" . date('H:i:s') . "] No tokens for usr_id=$usr_id, panel_id=$panel_id - logged only" . PHP_EOL);
        return;
    }

    $customData = ['panel_id' => $panel_id, 'site_name' => $site_name, 'event' => 'PANEL_OFFLINE', 'dt' => $displayTime, 'app' => 'fogshield', 'log_id' => $log_id !== null ? (string)$log_id : ''];
    $result = sendFCMNotification($tokens, $title, $body, $customData, 'fogshield');

    foreach ($result['invalid_tokens'] as $badToken) {
        sqlsrv_query($con, "DELETE FROM tbl_fogshield_device_tokens WHERE device_token = ?", [$badToken]);
    }

    if ($log_id) {
        $final = $result['sent'] > 0 ? 'SENT' : 'FAILED';
        sqlsrv_query($con, "UPDATE tbl_fogshield_logs SET status=?, fcm_response=? WHERE id=?",
            [$final, "sent={$result['sent']} failed={$result['failed']}", $log_id]);
    }
    fogshield_log_write('watchdog', "[" . date('H:i:s') . "] OFFLINE alert sent for panel_id=$panel_id: sent={$result['sent']} failed={$result['failed']}" . PHP_EOL);
}

// Save a phone's FCM token for a user (multi-device), as firenex/login.php
// does. tbl_fogshield_device_tokens.c_on is NOT NULL on the server, so it is
// set here. Returns false on a DB error.
function fogshield_store_device_token($con, $user_id, $token) {
    $stmt = sqlsrv_query($con,
        "MERGE INTO tbl_fogshield_device_tokens AS t
         USING (VALUES (?, ?)) AS s(user_id, device_token)
         ON t.user_id = s.user_id AND t.device_token = s.device_token
         WHEN NOT MATCHED THEN
             INSERT (user_id, device_token, c_on) VALUES (s.user_id, s.device_token, GETDATE());",
        [(int)$user_id, $token]);
    return $stmt !== false;
}
