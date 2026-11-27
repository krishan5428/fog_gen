<?php
// fogshield/get_panels.php — the user's live FogShield panels.
// Response: { status, msg, panels: [ {pnl_id, …, panel_imei, share_status, shared_by} ] }
// (the shape the FogShield app's PanelResponse reads; FireNex returns "data").
// No panel sharing in phase 1: every row is the user's own.
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Only POST allowed"]);
    exit;
}

$usr_id = trim($_POST['usr_id'] ?? '');
if ($usr_id === '') {
    echo json_encode(["status" => false, "msg" => "usr_id is required"]);
    exit;
}

$live = fogshield_live_status_sql();
$stmt = sqlsrv_query($con,
    "SELECT * FROM tbl_panel_fogshield
     WHERE CAST(usr_id AS VARCHAR) = CAST(? AS VARCHAR) AND $live
     ORDER BY pnl_id ASC",
    [$usr_id]);

if ($stmt === false) {
    fogshield_log('panel_get', "ERROR: query failed", ['usr_id' => $usr_id, 'error' => sqlsrv_errors()]);
    echo json_encode(["status" => false, "msg" => "Query failed"]);
    sqlsrv_close($con);
    exit;
}

$panels = [];
while ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
    foreach ($row as $key => $value) {
        if ($value instanceof DateTime) {
            $row[$key] = $value->format('Y-m-d H:i:s');
        } elseif ($value === null) {
            $row[$key] = "";
        }
    }
    $row['share_status'] = 'owner';
    $row['shared_by'] = '';
    $panels[] = $row;
}

echo json_encode([
    "status" => true,
    "msg"    => count($panels) > 0 ? "Panels retrieved" : "No panels found",
    "panels" => $panels,
]);
sqlsrv_close($con);
