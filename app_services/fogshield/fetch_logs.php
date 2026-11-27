<?php
// fogshield/fetch_logs.php — last 20 events of one of the user's panels.
// Replaces the root fetch_logs.php for FogShield, which (a) joins
// tbl_panel_master, so panels in tbl_panel_fogshield returned nothing,
// (b) required ip/port/mac/version/receiver/line to be non-empty, so G4
// panels (no IP, no MAC) always got "Validation failed", and (c) returned
// any panel's logs to any user who knew the account number.
//
// Source of the events:
//   SR1 panels  → tbl_gbl_logs (shared global log, holds the full history)
//   4GCOM (G4)  → tbl_fogshield_logs (written by fogshield/mqtt_4gcom_alert.php)
// Response (unchanged for the app): { status, msg, logs: [{event_name, event_time "d-m-Y H:i:s", …}] }
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Invalid request method"]);
    exit;
}

$usr_id     = trim($_POST['usr_id'] ?? '');
$pnl_acc_no = trim($_POST['pnl_acc_no'] ?? '');
if ($usr_id === '' || $pnl_acc_no === '') {
    echo json_encode(["status" => false, "msg" => "usr_id and pnl_acc_no are required"]);
    exit;
}

// The panel must be one of this user's live panels.
$stmt = sqlsrv_query($con,
    "SELECT TOP 1 pnl_type FROM tbl_panel_fogshield
     WHERE pnl_acc_no = ? AND CAST(usr_id AS VARCHAR) = CAST(? AS VARCHAR) AND " . fogshield_live_status_sql(),
    [$pnl_acc_no, $usr_id]);
$panel = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;
if (!$panel) {
    echo json_encode(["status" => false, "msg" => "Panel not found"]);
    sqlsrv_close($con);
    exit;
}

function fs_fmt_time($value) {
    if ($value instanceof DateTime) return $value->format('d-m-Y H:i:s');
    if ($value === null || $value === '') return '';
    $ts = strtotime((string)$value);
    return $ts === false ? (string)$value : date('d-m-Y H:i:s', $ts);
}

$isG4 = ($panel['pnl_type'] ?? '') === '4GCOM';
if ($isG4) {
    $stmt = sqlsrv_query($con,
        "SELECT TOP 20 id, panel_id, site_name, event_code, event_name, status, c_on
         FROM tbl_fogshield_logs
         WHERE panel_id = ? AND event_name IS NOT NULL AND event_name <> ''
         ORDER BY c_on DESC, id DESC",
        [$pnl_acc_no]);
} else {
    $stmt = sqlsrv_query($con,
        "SELECT TOP 20 * FROM tbl_gbl_logs WHERE panel_id = ? ORDER BY gbl_lg_id DESC",
        [$pnl_acc_no]);
}

if ($stmt === false) {
    fogshield_log('logs', "ERROR: query failed", ['pnl_acc_no' => $pnl_acc_no, 'error' => sqlsrv_errors()]);
    echo json_encode(["status" => false, "msg" => "Query failed"]);
    sqlsrv_close($con);
    exit;
}

$logs = [];
while ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
    if ($isG4) {
        $row['event_time'] = fs_fmt_time($row['c_on'] ?? null);
        $row['c_on'] = $row['event_time'];
    } else {
        // Legacy rule: show only the last segment of "Panel/Zone/Event".
        $parts = explode('/', (string)($row['event_name'] ?? ''));
        $last = trim(end($parts));
        $row['event_name'] = $last !== '' ? $last : 'Unknown Panel Event';
        $row['event_time'] = fs_fmt_time($row['event_time'] ?? null);
    }
    foreach ($row as $k => $v) {
        if ($v instanceof DateTime) $row[$k] = $v->format('Y-m-d H:i:s');
        elseif ($v === null) $row[$k] = '';
    }
    $logs[] = $row;
}

echo json_encode(["status" => true, "msg" => "Logs retrieved successfully", "logs" => $logs]);
sqlsrv_close($con);
