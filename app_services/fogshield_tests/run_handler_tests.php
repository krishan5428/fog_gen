<?php
// Tests for fogshield/sync_panel_log.php (SR1 alerts) and
// fogshield/mqtt_4gcom_alert.php (G4 alerts), run the way the root routers
// run them (require inside one PHP process). No DB, no FCM, no AMS:
// fake sqlsrv + fake sendFCMNotification, AMS forwarding switched off.
// Run: php app_services/fogshield_tests/run_handler_tests.php

$failures = 0;
$passes = 0;

function check($name, $cond, $detail = '') {
    global $failures, $passes;
    if ($cond) { $passes++; echo "  ok   $name\n"; }
    else { $failures++; echo "  FAIL $name" . ($detail !== '' ? "\n       $detail" : '') . "\n"; }
}

function rcopy($src, $dst) {
    @mkdir($dst, 0777, true);
    foreach (scandir($src) as $f) {
        if ($f === '.' || $f === '..' || $f === 'logs' || $f === 'backup_2026-10-26') continue;
        is_dir("$src/$f") ? rcopy("$src/$f", "$dst/$f") : copy("$src/$f", "$dst/$f");
    }
}

// Temp copy: <tmp>/app/{firenex,fogshield,harness.php}, <tmp>/common (fakes)
$tmp = sys_get_temp_dir() . '/fogshield_handler_tests_' . getmypid();
rcopy(__DIR__ . '/../firenex', "$tmp/app/firenex");
rcopy(__DIR__ . '/../fogshield', "$tmp/app/fogshield");
rcopy(__DIR__ . '/fx/common', "$tmp/common");
copy(__DIR__ . '/handler_harness.php', "$tmp/app/harness.php");
// Fake values only — the real config.php (not in git) is never used here.
copy(__DIR__ . '/fx/config.test.php', "$tmp/app/fogshield/config.php");

function run_handlers($handlers, $vars, $rules = [], $env = []) {
    global $tmp;
    $qlog = tempnam(sys_get_temp_dir(), 'fsq');
    $flog = tempnam(sys_get_temp_dir(), 'fsf');
    $all = array_merge([
        'FS_SCENARIO' => json_encode($rules),
        'FS_QUERY_LOG' => $qlog,
        'FS_FCM_LOG' => $flog,
        'FS_ROUTER_VARS' => json_encode($vars),
        'FOGSHIELD_LOG_DIR' => "$tmp/fslogs",
        'FOGSHIELD_AMS_URL' => '',
    ], $env);
    $cmd = '';
    foreach ($all as $k => $v) if ($v !== false) $cmd .= $k . '=' . escapeshellarg($v) . ' ';
    $cmd .= escapeshellarg(PHP_BINARY) . ' ' . escapeshellarg("$tmp/app/harness.php") . ' '
          . escapeshellarg(implode(',', $handlers)) . ' 2>&1 </dev/null';
    $out = shell_exec($cmd);
    $q = array_map(fn($l) => json_decode($l, true), file($qlog, FILE_IGNORE_NEW_LINES) ?: []);
    $f = array_map(fn($l) => json_decode($l, true), file($flog, FILE_IGNORE_NEW_LINES) ?: []);
    unlink($qlog); unlink($flog);
    return [json_decode($out, true), $q, $f, $out];
}

function find_query($queries, $regex) {
    foreach ($queries as $q) if (preg_match('/' . $regex . '/i', $q['sql'])) return $q;
    return null;
}

// ─────────────────────────── SR1: sync_panel_log ───────────────────────────
echo "fogshield/sync_panel_log.php (SR1)\n";

$pkt = [
    'PanelId' => '999999', 'eventCode' => 'FG1', 'eventName' => 'Panel/Zone 1/Fog Triggered',
    'statusName' => 'Active', 'eventOccuranceTime' => '2026-11-25 10:09:15',
    'zoneeventtransationid' => 'trx-1', 'priorityName' => 'High', 'severityName' => 'Critical',
];
$vars = ['routeRow' => ['panel_id' => '999999', 'app_name' => 'fogshield', 'usr_id' => '3'],
         'json_pkt' => json_encode($pkt), 'decoded_json' => $pkt];
$happy = [
    ['match' => 'SELECT site_name FROM tbl_panel_fogshield', 'rows' => [['site_name' => 'Lab']]],
    ['match' => 'tbl_fogshield_device_tokens t', 'rows' => [['device_token' => 't1'], ['device_token' => 't2'], ['device_token' => 't1']]],
    ['match' => 'INSERT INTO tbl_fogshield_logs', 'rows' => [['id' => 11]]],
];

[$r, $q, $f, $raw] = run_handlers(['fogshield/sync_panel_log.php'], $vars, $happy);
$j = $r['fogshield/sync_panel_log.php'] ?? null;
check('Event → one push, router gets $json', $j && $j['status'] === true && $j['notifications_sent'] === 1 && count($f) === 1, $raw);
check('Push goes through the FogShield Firebase project', ($f[0]['appType'] ?? '') === 'fogshield');
check('Each device once (duplicate token removed)', ($f[0]['tokens'] ?? []) === ['t1', 't2']);
check('Legacy title and body kept',
    ($f[0]['title'] ?? '') === 'Alert!' && ($f[0]['body'] ?? '') === "Lab\nFog Triggered\nActive On 25-11-2026 10:09:15");
check('Data the app reads: site_name, event_name, event_time',
    ($f[0]['customData']['site_name'] ?? '') === 'Lab' && $f[0]['customData']['event_name'] === 'Fog Triggered'
    && $f[0]['customData']['event_time'] === '25-11-2026 10:09:15' && $f[0]['customData']['log_id'] === '11');
check('Global logs written (tbl_jsn_sync, tbl_gbl_logs)', find_query($q, 'INSERT INTO tbl_jsn_sync') && find_query($q, 'INSERT INTO tbl_gbl_logs'));
check('FogShield log row marked SENT', ($u = find_query($q, 'UPDATE tbl_fogshield_logs SET status')) && $u['params'][0] === 'SENT' && $u['params'][2] === 11);
$t = find_query($q, 'tbl_fogshield_device_tokens t');
check('Tokens of every live owner of this account number (legacy behaviour)',
    $t && $t['params'] === ['999999'] && str_contains($t['sql'], 'FROM tbl_panel_fogshield p')
    && str_contains($t['sql'], "NOT IN ('inactive', 'deleted')"));

[$r, $q, $f] = run_handlers(['fogshield/sync_panel_log.php'], $vars, array_merge(
    [['match' => 'SELECT TOP 1 id FROM tbl_fogshield_logs', 'rows' => [['id' => 5]]]], $happy));
check('Same code within 20 s → skipped, no push',
    ($r['fogshield/sync_panel_log.php']['msg'] ?? '') === 'Duplicate skipped' && count($f) === 0);

[$r, $q, $f] = run_handlers(['fogshield/sync_panel_log.php'], $vars, [
    ['match' => 'tbl_fogshield_device_tokens t', 'rows' => []],
    ['match' => 'INSERT INTO tbl_fogshield_logs', 'rows' => [['id' => 12]]],
]);
$ins = find_query($q, 'INSERT INTO tbl_fogshield_logs');
check('No tokens → logged NO_TOKENS, no push', count($f) === 0 && $ins && $ins['params'][8] === 'NO_TOKENS');

[$r, $q, $f] = run_handlers(['fogshield/sync_panel_log.php'], $vars, $happy,
    ['FS_FCM_RESULT' => '{"sent":1,"failed":1,"invalid_tokens":["t2"]}']);
$d = find_query($q, 'DELETE FROM tbl_fogshield_device_tokens');
check('Token FCM rejects is removed', $d && $d['params'] === ['t2']);

[$r, $q, $f] = run_handlers(['fogshield/sync_panel_log.php'], $vars, array_merge(
    [['match' => 'FROM tbl_gbl_logs WHERE zone_event_trx_id', 'rows' => [['panel_id' => '999999']]]], $happy));
check('Already in the global log (another app) → not inserted twice, still pushed',
    find_query($q, 'INSERT INTO tbl_gbl_logs') === null && count($f) === 1);

// AMS settings come from fogshield/config.php: with an empty URL in the
// config and no env override, nothing is forwarded and the handler finishes.
$cfg = "$tmp/app/fogshield/config.php";
$cfgBackup = file_get_contents($cfg);
file_put_contents($cfg, "<?php return ['ams_url' => '', 'ams_auth' => ''];");
$t0 = microtime(true);
[$r] = run_handlers(['fogshield/sync_panel_log.php'], $vars, $happy, ['FOGSHIELD_AMS_URL' => false]);
check('AMS off via config.php (empty URL) → handler finishes, no forward',
    ($r['fogshield/sync_panel_log.php']['status'] ?? null) === true && microtime(true) - $t0 < 5);
file_put_contents($cfg, $cfgBackup);
$real = __DIR__ . '/../fogshield/config.php';
if (is_file($real)) { // only on a machine that has the real config
    $loaded = include $real;
    check('Real config.php has every key set', is_array($loaded)
        && count(array_filter($loaded)) === count(include __DIR__ . '/fx/config.test.php'));
}

[$r, $q, $f, $raw] = run_handlers(['firenex/sync_panel_log.php', 'fogshield/sync_panel_log.php'], $vars, $happy);
check('FireNex + FogShield handlers in one request: no clash, both answer',
    is_array($r) && array_key_exists('firenex/sync_panel_log.php', $r) && ($r['fogshield/sync_panel_log.php']['status'] ?? null) === true, $raw);

// ─────────────────────────── G4: mqtt_4gcom_alert ──────────────────────────
echo "fogshield/mqtt_4gcom_alert.php (G4)\n";

$imei = '861919084418721';
$g4vars = fn($packet) => [
    'routeRow' => ['panel_id' => '100124', 'app_name' => 'fogshield', 'usr_id' => '3'],
    'imei' => $imei, 'topic' => "QlMQTT/$imei/a", 'packet' => $packet,
];
$g4panel = [
    ['match' => 'SELECT TOP 1 site_name, pnl_type FROM tbl_panel_fogshield', 'rows' => [['site_name' => 'Lab', 'pnl_type' => '4GCOM']]],
    ['match' => 'FROM tbl_fogshield_device_tokens', 'rows' => [['device_token' => 't1']]],
    ['match' => 'INSERT INTO tbl_fogshield_logs', 'rows' => [['id' => 21]]],
];
$evacuate = "ST*$imei\$100\$04\$01\$012\$081\$1*ED";

[$r, $q, $f, $raw] = run_handlers(['fogshield/mqtt_4gcom_alert.php'], $g4vars($evacuate), $g4panel);
$j = $r['fogshield/mqtt_4gcom_alert.php'] ?? null;
check('Evacuate ack (012, output 1) → one push', $j && $j['status'] === true && count($f) === 1, $raw);
check('G4 push uses the FogShield project and app tag',
    ($f[0]['appType'] ?? '') === 'fogshield' && ($f[0]['customData']['app'] ?? '') === 'fogshield');
check('Wording from 4gcom_events.xml ("Evacuation")',
    str_contains(($f[0]['title'] ?? '') . ' ' . ($f[0]['body'] ?? ''), 'Evacuation'), json_encode($f[0] ?? null));
check('Site lookup reads only the live row', ($s = find_query($q, 'SELECT TOP 1 site_name, pnl_type')) && str_contains($s['sql'], "NOT IN ('inactive', 'deleted')"));

[$r, $q, $f] = run_handlers(['fogshield/mqtt_4gcom_alert.php'], $g4vars($evacuate), array_merge(
    [['match' => 'SELECT TOP 1 id FROM tbl_fogshield_logs', 'rows' => [['id' => 20]]]], $g4panel));
check('Automatic OFF within 12 s → no second push',
    ($r['fogshield/mqtt_4gcom_alert.php']['msg'] ?? '') === 'Dedup skipped' && count($f) === 0);

[$r, $q, $f] = run_handlers(['fogshield/mqtt_4gcom_alert.php'], $g4vars($evacuate), [
    ['match' => 'SELECT TOP 1 site_name, pnl_type FROM tbl_panel_fogshield', 'rows' => [['site_name' => 'Lab', 'pnl_type' => 'FOGGER PANEL']]],
]);
check('MQTT packet for a non-4GCOM panel → ignored', count($f) === 0
    && str_contains($r['fogshield/mqtt_4gcom_alert.php']['msg'] ?? '', 'Not a 4GCOM'));

[$r, $q, $f] = run_handlers(['fogshield/mqtt_4gcom_alert.php'], $g4vars("ST*$imei\$001234\$01\$012\$081\$1*ED"), $g4panel);
check('App request echoed (type 01) → skipped, no push', count($f) === 0);

[$r, $q, $f] = run_handlers(['fogshield/mqtt_4gcom_alert.php'], $g4vars("ST*$imei\$100\$04\$00\$012\$081*ED"), $g4panel);
check('Nack → skipped, no push', count($f) === 0);

[$r, $q, $f, $raw] = run_handlers(['firenex/mqtt_4gcom_alert.php', 'fogshield/mqtt_4gcom_alert.php'], $g4vars($evacuate), $g4panel);
check('FireNex + FogShield G4 handlers in one request: no clash, both answer',
    is_array($r) && array_key_exists('firenex/mqtt_4gcom_alert.php', $r) && ($r['fogshield/mqtt_4gcom_alert.php']['status'] ?? null) === true, $raw);

// Clean up the temp tree.
exec('rm -rf ' . escapeshellarg($tmp));

echo "\n$passes passed, $failures failed\n";
exit($failures === 0 ? 0 : 1);
