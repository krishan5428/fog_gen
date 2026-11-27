<?php
// fogshield/config_loader.php — reads fogshield/config.php once per request.
//
// config.php holds the per-server values and every credential (AMS auth,
// mailer login, G4 secret). It is NOT in git: copy config.example.php to
// config.php on the server and fill it in. FOGSHIELD_CONFIG, when set,
// points to another file (tests use fogshield_tests/fx/config.test.php).
// A missing file gives [] — callers treat a blank value as "not set up".

if (!function_exists('fogshield_config')) {
    function fogshield_config($key = null) {
        static $cfg = null;
        if ($cfg === null) {
            $path = getenv('FOGSHIELD_CONFIG') ?: __DIR__ . '/config.php';
            $loaded = is_file($path) ? (include $path) : [];
            $cfg = is_array($loaded) ? $loaded : [];
        }
        if ($key === null) return $cfg;
        return (string)($cfg[$key] ?? '');
    }
}
