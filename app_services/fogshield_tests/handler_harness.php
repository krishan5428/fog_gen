<?php
// Runs per-app handlers the way the root routers do: one PHP process, the
// router's variables in scope, each handler setting $json. Lives in a temp
// copy of app_services (see run_handler_tests.php), so every log file the
// handlers write stays in that temp tree.
// argv[1]: comma-separated handler paths relative to this file's folder.
// env FS_ROUTER_VARS: json of router variables (routeRow, imei, packet, json_pkt…)
chdir(__DIR__ . '/fogshield');                 // include("../../common/…") → fake common
include("../../common/db.php");
foreach (json_decode(getenv('FS_ROUTER_VARS') ?: '{}', true) as $k => $v) $$k = $v;
$results = [];
foreach (explode(',', $argv[1]) as $h) {
    unset($json);
    require __DIR__ . '/' . $h;
    $results[$h] = $json ?? null;
}
echo json_encode($results);
