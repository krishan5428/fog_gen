<?php
// fogshield/get_vendors.php — from firenex/get_vendors.php (vendor details live in the user's row of
// tbl_fogshield_users). Table and log helper renamed only.
header('Content-Type: application/json');
include("../../common/db.php");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => false, "msg" => "Only POST allowed"]);
    exit;
}

$usr_id = $_POST['usr_id'] ?? null;

if (!$usr_id) {
    echo json_encode(["status" => false, "msg" => "usr_id is required"]);
    exit;
}

$sql = "SELECT vendor_name, vendor_email, vendor_mob_no, vendor_address
        FROM tbl_fogshield_users
        WHERE usr_id = ?";

$stmt = sqlsrv_query($con, $sql, [$usr_id]);

if ($stmt && sqlsrv_has_rows($stmt)) {
    $row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC);

    // Check if any vendor field is actually filled
    $hasVendor = !empty($row['vendor_name']) || !empty($row['vendor_email'])
              || !empty($row['vendor_mob_no']) || !empty($row['vendor_address']);

    if ($hasVendor) {
        echo json_encode([
            "status"  => true,
            "vendor"  => $row
        ]);
    } else {
        echo json_encode([
            "status" => false,
            "msg"    => "No vendor details found for this user"
        ]);
    }
} else {
    if ($stmt === false) {
        error_log("get_vendors.php SQL error: " . print_r(sqlsrv_errors(), true));
    }
    echo json_encode([
        "status" => false,
        "msg"    => "User not found"
    ]);
}

sqlsrv_close($con);
