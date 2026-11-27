<?php
// fogshield/logout.php — from firenex/logout.php: remove only THIS phone's
// token, so other logged-in phones keep getting alerts.
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Invalid request method"]);
    exit;
}

$user_id      = trim($_POST['user_id']      ?? '');
$device_token = trim($_POST['device_token'] ?? '');
if (empty($user_id) || empty($device_token)) {
    echo json_encode(["status" => false, "msg" => "user_id and device_token are required"]);
    exit;
}
if (!ctype_digit($user_id)) {
    echo json_encode(["status" => false, "msg" => "Invalid user_id"]);
    exit;
}

fogshield_log('logout', "Logout attempt", ['user_id' => $user_id]);
$stmt = sqlsrv_query($con, "DELETE FROM tbl_fogshield_device_tokens WHERE user_id = ? AND device_token = ?",
    [(int)$user_id, $device_token]);

if ($stmt) {
    $rows = sqlsrv_rows_affected($stmt);
    fogshield_log('logout', $rows > 0 ? "Logout successful — device token removed" : "Logout — token not found (already removed)", ['user_id' => $user_id]);
    echo json_encode(["status" => true, "msg" => $rows > 0 ? "Logged out successfully" : "Logged out (token already removed)"]);
} else {
    fogshield_log('logout', "Logout failed — DB error", ['user_id' => $user_id, 'error' => sqlsrv_errors()]);
    echo json_encode(["status" => false, "msg" => "Logout failed"]);
}
sqlsrv_close($con);
