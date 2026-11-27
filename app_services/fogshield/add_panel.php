<?php
// fogshield/add_panel.php — add a FogShield panel (SR1 "FOGGER PANEL" or G4 "4GCOM").
// Based on firenex/add_panel.php. Differences: FogShield panel types,
// app_name 'fogshield', no factory-worker test history, $pnl_acc_no always
// initialised, response keys the FogShield app reads.
//
// Response (success): { status: true, msg, pnl_id, panel_acc_no, panel_id }
//   panel_id is the same value as panel_acc_no (FireNex name, kept for parity).
include("../../common/db.php");
include("../../common/panel_id_lock.php");
require_once(__DIR__ . '/log_helper.php');
header('Content-Type: application/json');

function fs_add_log($message, $data = []) {
    fogshield_log('panel_add', $message, $data);
}

function fs_add_fail($con, $msg, $extra = []) {
    echo json_encode(array_merge(["status" => false, "msg" => $msg], $extra));
    if ($con) sqlsrv_close($con);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    fs_add_fail(null, "Only POST allowed");
}

$usr_id     = trim($_POST['usr_id'] ?? '');
$pnl_mac    = trim($_POST['pnl_mac'] ?? '');     // SR1: read from the panel; duplicate check only
$panel_imei = trim($_POST['panel_imei'] ?? '');  // G4 only
$pnl_type   = trim($_POST['pnl_type'] ?? '');

if ($usr_id === '')   fs_add_fail($con, "usr_id is required");
if ($pnl_type === '') fs_add_fail($con, "pnl_type is required");

// Exactly the pnl_type values the FogShield app sends. Alert routing depends
// on these, so an unknown value is rejected instead of stored.
$allowedPnlTypes = ['FOGGER PANEL', '4GCOM'];
if (!in_array($pnl_type, $allowedPnlTypes, true)) {
    fs_add_log("Rejected unknown pnl_type", ['pnl_type' => $pnl_type]);
    fs_add_fail($con, "Unknown panel type: $pnl_type");
}
if ($pnl_type === '4GCOM' && $panel_imei === '') {
    fs_add_log("Rejected 4GCOM panel with no IMEI");
    fs_add_fail($con, "panel_imei is required for 4GCOM panels");
}

$live = fogshield_live_status_sql();

// ── Duplicates: a live panel with the same MAC / IMEI blocks re-adding ──
if ($pnl_mac !== '') {
    $stmt = sqlsrv_query($con, "SELECT pnl_acc_no FROM tbl_panel_fogshield WHERE pnl_mac = ? AND $live", [$pnl_mac]);
    if ($stmt && ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC))) {
        fs_add_log("Duplicate MAC rejected", ['pnl_mac' => $pnl_mac, 'pnl_acc_no' => $row['pnl_acc_no']]);
        fs_add_fail($con, "Panel already exists with this MAC address", ["panel_id" => $row['pnl_acc_no']]);
    }
}
if ($panel_imei !== '') {
    $stmt = sqlsrv_query($con, "SELECT pnl_id FROM tbl_panel_fogshield WHERE panel_imei = ? AND $live", [$panel_imei]);
    if ($stmt && ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC))) {
        fs_add_log("Duplicate IMEI rejected", ['panel_imei' => $panel_imei, 'pnl_id' => $row['pnl_id']]);
        fs_add_fail($con, "Panel already exists with this IMEI");
    }
}

// ── Account number ──
// SR1 panels report their own account number (read from the device by the
// app); keep it. G4 panels get one from the server:
//   1. this hardware's old FogShield number (deleted/inactive row), else
//   2. the number another app already gave this hardware (tbl_pnl_map), else
//   3. the next free 6-digit number in tbl_pnl_map (skipping locked ids).
$pnl_acc_no = null;
$posted_acc_no = trim($_POST['pnl_acc_no'] ?? '');
if ($pnl_type !== '4GCOM' && $posted_acc_no !== '') {
    $pnl_acc_no = $posted_acc_no;
}

if ($pnl_acc_no === null) {
    $reuse = null;
    if ($panel_imei !== '') {
        $stmt = sqlsrv_query($con,
            "SELECT TOP 1 pnl_acc_no FROM tbl_panel_fogshield
             WHERE panel_imei = ? AND NOT ($live) ORDER BY pnl_id DESC", [$panel_imei]);
        $row = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;
        if ($row) $reuse = $row['pnl_acc_no'];
    } elseif ($pnl_mac !== '') {
        $stmt = sqlsrv_query($con,
            "SELECT TOP 1 pnl_acc_no FROM tbl_panel_fogshield
             WHERE pnl_mac = ? AND NOT ($live) ORDER BY pnl_id DESC", [$pnl_mac]);
        $row = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;
        if ($row) $reuse = $row['pnl_acc_no'];
    }
    if ($reuse !== null && !isPanelIdLocked((int)$reuse)) {
        $pnl_acc_no = $reuse;
        fs_add_log("Reusing this hardware's previous FogShield number", ['pnl_acc_no' => $pnl_acc_no]);
    }
}

if ($pnl_acc_no === null) {
    $cross = null;
    if ($panel_imei !== '') {
        $stmt = sqlsrv_query($con,
            "SELECT TOP 1 panel_id FROM tbl_pnl_map WHERE imei = ? ORDER BY CAST(panel_id AS INT) DESC", [$panel_imei]);
        $row = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;
        if ($row) $cross = $row['panel_id'];
    } elseif ($pnl_mac !== '') {
        $stmt = sqlsrv_query($con,
            "SELECT TOP 1 panel_id FROM tbl_pnl_map WHERE pnl_mac = ? ORDER BY CAST(panel_id AS INT) DESC", [$pnl_mac]);
        $row = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;
        if ($row) $cross = $row['panel_id'];
    }
    if ($cross !== null && !isPanelIdLocked((int)$cross)) {
        $pnl_acc_no = $cross;
        fs_add_log("Reusing the number another app gave this hardware", ['pnl_acc_no' => $pnl_acc_no]);
    }
}

if ($pnl_acc_no === null) {
    $stmt = sqlsrv_query($con,
        "SELECT TOP 1 CAST(panel_id AS INT) AS panel_id FROM tbl_pnl_map
         WHERE CAST(panel_id AS INT) BETWEEN 100001 AND 999999
         ORDER BY CAST(panel_id AS INT) DESC");
    $row = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;
    $next = ($row && !empty($row['panel_id'])) ? (int)$row['panel_id'] + 1 : 100001;
    $tries = 0;
    while (isPanelIdLocked($next)) {
        $next++;
        if (++$tries > 1000 || $next > 999999) {
            fs_add_log("ERROR: no free panel number in range");
            fs_add_fail($con, "Unable to assign panel ID, please try again later");
        }
    }
    $pnl_acc_no = str_pad((string)$next, 6, '0', STR_PAD_LEFT);
}

// ── Insert ──
$allowedFields = [
    'panel_name', 'site_name', 'site_address',
    'pnl_ver', 'pnl_line_no', 'pnl_rcvr_no',
    'ip_add', 'port_no', 'static_ip', 'static_port', 'pass',
    'admin_code', 'usr_1', 'usr_2', 'usr_3', 'usr_4',
    'panel_sim_number', 'admin_mobile_number', 'mobile_number_sub_id',
    'mobile_number1', 'mobile_number2', 'mobile_number3', 'mobile_number4',
    'mobile_number5', 'mobile_number6', 'mobile_number7', 'mobile_number8',
    'mobile_number9', 'mobile_number10', 'is_ip_panel', 'is_ip_gsm_panel',
];
$columns = ['usr_id', 'c_on', 'pnl_acc_no', 'pnl_type'];
$params  = [$usr_id, date('Y-m-d H:i:s'), $pnl_acc_no, $pnl_type];
if ($pnl_mac !== '')    { $columns[] = 'pnl_mac';    $params[] = $pnl_mac; }
if ($panel_imei !== '') { $columns[] = 'panel_imei'; $params[] = $panel_imei; }
foreach ($allowedFields as $field) {
    if (!isset($_POST[$field])) continue;
    $columns[] = $field;
    $params[] = in_array($field, ['is_ip_panel', 'is_ip_gsm_panel'], true)
        ? (filter_var($_POST[$field], FILTER_VALIDATE_BOOLEAN) ? 1 : 0)
        : $_POST[$field];
}
$placeholders = implode(', ', array_fill(0, count($columns), '?'));
$sql = "INSERT INTO tbl_panel_fogshield (" . implode(', ', $columns) . ")
        OUTPUT INSERTED.pnl_id VALUES ($placeholders)";
$stmt = sqlsrv_query($con, $sql, $params);
$row  = $stmt ? sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC) : null;
if (!$row || empty($row['pnl_id'])) {
    fs_add_log("ERROR: insert failed", ['error' => sqlsrv_errors()]);
    fs_add_fail($con, "Failed to add panel");
}
$pnl_id = (int)$row['pnl_id'];

// ── Routing (alerts) + default zone names ──
// (zone names go to tbl_fogshield_zone_map, see below)
// tbl_pnl_map row → root routers send this panel's SR1 logs to
// fogshield/sync_panel_log.php and its MQTT events to
// fogshield/mqtt_4gcom_alert.php. Both handlers must be deployed with this file.
$map = sqlsrv_query($con,
    "MERGE INTO tbl_pnl_map AS t
     USING (VALUES (?, ?, ?, ?, ?)) AS s(panel_id, app_name, usr_id, imei, pnl_mac)
     ON t.panel_id = s.panel_id AND t.app_name = s.app_name
     WHEN NOT MATCHED THEN
         INSERT (panel_id, app_name, usr_id, imei, pnl_mac)
         VALUES (s.panel_id, s.app_name, s.usr_id, s.imei, s.pnl_mac)
     WHEN MATCHED THEN
         UPDATE SET t.usr_id = s.usr_id,
                    t.imei = ISNULL(s.imei, t.imei),
                    t.pnl_mac = ISNULL(s.pnl_mac, t.pnl_mac);",
    [$pnl_acc_no, 'fogshield', $usr_id,
     $panel_imei !== '' ? $panel_imei : null,
     $pnl_mac !== '' ? $pnl_mac : null]);
if ($map === false) {
    fs_add_log("WARNING: tbl_pnl_map seed failed", ['error' => sqlsrv_errors()]);
}

// Zone names: tbl_fogshield_zone_map (FireNex keeps these in
// tbl_firenex_event_map; FogShield's event_map is a code → name table).
$zone = sqlsrv_query($con,
    "INSERT INTO tbl_fogshield_zone_map (panel_id, usr_id, zone_1, zone_2, zone_3, zone_4, fog, updated_on)
     VALUES (?, ?, 'Zone 1', 'Zone 2', 'Zone 3', 'Zone 4', 'Fog Alert', GETDATE())",
    [$pnl_acc_no, (int)$usr_id]);
if ($zone === false) {
    fs_add_log("WARNING: zone map seed failed", ['error' => sqlsrv_errors()]);
}

fs_add_log("Panel added", [
    'usr_id' => $usr_id, 'pnl_id' => $pnl_id, 'pnl_acc_no' => $pnl_acc_no,
    'pnl_type' => $pnl_type, 'panel_imei' => $panel_imei,
]);

echo json_encode([
    "status"       => true,
    "msg"          => "Panel added successfully",
    "pnl_id"       => $pnl_id,
    "panel_acc_no" => $pnl_acc_no,
    "panel_id"     => $pnl_acc_no,
]);
sqlsrv_close($con);
