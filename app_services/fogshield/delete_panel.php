<?php
// fogshield/delete_panel.php — soft-delete the user's own panel.
// Like firenex/delete_panel.php for the owner: status = 'DELETED' (the row
// stays so the same hardware gets its old number back if re-added), then the
// routing row, zone names, custom event names, logs and G4 state baseline
// are removed so a future
// panel given the same number starts clean.
// Not copied from FireNex: the "panel not found → delete all of this user's
// share rows" branch (no sharing in phase 1, and it removed unrelated shares).
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

fogshield_log('panel_delete', "Delete attempt", ['pnl_id' => $pnl_id, 'usr_id' => $usr_id]);

$live = fogshield_live_status_sql();
$stmt = sqlsrv_query($con,
    "SELECT pnl_acc_no FROM tbl_panel_fogshield
     WHERE pnl_id = ? AND CAST(usr_id AS VARCHAR) = CAST(? AS VARCHAR) AND $live",
    [(int)$pnl_id, $usr_id]);
$row = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;
if (!$row) {
    fogshield_log('panel_delete', "Panel not found", ['pnl_id' => $pnl_id, 'usr_id' => $usr_id]);
    echo json_encode(["status" => false, "msg" => "Panel not found"]);
    sqlsrv_close($con);
    exit;
}
$pnl_acc_no = $row['pnl_acc_no'];

$del = sqlsrv_query($con,
    "UPDATE tbl_panel_fogshield SET status = 'DELETED'
     WHERE pnl_id = ? AND CAST(usr_id AS VARCHAR) = CAST(? AS VARCHAR)",
    [(int)$pnl_id, $usr_id]);
if (!$del || sqlsrv_rows_affected($del) < 1) {
    fogshield_log('panel_delete', "ERROR: delete failed", ['pnl_id' => $pnl_id, 'error' => sqlsrv_errors()]);
    echo json_encode(["status" => false, "msg" => "Delete failed"]);
    sqlsrv_close($con);
    exit;
}

if (!empty($pnl_acc_no)) {
    sqlsrv_query($con, "DELETE FROM tbl_pnl_map WHERE panel_id = ? AND app_name = 'fogshield'", [$pnl_acc_no]);
    sqlsrv_query($con, "DELETE FROM tbl_fogshield_zone_map WHERE panel_id = ?", [$pnl_acc_no]);
    sqlsrv_query($con, "DELETE FROM tbl_fogshield_event_map WHERE panel_id = ?", [$pnl_acc_no]);
    sqlsrv_query($con, "DELETE FROM tbl_fogshield_logs WHERE panel_id = ?", [$pnl_acc_no]);
    sqlsrv_query($con, "DELETE FROM tbl_fogshield_4gcom_panel_state WHERE panel_id = ?", [$pnl_acc_no]);
}

fogshield_log('panel_delete', "Panel deleted", ['pnl_id' => $pnl_id, 'usr_id' => $usr_id, 'pnl_acc_no' => $pnl_acc_no]);
echo json_encode(["status" => true, "msg" => "Panel deleted successfully"]);
sqlsrv_close($con);
