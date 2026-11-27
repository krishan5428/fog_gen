<?php
// fogshield/del_user.php — "delete account". firenex/ has no del_user.php, so
// this follows the root del_user.php the app used: status = 'STOP' for the
// matching mobile + password (row kept; login only accepts ACTIVE).
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Invalid request method. Please use POST."]);
    exit;
}

$mobile = trim($_POST['mobile'] ?? '');
$pass   = trim($_POST['pass'] ?? '');
if ($mobile === '' || $pass === '') {
    echo json_encode(["status" => false, "msg" => "Mobile and Password are required"]);
    exit;
}

$stmt = sqlsrv_query($con, "UPDATE tbl_fogshield_users SET status = 'STOP' WHERE mobile = ? AND password = ?", [$mobile, $pass]);
if (!$stmt) {
    fogshield_log('user_delete', "ERROR: delete failed", ['mobile' => $mobile, 'error' => sqlsrv_errors()]);
    echo json_encode(["status" => false, "msg" => "Execution error"]);
} elseif (sqlsrv_rows_affected($stmt) > 0) {
    fogshield_log('user_delete', "Account stopped", ['mobile' => $mobile]);
    echo json_encode(["status" => true, "msg" => "ok"]);
} else {
    echo json_encode(["status" => false, "msg" => "Invalid Mobile or Password"]);
}
sqlsrv_close($con);
