<?php
// fogshield/update_panel.php — update fields of the user's own panel.
// Same fields as firenex/update_panel.php. pnl_type, panel_imei and
// pnl_acc_no are NOT updatable: they drive alert routing (tbl_pnl_map).
// Response (success): { status: true, msg, data: {row}, panelData: {row} }
//   data = FireNex name; panelData = what the FogShield app's repo checks.
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Only POST allowed"]);
    exit;
}

$pnl_id = $_POST['pnl_id'] ?? null;
$usr_id = $_POST['usr_id'] ?? null;
if (!$pnl_id || !$usr_id) {
    echo json_encode(["status" => false, "msg" => "pnl_id and usr_id are required"]);
    exit;
}

$updatableFields = [
    'panel_name', 'site_name', 'site_address',
    'pnl_mac', 'pnl_ver', 'pnl_line_no', 'pnl_rcvr_no',
    'ip_add', 'port_no', 'static_ip', 'static_port', 'pass',
    'admin_code', 'usr_1', 'usr_2', 'usr_3', 'usr_4',
    'panel_sim_number', 'admin_mobile_number', 'mobile_number_sub_id',
    'mobile_number1', 'mobile_number2', 'mobile_number3', 'mobile_number4',
    'mobile_number5', 'mobile_number6', 'mobile_number7', 'mobile_number8',
    'mobile_number9', 'mobile_number10', 'is_ip_panel', 'is_ip_gsm_panel',
];

$updates = [];
$params  = [];
$changed = [];
foreach ($updatableFields as $field) {
    if (!array_key_exists($field, $_POST)) continue;
    $updates[] = "$field = ?";
    $changed[] = $field;
    $params[] = in_array($field, ['is_ip_panel', 'is_ip_gsm_panel'], true)
        ? (filter_var($_POST[$field], FILTER_VALIDATE_BOOLEAN) ? 1 : 0)
        : $_POST[$field];
}

if (empty($updates)) {
    echo json_encode(["status" => false, "msg" => "No updatable fields provided"]);
    exit;
}

// Field names only — never log values (pass, admin_code).
fogshield_log('panel_update', "Update attempt", ['pnl_id' => $pnl_id, 'usr_id' => $usr_id, 'fields' => $changed]);

$live = fogshield_live_status_sql();
$params[] = (int)$pnl_id;
$params[] = $usr_id;
$stmt = sqlsrv_query($con,
    "UPDATE tbl_panel_fogshield SET " . implode(', ', $updates) . "
     WHERE pnl_id = ? AND CAST(usr_id AS VARCHAR) = CAST(? AS VARCHAR) AND $live",
    $params);

if ($stmt === false) {
    fogshield_log('panel_update', "ERROR: update failed", ['pnl_id' => $pnl_id, 'error' => sqlsrv_errors()]);
    echo json_encode(["status" => false, "msg" => "Update failed"]);
    sqlsrv_close($con);
    exit;
}
if (sqlsrv_rows_affected($stmt) < 1) {
    echo json_encode(["status" => false, "msg" => "No matching panel found"]);
    sqlsrv_close($con);
    exit;
}

$sel = sqlsrv_query($con, "SELECT * FROM tbl_panel_fogshield WHERE pnl_id = ?", [(int)$pnl_id]);
$row = $sel ? sqlsrv_fetch_array($sel, SQLSRV_FETCH_ASSOC) : null;
if ($row) {
    foreach ($row as $key => $value) {
        if ($value instanceof DateTime) $row[$key] = $value->format('Y-m-d H:i:s');
        elseif ($value === null) $row[$key] = "";
    }
}

echo json_encode([
    "status"    => true,
    "msg"       => "Panel updated successfully",
    "data"      => $row,
    "panelData" => $row,
]);
sqlsrv_close($con);
