<?php
// fogshield/add_vendor.php — from firenex/add_vendor.php (vendor details live in the user's row of
// tbl_fogshield_users). Table and log helper renamed only.
header('Content-Type: application/json');
include("../../common/db.php");
require_once(__DIR__ . '/log_helper.php');

function logToFile($message, $data = []) {
    $timestamp = date('Y-m-d H:i:s');
    $logEntry = "[$timestamp] $message\n";
    if (!empty($data)) {
        $logEntry .= "Data: " . json_encode($data, JSON_PRETTY_PRINT) . "\n";
    }
    $logEntry .= str_repeat('-', 80) . "\n";
    fogshield_log_write('vendor_add', $logEntry);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Only POST allowed"]);
    exit;
}

$usr_id         = $_POST['usr_id']         ?? null;
$vendor_name    = $_POST['vendor_name']    ?? '';
$vendor_email   = $_POST['vendor_email']   ?? '';
// Accept both param names for mobile
$vendor_mob_no  = $_POST['vendor_mob_no']  ?? ($_POST['vendor_mobile'] ?? '');
$vendor_address = $_POST['vendor_address'] ?? '';

logToFile("Add vendor attempt", [
    'usr_id'         => $usr_id,
    'vendor_name'    => $vendor_name,
    'vendor_email'   => $vendor_email,
    'vendor_mob_no'  => $vendor_mob_no,
    'vendor_address' => $vendor_address,
    'raw_post'       => $_POST
]);

if (!$usr_id) {
    echo json_encode(["status" => false, "msg" => "usr_id is required"]);
    exit;
}

$sql = "UPDATE tbl_fogshield_users 
        SET vendor_name = ?, vendor_email = ?, vendor_mob_no = ?, vendor_address = ? 
        WHERE usr_id = ?";
$params = [$vendor_name, $vendor_email, $vendor_mob_no, $vendor_address, $usr_id];

$stmt = sqlsrv_query($con, $sql, $params);

if ($stmt) {
    $affected = sqlsrv_rows_affected($stmt);
    logToFile("Vendor updated", ['usr_id' => $usr_id, 'rows_affected' => $affected]);
    if ($affected > 0) {
        echo json_encode(["status" => true, "msg" => "Vendor details updated successfully"]);
    } else {
        echo json_encode(["status" => false, "msg" => "No user found with this usr_id"]);
    }
} else {
    $err = sqlsrv_errors();
    logToFile("ERROR: Vendor update failed", ['usr_id' => $usr_id, 'error' => $err]);
    echo json_encode(["status" => false, "msg" => "Update failed"]);
}

sqlsrv_close($con);
