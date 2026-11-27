<?php
// fogshield/update_user.php — firenex/update_user.php (store this phone's FCM
// token) PLUS profile fields, so the FogShield profile screens keep working
// (FireNex's version only stores the token, so its profile edits don't save).
//
// POST usr_id and any of:
//   dev_id or device_id          → token saved in tbl_fogshield_device_tokens
//   name, email, mobile, password → profile update in tbl_fogshield_users
// Response: { status, message }   (the key the app reads)
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "message" => "Invalid request method"]);
    exit;
}

$usr_id = (int)($_POST['usr_id'] ?? 0);
$dev_id = trim($_POST['dev_id'] ?? ($_POST['device_id'] ?? ''));
if ($usr_id <= 0) {
    echo json_encode(["status" => false, "message" => "usr_id is required"]);
    exit;
}

$profileFields = ['name', 'email', 'mobile', 'password'];
$updates = [];
$params  = [];
foreach ($profileFields as $f) {
    if (!array_key_exists($f, $_POST)) continue;
    $v = trim((string)$_POST[$f]);
    if (in_array($f, ['mobile', 'password'], true) && $v === '') {
        echo json_encode(["status" => false, "message" => "$f cannot be empty"]);
        exit;
    }
    $updates[] = $f === 'password' ? "password = CAST(? AS VARCHAR(255))" : "$f = ?";
    $params[] = $v;
}

if ($dev_id === '' && empty($updates)) {
    echo json_encode(["status" => false, "message" => "Nothing to update"]);
    exit;
}

if ($dev_id !== '' && !fogshield_store_device_token($con, $usr_id, $dev_id)) {
    echo json_encode(["status" => false, "message" => "DB error"]);
    sqlsrv_close($con);
    exit;
}

if (!empty($updates)) {
    if (array_key_exists('mobile', $_POST)) {
        $dup = sqlsrv_query($con, "SELECT usr_id FROM tbl_fogshield_users WHERE mobile = ? AND usr_id <> ?",
            [trim($_POST['mobile']), $usr_id]);
        if ($dup && sqlsrv_has_rows($dup)) {
            echo json_encode(["status" => false, "message" => "Mobile number already registered"]);
            sqlsrv_close($con);
            exit;
        }
    }
    $params[] = $usr_id;
    $stmt = sqlsrv_query($con, "UPDATE tbl_fogshield_users SET " . implode(', ', $updates) . " WHERE usr_id = ?", $params);
    if ($stmt === false) {
        fogshield_log('user_update', "ERROR: update failed", ['usr_id' => $usr_id, 'error' => sqlsrv_errors()]);
        echo json_encode(["status" => false, "message" => "DB error"]);
        sqlsrv_close($con);
        exit;
    }
    if (sqlsrv_rows_affected($stmt) < 1) {
        echo json_encode(["status" => false, "message" => "User not found"]);
        sqlsrv_close($con);
        exit;
    }
    // Field names only — never log the password value.
    fogshield_log('user_update', "Profile updated", ['usr_id' => $usr_id, 'fields' => array_values(array_intersect($profileFields, array_keys($_POST)))]);
}

echo json_encode([
    "status"  => true,
    "message" => !empty($updates) ? "Updated successfully" : "Token registered",
]);
sqlsrv_close($con);
