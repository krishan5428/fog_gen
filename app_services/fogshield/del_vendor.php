<?php
// fogshield/del_vendor.php — from firenex/del_vendor.php (vendor details live in the user's row of
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
    fogshield_log_write('vendor_delete', $logEntry);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Only POST allowed"]);
    exit;
}

$usr_id = $_POST['usr_id'] ?? null;

if (!$usr_id) {
    echo json_encode(["status" => false, "msg" => "usr_id is required"]);
    exit;
}

logToFile("Delete vendor attempt", ['usr_id' => $usr_id]);

// First check if user exists and has vendor details
$checkSql  = "SELECT vendor_name FROM tbl_fogshield_users WHERE usr_id = ?";
$checkStmt = sqlsrv_query($con, $checkSql, [$usr_id]);

if (!$checkStmt || !sqlsrv_has_rows($checkStmt)) {
    echo json_encode(["status" => false, "msg" => "User not found"]);
    sqlsrv_close($con);
    exit;
}

$checkRow = sqlsrv_fetch_array($checkStmt, SQLSRV_FETCH_ASSOC);

if (empty($checkRow['vendor_name'])) {
    echo json_encode(["status" => false, "msg" => "No vendor details found for this user"]);
    sqlsrv_close($con);
    exit;
}

// Clear all vendor fields (set to NULL)
$sql = "UPDATE tbl_fogshield_users
        SET vendor_name = NULL, vendor_email = NULL, vendor_mob_no = NULL, vendor_address = NULL
        WHERE usr_id = ?";

$stmt = sqlsrv_query($con, $sql, [$usr_id]);

if ($stmt) {
    $affected = sqlsrv_rows_affected($stmt);
    if ($affected > 0) {
        logToFile("Vendor details deleted successfully", ['usr_id' => $usr_id]);
        echo json_encode(["status" => true, "msg" => "Vendor details deleted successfully"]);
    } else {
        logToFile("Delete vendor: no rows updated", ['usr_id' => $usr_id]);
        echo json_encode(["status" => false, "msg" => "No rows updated"]);
    }
} else {
    logToFile("ERROR: Delete vendor failed", ['usr_id' => $usr_id, 'error' => sqlsrv_errors()]);
    echo json_encode([
        "status" => false,
        "msg"    => "Delete failed"
    ]);
}

sqlsrv_close($con);
