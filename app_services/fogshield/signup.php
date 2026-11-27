<?php
// fogshield/signup.php — from firenex/signup.php, on tbl_fogshield_users.
// Same behaviour: an existing mobile is re-activated and updated; password
// stored as given (as FireNex). Not copied: role / created_by_usr_id
// (FogShield has no factory-worker roles; the table has no such columns).
// App sends: name, mobile, email, password, dev_info (device_id is ignored).
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Invalid request method"]);
    exit;
}

$name     = trim($_POST['name']     ?? '');
$mobile   = trim($_POST['mobile']   ?? '');
$email    = trim($_POST['email']    ?? '');
$password = trim($_POST['password'] ?? '');
$dev_info = $_POST['dev_info'] ?? '';

if (empty($mobile) || empty($password)) {
    echo json_encode(["status" => false, "msg" => "Mobile and password are required"]);
    exit;
}

fogshield_log('signup', "Signup request", ['mobile' => $mobile, 'email' => $email]);

$checkStmt = sqlsrv_query($con, "SELECT usr_id FROM tbl_fogshield_users WHERE mobile = ?", [$mobile]);
$now = date('Y-m-d H:i:s');

if ($checkStmt && sqlsrv_has_rows($checkStmt)) {
    $stmt = sqlsrv_query($con,
        "UPDATE tbl_fogshield_users
         SET name = ?, email = ?, password = CAST(? AS VARCHAR(255)),
             dev_info = ?, status = 'ACTIVE', c_on = ?
         WHERE mobile = ?",
        [$name, $email, $password, $dev_info, $now, $mobile]);
    $msg = "User updated successfully";
} else {
    $stmt = sqlsrv_query($con,
        "INSERT INTO tbl_fogshield_users (name, mobile, email, password, dev_info, status, enrolled_on, c_on)
         VALUES (?, ?, ?, CAST(? AS VARCHAR(255)), ?, 'ACTIVE', ?, ?)",
        [$name, $mobile, $email, $password, $dev_info, $now, $now]);
    $msg = "User registered successfully";
}

if ($stmt) {
    fogshield_log('signup', $msg, ['mobile' => $mobile]);
    $vStmt = sqlsrv_query($con, "SELECT vendor_name FROM tbl_fogshield_users WHERE mobile = ?", [$mobile]);
    $vendor_added = false;
    if ($vStmt && ($vRow = sqlsrv_fetch_array($vStmt, SQLSRV_FETCH_ASSOC))) {
        $vendor_added = !empty($vRow['vendor_name']);
    }
    echo json_encode(["status" => true, "msg" => $msg, "vendor_added" => $vendor_added]);
} else {
    fogshield_log('signup', "ERROR: Signup failed", ['error' => sqlsrv_errors()]);
    echo json_encode(["status" => false, "msg" => "Registration failed"]);
}

sqlsrv_close($con);
