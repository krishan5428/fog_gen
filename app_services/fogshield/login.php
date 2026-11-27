<?php
// fogshield/login.php — from firenex/login.php, on tbl_fogshield_users.
// Stores this phone's FCM token (dev_id) in tbl_fogshield_device_tokens
// (multi-device) and returns a JWT. Not copied: role (no such column).
// Response: { status, msg, data: {usr_id, name, email, mobile, status, …}, token, vendor_added }
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Invalid request method"]);
    exit;
}

$mobile = trim($_POST['mobile'] ?? '');
$pass   = trim($_POST['pass']   ?? '');
$dev_id = trim($_POST['dev_id'] ?? '');

if (empty($mobile) || empty($pass)) {
    echo json_encode(["status" => false, "msg" => "Mobile and password are required"]);
    exit;
}

fogshield_log('login', "Login attempt", ['mobile' => $mobile]);

$stmt = sqlsrv_query($con,
    "SELECT usr_id, name, email, mobile, status, dev_info, enrolled_on, c_on, vendor_name
     FROM tbl_fogshield_users
     WHERE mobile = ? AND password = ? AND status = 'ACTIVE'",
    [$mobile, $pass]);

if ($stmt && sqlsrv_has_rows($stmt)) {
    $row     = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC);
    $user_id = $row['usr_id'];
    foreach ($row as $k => $v) {
        if ($v instanceof DateTime) $row[$k] = $v->format('Y-m-d H:i:s');
        elseif ($v === null) $row[$k] = '';
    }

    if (!empty($dev_id)) {
        $tok = fogshield_store_device_token($con, $user_id, $dev_id);
        fogshield_log('login', $tok ? "Device token stored" : "WARNING: Failed to store device token",
            $tok ? ['user_id' => $user_id] : ['error' => sqlsrv_errors()]);
    }

    $jwtGenerator = new JwtGenerator();
    $token = $jwtGenerator->generateToken($row);

    fogshield_log('login', "Login successful", ['usr_id' => $user_id]);
    echo json_encode([
        "status"       => true,
        "msg"          => "Login successful",
        "data"         => $row,
        "token"        => $token,
        "vendor_added" => !empty($row['vendor_name']),
    ]);
} else {
    $chkStmt = sqlsrv_query($con, "SELECT COUNT(*) AS cnt FROM tbl_fogshield_users WHERE mobile = ?", [$mobile]);
    $chkRow  = $chkStmt ? sqlsrv_fetch_array($chkStmt, SQLSRV_FETCH_ASSOC) : null;
    if ($chkRow && (int)$chkRow['cnt'] === 0) {
        fogshield_log('login', "Login failed - user not registered", ['mobile' => $mobile]);
        echo json_encode(["status" => false, "msg" => "User not registered"]);
    } else {
        fogshield_log('login', "Login failed - invalid password or inactive", ['mobile' => $mobile]);
        echo json_encode(["status" => false, "msg" => "Invalid mobile or password"]);
    }
}

sqlsrv_close($con);
