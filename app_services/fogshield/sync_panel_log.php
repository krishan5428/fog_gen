<?php
/**
 * FOGSHIELD — SR1 (TCP) panel event handler.
 *
 * Called by the root router (app_services/sync_panel_log.php) via require,
 * for a panel_id whose tbl_pnl_map row has app_name = 'fogshield'.
 * In scope from the router: $con, $routeRow ['panel_id','app_name','usr_id'],
 * $decoded_json / $data (packet), $json_pkt (raw), normalizeDateTime().
 * Must set $json and return — never exit (other apps' handlers may run
 * after this one in the same request). All locals use the $fs_ prefix so
 * the router's and other handlers' variables are never overwritten.
 *
 * Structure from firenex/sync_panel_log.php; notification content and AMS
 * forwarding kept exactly as the legacy FogShield path in the root router
 * (every event is pushed, title "Alert!", same body/data the app reads).
 * Difference from legacy: the push goes through the FogShield Firebase
 * project ('fogshield') — the app's tokens belong to that project.
 */

require_once __DIR__ . '/log_helper.php';

if (!function_exists('fsh_sync_log')) {
    function fsh_sync_log($msg) {
        $dir = dirname(__DIR__) . '/logs/process_flow';
        if (!is_dir($dir)) @mkdir($dir, 0777, true);
        @file_put_contents($dir . '/process_flow_' . date('Y-m-d') . '.txt',
            "[" . date('H:i:s') . "] [FOGSHIELD] $msg" . PHP_EOL, FILE_APPEND);
    }
}

// ── Packet: php://input first (the router's $data can be reused), then router vars ──
$fs_raw = file_get_contents('php://input');
if (empty($fs_raw)) $fs_raw = $json_pkt ?? '';
$fs_pkt = json_decode(str_replace("'", '"', $fs_raw), true);
if (empty($fs_pkt) && !empty($decoded_json) && is_array($decoded_json)) $fs_pkt = $decoded_json;
if (empty($fs_pkt) && !empty($data) && is_array($data)) $fs_pkt = $data;

if (empty($fs_pkt)) {
    fsh_sync_log("ERROR: could not parse packet — aborting");
    $json = ["status" => false, "msg" => "FogShield: bad packet"];
    return;
}

$fs_panel_id = $routeRow['panel_id'];
$fs_usr_id   = (int)$routeRow['usr_id'];
$fs_code     = strtoupper(trim($fs_pkt['eventCode'] ?? ''));
$fs_c_on     = date('Y-m-d H:i:s');
fsh_sync_log("Handler started — panel_id=$fs_panel_id usr_id=$fs_usr_id code=$fs_code");

// ── 0. Duplicates ──
// Same transaction id already in the global log → don't insert it again
// (another app may have logged it in this request).
$fs_trx = $fs_pkt['zoneeventtransationid'] ?? '';
$fs_global_logged = false;
if ($fs_trx !== '') {
    $fs_st = sqlsrv_query($con, "SELECT TOP 1 panel_id FROM tbl_gbl_logs WHERE zone_event_trx_id = ?", [$fs_trx]);
    $fs_global_logged = $fs_st && sqlsrv_fetch_array($fs_st, SQLSRV_FETCH_ASSOC);
}
// Same code for this user+panel within 20 s → already pushed.
$fs_st = sqlsrv_query($con,
    "SELECT TOP 1 id FROM tbl_fogshield_logs
     WHERE usr_id = ? AND panel_id = ? AND event_code = ? AND ABS(DATEDIFF(second, c_on, ?)) <= 20",
    [$fs_usr_id, $fs_panel_id, $fs_code, $fs_c_on]);
if ($fs_st && sqlsrv_fetch_array($fs_st, SQLSRV_FETCH_ASSOC)) {
    fsh_sync_log("Duplicate skipped: $fs_code within 20s");
    $json = ["status" => true, "msg" => "Duplicate skipped", "notifications_sent" => 0];
    return;
}

// ── 1. Event name (legacy rule: last segment after '/') ──
$fs_parts = explode('/', $fs_pkt['eventName'] ?? '');
$fs_event_name = trim(end($fs_parts));
if ($fs_event_name === '') $fs_event_name = 'Unknown Panel Event';

// ── 2. Site name ──
$fs_site = 'Site';
$fs_st = sqlsrv_query($con, "SELECT site_name FROM tbl_panel_fogshield WHERE pnl_acc_no = ? AND "
    . fogshield_live_status_sql(), [$fs_panel_id]);
if ($fs_st && ($fs_row = sqlsrv_fetch_array($fs_st, SQLSRV_FETCH_ASSOC)) && !empty($fs_row['site_name'])) {
    $fs_site = $fs_row['site_name'];
}

// ── 3. Time ──
$fs_raw_pkt = json_encode($fs_pkt);
$fs_event_time = $fs_pkt['eventOccuranceTime'] ?? '';
if (function_exists('normalizeDateTime')) $fs_event_time = normalizeDateTime($fs_event_time);
try {
    $fs_formatted = (new DateTime($fs_event_time ?: 'now'))->format('d-m-Y H:i:s');
} catch (Exception $e) {
    $fs_formatted = date('d-m-Y H:i:s');
}

// ── 4. Global logs (shared tables) ──
if (!$fs_global_logged) {
    sqlsrv_query($con, "INSERT INTO tbl_jsn_sync (op_tp, op_info, json_pkt, c_on) VALUES (?, ?, ?, ?)",
        ['IN', 'FOGSHIELD', $fs_raw_pkt, $fs_c_on]);
    sqlsrv_query($con,
        "INSERT INTO tbl_gbl_logs
         (panel_id, org_name, zone_name, event_code, event_name, panel_name, card_number,
          status_name, panel_number, priority_name, severity_name, event_time, zone_event_trx_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [
            $fs_pkt['PanelId'] ?? '', $fs_pkt['orgName'] ?? '', $fs_pkt['zoneName'] ?? '',
            $fs_pkt['eventCode'] ?? '', $fs_pkt['eventName'] ?? '', $fs_pkt['panelName'] ?? '',
            $fs_pkt['cardNumber'] ?? '', $fs_pkt['statusName'] ?? '', $fs_pkt['panelNumber'] ?? '',
            $fs_pkt['priorityName'] ?? '', $fs_pkt['severityName'] ?? '', $fs_event_time, $fs_trx,
        ]);
}

// ── 5. Push (every event, as the legacy FogShield path does) ──
$fs_title = 'Alert!';
$fs_body  = $fs_site . "\n" . $fs_event_name . "\n" . ($fs_pkt['statusName'] ?? '') . ' On ' . $fs_formatted;
$fs_data  = [
    'site_name'     => $fs_site,
    'event_name'    => $fs_event_name,
    'priority_name' => $fs_pkt['priorityName'] ?? '',
    'severity_name' => $fs_pkt['severityName'] ?? '',
    'event_time'    => $fs_formatted,
    'panel_id'      => (string)$fs_panel_id,
    'event_code'    => $fs_code,
    'app'           => 'fogshield',
];

// Every live owner of this account number gets the push, as the legacy path
// does (two users may have added the same panel).
$fs_tokens = [];
$fs_st = sqlsrv_query($con,
    "SELECT DISTINCT t.device_token
     FROM tbl_panel_fogshield p
     INNER JOIN tbl_fogshield_device_tokens t ON CAST(t.user_id AS VARCHAR) = CAST(p.usr_id AS VARCHAR)
     WHERE p.pnl_acc_no = ? AND " . fogshield_live_status_sql('p'),
    [$fs_panel_id]);
while ($fs_st && ($fs_row = sqlsrv_fetch_array($fs_st, SQLSRV_FETCH_ASSOC))) {
    if (!empty($fs_row['device_token'])) $fs_tokens[] = $fs_row['device_token'];
}
$fs_tokens = array_values(array_unique($fs_tokens));

$fs_status = empty($fs_tokens) ? 'NO_TOKENS' : 'PENDING';
$fs_log_id = null;
$fs_st = sqlsrv_query($con,
    "INSERT INTO tbl_fogshield_logs
     (usr_id, panel_id, site_name, event_code, event_name, device_token, notification_title, notification_body, status, c_on)
     OUTPUT INSERTED.id
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    [$fs_usr_id, $fs_panel_id, $fs_site, $fs_code, $fs_event_name,
     fogshield_truncateTokenList($fs_tokens), $fs_title, $fs_body, $fs_status, $fs_c_on]);
if ($fs_st && ($fs_row = sqlsrv_fetch_array($fs_st, SQLSRV_FETCH_ASSOC))) {
    $fs_log_id = $fs_row['id'];
} else {
    fsh_sync_log("ERROR: tbl_fogshield_logs insert failed");
}

$fs_sent = 0;
if (!empty($fs_tokens) && function_exists('sendFCMNotification')) {
    $fs_data['log_id'] = $fs_log_id !== null ? (string)$fs_log_id : '';
    $fs_result = sendFCMNotification($fs_tokens, $fs_title, $fs_body, $fs_data, 'fogshield');
    $fs_sent = (int)($fs_result['sent'] ?? 0);
    foreach ($fs_result['invalid_tokens'] ?? [] as $fs_bad) {
        sqlsrv_query($con, "DELETE FROM tbl_fogshield_device_tokens WHERE device_token = ?", [$fs_bad]);
    }
    if ($fs_log_id !== null) {
        sqlsrv_query($con, "UPDATE tbl_fogshield_logs SET status = ?, fcm_response = ? WHERE id = ?",
            [$fs_sent > 0 ? 'SENT' : 'FAILED',
             "sent=" . ($fs_result['sent'] ?? 0) . " failed=" . ($fs_result['failed'] ?? 0), $fs_log_id]);
    }
} elseif (!empty($fs_tokens)) {
    fsh_sync_log("ERROR: sendFCMNotification not loaded (common/fcm.php)");
}

fogshield_log('panel_log', "Event", [
    'log_id' => $fs_log_id, 'panel_id' => $fs_panel_id, 'event_code' => $fs_code,
    'event_name' => $fs_event_name, 'status' => $fs_status, 'sent' => $fs_sent,
]);

// ── 6. Forward to AMS, as the legacy FogShield path does ──
// Kept so moving FogShield panels to this handler doesn't silently stop
// the Alarm Monitoring System feed. Same URL/credentials as the root router.
// URL and auth come from fogshield/config.php (they change per server);
// FOGSHIELD_AMS_URL / FOGSHIELD_AMS_AUTH override them ("" URL = off, tests).
require_once(__DIR__ . '/config_loader.php');
$fs_ams_url  = getenv('FOGSHIELD_AMS_URL');
$fs_ams_auth = getenv('FOGSHIELD_AMS_AUTH');
if ($fs_ams_url === false)  $fs_ams_url  = fogshield_config('ams_url');
if ($fs_ams_auth === false) $fs_ams_auth = fogshield_config('ams_auth');
if ($fs_ams_url !== '' && function_exists('curl_init')) {
    $fs_headers = ['Content-Type: application/json'];
    if ($fs_ams_auth !== '') $fs_headers[] = 'Authorization: ' . $fs_ams_auth;
    $fs_ch = curl_init($fs_ams_url);
    curl_setopt($fs_ch, CURLOPT_POST, true);
    curl_setopt($fs_ch, CURLOPT_HTTPHEADER, $fs_headers);
    curl_setopt($fs_ch, CURLOPT_POSTFIELDS, $fs_raw);
    curl_setopt($fs_ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($fs_ch, CURLOPT_TIMEOUT, 10);
    curl_exec($fs_ch);
    $fs_ams = curl_getinfo($fs_ch, CURLINFO_HTTP_CODE);
    curl_close($fs_ch);
    fsh_sync_log("AMS HTTP $fs_ams");
}

fsh_sync_log("Done — $fs_sent notification(s) for panel_id=$fs_panel_id");
$json = ["status" => true, "msg" => "FogShield: processed", "notifications_sent" => $fs_sent];
