<?php
// fogshield/config.example.php — template for fogshield/config.php.
// On the server: copy this file to config.php and fill in the values.
// config.php is gitignored — never commit real values.
//
//   ams_url    AMS (Alarm Monitoring System) URL; every SR1 event is forwarded
//              there. '' → forwarding off.
//   ams_auth   full Authorization header value for AMS ('' → no header).
//              FOGSHIELD_AMS_URL / FOGSHIELD_AMS_AUTH env vars win over both.
//   smtp_user  Gmail account forgot_password.php sends from.
//   smtp_pass  its app password. Blank → forgot password returns an error.
//   g4_secret  shared secret the MQTT bridge sends when it calls
//              mqtt_4gcom_alert.php directly. Blank → every direct call is
//              refused (calls through the root router don't need it).
return [
    'ams_url'    => '',
    'ams_auth'   => '',
    'smtp_user'  => '',
    'smtp_pass'  => '',
    'g4_secret'  => '',
];
