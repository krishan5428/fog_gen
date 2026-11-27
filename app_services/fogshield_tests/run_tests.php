<?php
// Tests for app_services/fogshield/*.php — no database needed.
// Run: php app_services/fogshield_tests/run_tests.php
// Each case runs the endpoint in a separate PHP process against a fake
// sqlsrv (fx/common/db.php) and checks the JSON reply + the SQL it sent.

$failures = 0;
$passes = 0;

function run_endpoint($endpoint, $post, $rules = [], $env = []) {
    $log = tempnam(sys_get_temp_dir(), 'fsq');
    $logDir = sys_get_temp_dir() . '/fogshield_test_logs';
    $vars = array_merge([
        'FS_SCENARIO' => json_encode($rules),
        'FS_QUERY_LOG' => $log,
        'FOGSHIELD_LOG_DIR' => $logDir,
        'FOGSHIELD_CONFIG' => __DIR__ . '/fx/config.test.php',
    ], $env);
    $cmd = '';
    foreach ($vars as $k => $v) $cmd .= $k . '=' . escapeshellarg($v) . ' ';
    $cmd .= escapeshellarg(PHP_BINARY) . ' ' . escapeshellarg(__DIR__ . '/harness.php') . ' '
          . escapeshellarg($endpoint) . ' ' . escapeshellarg(json_encode($post)) . ' 2>&1';
    $out = shell_exec($cmd);
    $queries = [];
    foreach (file($log, FILE_IGNORE_NEW_LINES) ?: [] as $line) $queries[] = json_decode($line, true);
    unlink($log);
    return [json_decode($out, true), $queries, $out];
}

function check($name, $cond, $detail = '') {
    global $failures, $passes;
    if ($cond) { $passes++; echo "  ok   $name\n"; }
    else { $failures++; echo "  FAIL $name" . ($detail !== '' ? "\n       $detail" : '') . "\n"; }
}

function find_query($queries, $regex) {
    foreach ($queries as $q) if (preg_match('/' . $regex . '/i', $q['sql'])) return $q;
    return null;
}

$g4 = [
    'usr_id' => '3', 'pnl_type' => '4GCOM', 'panel_name' => 'FIRE PANEL-4 ZONE - F04L G4',
    'panel_imei' => '861919084418721', 'site_name' => 'Site', 'pass' => '001234',
    'pnl_acc_no' => '', 'is_ip_panel' => '0', 'is_ip_gsm_panel' => '0',
];
$insertOk = ['match' => 'INSERT INTO tbl_panel_fogshield', 'rows' => [['pnl_id' => 55]]];

echo "add_panel.php\n";

[$r, $q, $raw] = run_endpoint('add_panel.php', $g4, [
    ['match' => 'SELECT TOP 1 CAST\\(panel_id AS INT\\)', 'rows' => [['panel_id' => 100123]]],
    $insertOk,
]);
check('G4 new: next free number after the highest in tbl_pnl_map', ($r['panel_acc_no'] ?? null) === '100124', $raw);
check('G4 new: returns pnl_id from the insert', ($r['pnl_id'] ?? null) === 55 && $r['status'] === true);
check('G4 new: panel_id alias = panel_acc_no', ($r['panel_id'] ?? null) === '100124');
$ins = find_query($q, 'INSERT INTO tbl_panel_fogshield');
check('G4 new: IMEI and 4GCOM stored', $ins && in_array('861919084418721', $ins['params'], true) && in_array('4GCOM', $ins['params'], true));
$map = find_query($q, 'MERGE INTO tbl_pnl_map');
check('G4 new: routed as app fogshield with IMEI', $map && $map['params'][1] === 'fogshield' && $map['params'][3] === '861919084418721');
$z = find_query($q, 'INSERT INTO tbl_fogshield_zone_map');
check('G4 new: default zone names seeded in tbl_fogshield_zone_map (fog column, int usr_id)',
    $z && str_contains($z['sql'], ', fog,') && $z['params'] === ['100124', 3]);
check('Nothing written to tbl_fogshield_event_map (code → name table on the server)', find_query($q, 'tbl_fogshield_event_map') === null);
check('G4 new: no posted/empty pnl_acc_no column duplicated', substr_count($ins['sql'] ?? '', 'pnl_acc_no') === 1);

[$r] = run_endpoint('add_panel.php', array_merge($g4, ['panel_imei' => '']));
check('G4 without IMEI rejected', $r['status'] === false && str_contains($r['msg'], 'panel_imei is required'));

[$r] = run_endpoint('add_panel.php', array_merge($g4, ['pnl_type' => 'FIRE PANEL']));
check('Unknown panel type rejected', $r['status'] === false && str_contains($r['msg'], 'Unknown panel type'));

[$r] = run_endpoint('add_panel.php', array_diff_key($g4, ['usr_id' => 1]));
check('Missing usr_id rejected', $r['status'] === false && $r['msg'] === 'usr_id is required');

[$r, $q] = run_endpoint('add_panel.php', $g4, [
    ['match' => 'SELECT pnl_id FROM tbl_panel_fogshield WHERE panel_imei', 'rows' => [['pnl_id' => 9]]],
]);
check('Live duplicate IMEI rejected, nothing inserted',
    $r['status'] === false && str_contains($r['msg'], 'IMEI') && find_query($q, 'INSERT INTO tbl_panel_fogshield') === null);

[$r] = run_endpoint('add_panel.php', $g4, [
    ['match' => 'SELECT TOP 1 pnl_acc_no FROM tbl_panel_fogshield WHERE panel_imei', 'rows' => [['pnl_acc_no' => '100050']]],
    $insertOk,
]);
check('Re-added hardware gets its old FogShield number back', ($r['panel_acc_no'] ?? null) === '100050');

[$r] = run_endpoint('add_panel.php', $g4, [
    ['match' => 'SELECT TOP 1 panel_id FROM tbl_pnl_map WHERE imei', 'rows' => [['panel_id' => '100077']]],
    $insertOk,
]);
check('Hardware known to another app keeps that number', ($r['panel_acc_no'] ?? null) === '100077');

[$r] = run_endpoint('add_panel.php', $g4, [
    ['match' => 'SELECT TOP 1 CAST\\(panel_id AS INT\\)', 'rows' => [['panel_id' => 100123]]],
    $insertOk,
], ['FS_LOCKED' => '100124,100125']);
check('Locked numbers are skipped', ($r['panel_acc_no'] ?? null) === '100126');

[$r] = run_endpoint('add_panel.php', $g4, [
    ['match' => 'SELECT TOP 1 pnl_acc_no FROM tbl_panel_fogshield WHERE panel_imei', 'rows' => [['pnl_acc_no' => '100050']]],
    ['match' => 'SELECT TOP 1 CAST\\(panel_id AS INT\\)', 'rows' => [['panel_id' => 100123]]],
    $insertOk,
], ['FS_LOCKED' => '100050']);
check('A locked old number is not reused', ($r['panel_acc_no'] ?? null) === '100124');

[$r] = run_endpoint('add_panel.php', $g4, [
    ['match' => 'SELECT TOP 1 CAST\\(panel_id AS INT\\)', 'rows' => []],
    $insertOk,
]);
check('Empty map starts at 100001', ($r['panel_acc_no'] ?? null) === '100001');

$sr1 = ['usr_id' => '3', 'pnl_type' => 'FOGGER PANEL', 'panel_name' => 'FogShield Pro',
        'pnl_mac' => '004145098123236254', 'pnl_acc_no' => '999999', 'ip_add' => '1.2.3.4', 'port_no' => '5000',
        'is_ip_gsm_panel' => 'true'];
[$r, $q] = run_endpoint('add_panel.php', $sr1, [$insertOk]);
check('SR1: keeps the account number read from the panel', ($r['panel_acc_no'] ?? null) === '999999');
$ins = find_query($q, 'INSERT INTO tbl_panel_fogshield');
check('SR1: booleans stored as 1/0', $ins && in_array(1, $ins['params'], true));
$map = find_query($q, 'MERGE INTO tbl_pnl_map');
check('SR1: routed by MAC, no IMEI', $map && $map['params'][3] === null && $map['params'][4] === '004145098123236254');

[$r, $q] = run_endpoint('add_panel.php', $sr1, [
    ['match' => 'SELECT pnl_acc_no FROM tbl_panel_fogshield WHERE pnl_mac', 'rows' => [['pnl_acc_no' => '999999']]],
]);
check('SR1: live duplicate MAC rejected', $r['status'] === false && ($r['panel_id'] ?? null) === '999999');

[$r, $q] = run_endpoint('add_panel.php', $g4, [
    ['match' => 'INSERT INTO tbl_panel_fogshield', 'fail' => true],
]);
check('Insert failure → error, no routing row written',
    $r['status'] === false && $r['msg'] === 'Failed to add panel' && find_query($q, 'MERGE INTO tbl_pnl_map') === null);

[$r] = run_endpoint('add_panel.php', $g4, [], ['FS_METHOD' => 'GET']);
check('GET rejected', $r['status'] === false && $r['msg'] === 'Only POST allowed');

echo "get_panels.php\n";

[$r, $q] = run_endpoint('get_panels.php', ['usr_id' => '3'], [
    ['match' => 'FROM tbl_panel_fogshield', 'rows' => [
        ['pnl_id' => 1, 'site_name' => 'A', 'panel_imei' => null, 'status' => null],
        ['pnl_id' => 2, 'site_name' => 'B', 'panel_imei' => '861919084418721', 'status' => 'ACTIVE'],
    ]],
]);
check('Returns {status, msg, panels}', $r['status'] === true && count($r['panels']) === 2 && isset($r['msg']));
check('NULL columns become ""', $r['panels'][0]['panel_imei'] === '');
check('Every panel is the owner\'s', $r['panels'][1]['share_status'] === 'owner');
$sel = find_query($q, 'FROM tbl_panel_fogshield');
check('Only live panels of this user are read', $sel && str_contains($sel['sql'], "NOT IN ('inactive', 'deleted')") && $sel['params'] === ['3']);

[$r] = run_endpoint('get_panels.php', []);
check('Missing usr_id rejected', $r['status'] === false);

[$r] = run_endpoint('get_panels.php', ['usr_id' => '3'], [['match' => 'FROM tbl_panel_fogshield', 'fail' => true]]);
check('Query failure → status false', $r['status'] === false && $r['msg'] === 'Query failed');

echo "update_panel.php\n";

[$r, $q] = run_endpoint('update_panel.php', ['pnl_id' => '7', 'usr_id' => '3', 'site_name' => 'New', 'is_ip_panel' => 'false'], [
    ['match' => '^\\s*UPDATE tbl_panel_fogshield', 'affected' => 1],
    ['match' => 'SELECT \\* FROM tbl_panel_fogshield', 'rows' => [['pnl_id' => 7, 'site_name' => 'New', 'panel_imei' => null]]],
]);
check('Success returns the row as data and panelData',
    $r['status'] === true && $r['data']['site_name'] === 'New' && $r['panelData']['pnl_id'] === 7);
$up = find_query($q, '^UPDATE tbl_panel_fogshield');
check('Only posted fields are set; booleans as 1/0', $up && str_contains($up['sql'], 'site_name = ?') && $up['params'][1] === 0);

[$r, $q] = run_endpoint('update_panel.php', ['pnl_id' => '7', 'usr_id' => '3', 'pnl_type' => '4GCOM', 'panel_imei' => 'x']);
check('Routing fields (pnl_type, panel_imei) cannot be changed',
    $r['status'] === false && find_query($q, '^UPDATE') === null);

[$r] = run_endpoint('update_panel.php', ['pnl_id' => '7', 'usr_id' => '3', 'site_name' => 'X'], [
    ['match' => '^\\s*UPDATE tbl_panel_fogshield', 'affected' => 0],
]);
check('Someone else\'s / deleted panel → not found', $r['status'] === false && $r['msg'] === 'No matching panel found');

[$r] = run_endpoint('update_panel.php', ['usr_id' => '3', 'site_name' => 'X']);
check('Missing pnl_id rejected', $r['status'] === false);

echo "delete_panel.php\n";

[$r, $q] = run_endpoint('delete_panel.php', ['pnl_id' => '7', 'usr_id' => '3'], [
    ['match' => 'SELECT pnl_acc_no FROM tbl_panel_fogshield', 'rows' => [['pnl_acc_no' => '100124']]],
    ['match' => "SET status = 'DELETED'", 'affected' => 1],
]);
check('Soft delete succeeds', $r['status'] === true);
check('Routing row removed (fogshield only)', ($m = find_query($q, 'DELETE FROM tbl_pnl_map')) && str_contains($m['sql'], "app_name = 'fogshield'") && $m['params'] === ['100124']);
check('Zone names, custom event names, logs and G4 state removed',
    find_query($q, 'DELETE FROM tbl_fogshield_zone_map') && find_query($q, 'DELETE FROM tbl_fogshield_event_map')
    && find_query($q, 'DELETE FROM tbl_fogshield_logs') && find_query($q, 'DELETE FROM tbl_fogshield_4gcom_panel_state'));
check('Row is kept (no hard DELETE of the panel)', find_query($q, 'DELETE FROM tbl_panel_fogshield') === null);

[$r, $q] = run_endpoint('delete_panel.php', ['pnl_id' => '7', 'usr_id' => '4']);
check('Not the owner / not found → nothing deleted',
    $r['status'] === false && $r['msg'] === 'Panel not found' && find_query($q, '^DELETE') === null && find_query($q, "SET status = 'DELETED'") === null);

[$r, $q] = run_endpoint('delete_panel.php', ['pnl_id' => '7', 'usr_id' => '3'], [
    ['match' => 'SELECT pnl_acc_no FROM tbl_panel_fogshield', 'rows' => [['pnl_acc_no' => '100124']]],
    ['match' => "SET status = 'DELETED'", 'fail' => true],
]);
check('Delete failure → no cleanup', $r['status'] === false && find_query($q, 'DELETE FROM tbl_pnl_map') === null);

echo "fetch_logs.php\n";

$own = ['match' => 'SELECT TOP 1 pnl_type FROM tbl_panel_fogshield'];
[$r, $q, $raw] = run_endpoint('fetch_logs.php', ['usr_id' => '3', 'pnl_acc_no' => '999999', 'pnl_id' => '7',
    'ip_add' => '', 'port_no' => '', 'pnl_mac' => '', 'pnl_ver' => '', 'pnl_rcvr_no' => '', 'pnl_line_no' => ''], [
    $own + ['rows' => [['pnl_type' => 'FOGGER PANEL']]],
    ['match' => 'FROM tbl_gbl_logs', 'rows' => [
        ['gbl_lg_id' => 9, 'event_name' => 'Panel/Zone 1/Fog Triggered', 'event_time' => '2026-11-25 10:09:15'],
        ['gbl_lg_id' => 8, 'event_name' => '', 'event_time' => null],
    ]],
]);
check('SR1: empty IP/MAC fields are accepted (old endpoint rejected them)', $r['status'] === true, $raw);
check('SR1: logs from tbl_gbl_logs, newest first, last 20', ($g = find_query($q, 'FROM tbl_gbl_logs')) && str_contains($g['sql'], 'TOP 20') && $g['params'] === ['999999']);
check('SR1: event name = last segment, time d-m-Y H:i:s (what the app parses)',
    $r['logs'][0]['event_name'] === 'Fog Triggered' && $r['logs'][0]['event_time'] === '25-11-2026 10:09:15');
check('SR1: blank name → "Unknown Panel Event"', $r['logs'][1]['event_name'] === 'Unknown Panel Event' && $r['logs'][1]['event_time'] === '');
$o = find_query($q, 'SELECT TOP 1 pnl_type');
check('Only the user\'s own live panel', $o && $o['params'] === ['999999', '3'] && str_contains($o['sql'], "NOT IN ('inactive', 'deleted')"));

[$r, $q] = run_endpoint('fetch_logs.php', ['usr_id' => '3', 'pnl_acc_no' => '100124'], [
    $own + ['rows' => [['pnl_type' => '4GCOM']]],
    ['match' => 'FROM tbl_fogshield_logs', 'rows' => [
        ['id' => 21, 'event_name' => 'Evacuation', 'c_on' => '2026-11-25 10:09:15', 'status' => 'SENT'],
    ]],
]);
check('G4: logs from tbl_fogshield_logs (where the G4 handler writes)',
    $r['status'] === true && find_query($q, 'FROM tbl_gbl_logs') === null && $r['logs'][0]['event_name'] === 'Evacuation');
check('G4: event_time from c_on in the app\'s format', $r['logs'][0]['event_time'] === '25-11-2026 10:09:15');

[$r, $q] = run_endpoint('fetch_logs.php', ['usr_id' => '4', 'pnl_acc_no' => '999999']);
check('Someone else\'s panel → "Panel not found", no logs read',
    $r['status'] === false && $r['msg'] === 'Panel not found' && find_query($q, 'tbl_gbl_logs|tbl_fogshield_logs') === null);

[$r] = run_endpoint('fetch_logs.php', ['usr_id' => '3']);
check('Missing pnl_acc_no rejected', $r['status'] === false);

[$r] = run_endpoint('fetch_logs.php', ['usr_id' => '3', 'pnl_acc_no' => '999999'], [
    $own + ['rows' => [['pnl_type' => 'FOGGER PANEL']]],
    ['match' => 'FROM tbl_gbl_logs', 'fail' => true],
]);
check('Query failure → status false', $r['status'] === false && $r['msg'] === 'Query failed');

echo "users: signup / login / update_user / logout / del_user / forgot_password\n";

[$r, $q] = run_endpoint('signup.php', ['name' => 'A', 'mobile' => '9000000001', 'email' => 'a@x.in', 'password' => 'p1', 'dev_info' => 'pixel']);
$i = find_query($q, 'INSERT INTO tbl_fogshield_users');
check('Signup: new mobile → inserted ACTIVE into tbl_fogshield_users', $r['status'] === true && $r['msg'] === 'User registered successfully'
    && $i && $i['params'][1] === '9000000001' && $i['params'][3] === 'p1');
check('Signup: no role columns written (table has none)', $i && !str_contains($i['sql'], 'role'));

[$r, $q] = run_endpoint('signup.php', ['name' => 'A2', 'mobile' => '9000000001', 'password' => 'p2'], [
    ['match' => 'SELECT usr_id FROM tbl_fogshield_users WHERE mobile', 'rows' => [['usr_id' => 7]]],
]);
check('Signup: existing mobile → re-activated and updated (FireNex behaviour)', $r['msg'] === 'User updated successfully'
    && find_query($q, '^UPDATE tbl_fogshield_users') && find_query($q, 'INSERT INTO') === null);

[$r] = run_endpoint('signup.php', ['mobile' => '9000000001']);
check('Signup: password required', $r['status'] === false);

$user = ['usr_id' => 7, 'name' => 'A', 'email' => 'a@x.in', 'mobile' => '9000000001', 'status' => 'ACTIVE',
         'dev_info' => null, 'enrolled_on' => '2026-11-27 10:00:00', 'c_on' => '2026-11-27 10:00:00', 'vendor_name' => null];
[$r, $q, $raw] = run_endpoint('login.php', ['mobile' => '9000000001', 'pass' => 'p1', 'dev_id' => 'fcm-1'], [
    ['match' => 'FROM tbl_fogshield_users WHERE mobile = \\? AND password', 'rows' => [$user]],
]);
check('Login: returns data + token (the shape the app reads)', $r['status'] === true && $r['data']['usr_id'] === 7
    && $r['token'] === 'jwt-for-7' && $r['data']['dev_info'] === '', $raw);
$t = find_query($q, 'MERGE INTO tbl_fogshield_device_tokens');
check('Login: phone token saved with c_on (NOT NULL on the server)', $t && $t['params'] === [7, 'fcm-1'] && str_contains($t['sql'], 'c_on'));
check('Login: only ACTIVE users', ($l = find_query($q, 'AND password = \\?')) && str_contains($l['sql'], "status = 'ACTIVE'"));

[$r] = run_endpoint('login.php', ['mobile' => '9000000009', 'pass' => 'x'], [['match' => 'COUNT\\(\\*\\)', 'rows' => [['cnt' => 0]]]]);
check('Login: unknown mobile → "User not registered"', $r['msg'] === 'User not registered');
[$r] = run_endpoint('login.php', ['mobile' => '9000000001', 'pass' => 'bad'], [['match' => 'COUNT\\(\\*\\)', 'rows' => [['cnt' => 1]]]]);
check('Login: wrong password → "Invalid mobile or password"', $r['msg'] === 'Invalid mobile or password');

[$r, $q] = run_endpoint('update_user.php', ['usr_id' => '7', 'device_id' => 'fcm-2']);
check('update_user: token via device_id (what the app\'s splash sends) → saved',
    $r['status'] === true && ($t = find_query($q, 'MERGE INTO tbl_fogshield_device_tokens')) && $t['params'] === [7, 'fcm-2']);

[$r, $q] = run_endpoint('update_user.php', ['usr_id' => '7', 'email' => 'new@x.in'], [
    ['match' => '^\\s*UPDATE tbl_fogshield_users', 'affected' => 1],
]);
$u = find_query($q, '^UPDATE tbl_fogshield_users');
check('update_user: profile edit (email) saved — FireNex\'s version would not',
    $r['status'] === true && $r['message'] === 'Updated successfully' && $u && str_contains($u['sql'], 'email = ?') && $u['params'] === ['new@x.in', 7]);

[$r, $q] = run_endpoint('update_user.php', ['usr_id' => '7', 'mobile' => '9000000002'], [
    ['match' => 'WHERE mobile = \\? AND usr_id <> \\?', 'rows' => [['usr_id' => 8]]],
]);
check('update_user: mobile taken by another user → rejected, nothing written',
    $r['status'] === false && find_query($q, '^UPDATE') === null);

[$r] = run_endpoint('update_user.php', ['usr_id' => '7', 'password' => '']);
check('update_user: empty password rejected', $r['status'] === false);
[$r] = run_endpoint('update_user.php', ['usr_id' => '7', 'role' => 'admin']);
check('update_user: unknown fields only → "Nothing to update"', $r['status'] === false && $r['message'] === 'Nothing to update');

[$r, $q] = run_endpoint('logout.php', ['user_id' => '7', 'device_token' => 'fcm-1'], [['match' => 'DELETE FROM tbl_fogshield_device_tokens', 'affected' => 1]]);
check('Logout: removes only this phone\'s token', $r['status'] === true && ($d = find_query($q, 'DELETE FROM tbl_fogshield_device_tokens')) && $d['params'] === [7, 'fcm-1']);

[$r, $q] = run_endpoint('del_user.php', ['mobile' => '9000000001', 'pass' => 'p1'], [['match' => "SET status = 'STOP'", 'affected' => 1]]);
check('Delete account: status STOP (row kept, login refuses it)', $r['status'] === true && find_query($q, "^UPDATE tbl_fogshield_users SET status = 'STOP'"));
[$r] = run_endpoint('del_user.php', ['mobile' => '9000000001', 'pass' => 'bad'], [['match' => "SET status = 'STOP'", 'affected' => 0]]);
check('Delete account: wrong password → refused', $r['status'] === false && $r['msg'] === 'Invalid Mobile or Password');

$mailLog = tempnam(sys_get_temp_dir(), 'fsm');
[$r] = run_endpoint('forgot_password.php', ['mobile' => '9000000001'], [
    ['match' => 'SELECT email, password FROM tbl_fogshield_users', 'rows' => [['email' => 'a@x.in', 'password' => 'p1']]],
], ['FS_MAIL_LOG' => $mailLog]);
$mail = json_decode(trim((string)file_get_contents($mailLog)), true);
check('Forgot password: emails the user, says FogShield (not FireNex)', $r['status'] === true && $mail
    && $mail['to'] === ['a@x.in'] && str_contains($mail['subject'], 'FogShield') && !str_contains($mail['body'] . $mail['from'], 'Firenex'));
unlink($mailLog);

// The mailer login comes from config, not from the code.
$credLog = tempnam(sys_get_temp_dir(), 'fsm');
run_endpoint('forgot_password.php', ['mobile' => '9000000001'], [
    ['match' => 'SELECT email, password FROM tbl_fogshield_users', 'rows' => [['email' => 'a@x.in', 'password' => 'p1']]],
], ['FS_MAIL_LOG' => $credLog]);
$mail = json_decode(trim((string)file_get_contents($credLog)), true);
check('Forgot password: SMTP user/password read from config', $mail
    && ($mail['username'] ?? null) === 'test-mailer@example.com' && ($mail['password'] ?? null) === 'test-smtp-pass'
    && str_contains($mail['from'], 'test-mailer@example.com'), json_encode($mail));
unlink($credLog);
$noMail = tempnam(sys_get_temp_dir(), 'fsm');
[, , $raw] = run_endpoint('forgot_password.php', ['mobile' => '9000000001'], [
    ['match' => 'SELECT email, password FROM tbl_fogshield_users', 'rows' => [['email' => 'a@x.in', 'password' => 'p1']]],
], ['FOGSHIELD_CONFIG' => '/nonexistent/config.php', 'FS_MAIL_LOG' => $noMail]);
// stdout also carries the error_log line here (CLI), so read the JSON line.
$r = json_decode((string)preg_replace('/^.*?(\{.*\})\s*$/s', '$1', $raw), true);
check('Forgot password: no mailer configured → clear error, nothing sent',
    ($r['status'] ?? null) === false && trim((string)file_get_contents($noMail)) === '', $raw);
unlink($noMail);

[$r] = run_endpoint('forgot_password.php', ['mobile' => '9000000001'], [
    ['match' => 'SELECT email, password', 'rows' => [['email' => '', 'password' => 'p1']]],
]);
check('Forgot password: no email on file → error', $r['status'] === false);

echo "vendors: add_vendor / get_vendors / del_vendor\n";

[$r, $q] = run_endpoint('add_vendor.php', ['usr_id' => '7', 'vendor_name' => 'V', 'vendor_email' => 'v@x.in', 'vendor_mobile' => '9111111111', 'vendor_address' => 'Addr'], [
    ['match' => 'UPDATE tbl_fogshield_users', 'affected' => 1],
]);
$u = find_query($q, 'UPDATE tbl_fogshield_users');
check('Add vendor: stored in the user row (vendor_mobile accepted as mobile)', $r['status'] === true && $u && $u['params'] === ['V', 'v@x.in', '9111111111', 'Addr', '7']);

[$r] = run_endpoint('get_vendors.php', ['usr_id' => '7'], [
    ['match' => 'SELECT vendor_name', 'rows' => [['vendor_name' => 'V', 'vendor_email' => 'v@x.in', 'vendor_mob_no' => '9111111111', 'vendor_address' => 'Addr']]],
]);
check('Get vendor: {status, vendor:{…}} (FireNex shape)', $r['status'] === true && $r['vendor']['vendor_mob_no'] === '9111111111');

[$r, $q] = run_endpoint('del_vendor.php', ['usr_id' => '7'], [
    ['match' => 'SELECT vendor_name FROM tbl_fogshield_users', 'rows' => [['vendor_name' => 'V']]],
    ['match' => 'SET vendor_name = NULL', 'affected' => 1],
]);
check('Delete vendor: clears the vendor fields', $r['status'] === true && find_query($q, 'SET vendor_name = NULL'));

echo "secrets: config only, never in code\n";

// G4 direct calls are checked against g4_secret from config.
$g4body = fn($secret) => json_encode(['secret' => $secret, 'imei' => '861919084418721', 'topic' => 'QlMQTT/861919084418721/a', 'packet' => 'garbage']);
[$r, , $raw] = run_endpoint('mqtt_4gcom_alert.php', [], [], ['FS_RAW_INPUT' => $g4body('wrong')]);
check('G4 direct call: wrong secret → Unauthorized', ($r['msg'] ?? null) === 'Unauthorized', $raw);
[$r, , $raw] = run_endpoint('mqtt_4gcom_alert.php', [], [], ['FS_RAW_INPUT' => $g4body('test-g4-secret')]);
// Accepted = gets past the secret check (then "Panel not found": no DB rows).
check('G4 direct call: secret from config → accepted', ($r['msg'] ?? null) === 'Panel not found', $raw);
[$r, , $raw] = run_endpoint('mqtt_4gcom_alert.php', [], [], ['FS_RAW_INPUT' => $g4body(''), 'FOGSHIELD_CONFIG' => '/nonexistent/config.php']);
check('G4 direct call: no secret configured → Unauthorized (fails closed)', ($r['msg'] ?? null) === 'Unauthorized', $raw);

// Committed code must carry no credentials: they live in config.php (not in git).
$leaks = [];
foreach (glob(__DIR__ . '/../fogshield/*.php') as $file) {
    if (basename($file) === 'config.php') continue;
    $src = file_get_contents($file);
    if (preg_match('/->Password\s*=\s*[\'"]|fourg_secret_|Basic [A-Za-z0-9+\/]{8,}={0,2}[\'"]/', $src)) $leaks[] = basename($file);
}
check('No password, G4 secret or Basic auth hardcoded in fogshield/*.php', $leaks === [], implode(', ', $leaks));
$example = include __DIR__ . '/../fogshield/config.example.php';
check('config.example.php lists every key, all values blank',
    is_array($example) && array_keys($example) === array_keys(include __DIR__ . '/fx/config.test.php')
    && array_filter($example) === []);

echo "\n$passes passed, $failures failed\n";
exit($failures === 0 ? 0 : 1);
