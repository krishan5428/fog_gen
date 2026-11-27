<?php
// Test stand-in for common/db.php: a fake sqlsrv driven by FS_SCENARIO.
// Each rule: {"match": "<regex on SQL>", "rows": [...], "affected": n, "fail": bool}
// The first matching rule answers (rules with "once": true are used once).
// Every query is appended to FS_QUERY_LOG as {"sql", "params"}.
if (!defined('SQLSRV_FETCH_ASSOC')) define('SQLSRV_FETCH_ASSOC', 2);
$GLOBALS['__fs_rules'] = json_decode(getenv('FS_SCENARIO') ?: '[]', true);
$GLOBALS['__fs_used'] = [];
$con = 'fake-connection';

function sqlsrv_query($con, $sql, $params = []) {
    file_put_contents(getenv('FS_QUERY_LOG'),
        json_encode(['sql' => preg_replace('/\s+/', ' ', trim($sql)), 'params' => $params]) . "\n", FILE_APPEND);
    foreach ($GLOBALS['__fs_rules'] as $i => $rule) {
        if (!empty($rule['once']) && !empty($GLOBALS['__fs_used'][$i])) continue;
        if (preg_match('/' . $rule['match'] . '/is', preg_replace('/\s+/', ' ', trim($sql)))) {
            $GLOBALS['__fs_used'][$i] = true;
            if (!empty($rule['fail'])) return false;
            return (object)['rows' => $rule['rows'] ?? [], 'affected' => $rule['affected'] ?? 1];
        }
    }
    return (object)['rows' => [], 'affected' => 1]; // default: ok, no rows
}
function sqlsrv_fetch_array($stmt, $type = null) {
    if (!is_object($stmt) || empty($stmt->rows)) return null;
    return array_shift($stmt->rows);
}
function sqlsrv_rows_affected($stmt) { return is_object($stmt) ? $stmt->affected : false; }
function sqlsrv_errors() { return [['message' => 'fake error']]; }
function sqlsrv_close($con) { return true; }

// FCM stand-in: records calls in FS_FCM_LOG; FS_FCM_RESULT = json result.
function sendFCMNotification($tokens, $title, $body, $customData = [], $appType = 'connect') {
    if (getenv('FS_FCM_LOG')) {
        file_put_contents(getenv('FS_FCM_LOG'), json_encode(compact('tokens', 'title', 'body', 'customData', 'appType')) . "\n", FILE_APPEND);
    }
    return json_decode(getenv('FS_FCM_RESULT') ?: '{"sent":1,"failed":0,"invalid_tokens":[]}', true);
}
function normalizeDateTime($input) { return $input; }

function sqlsrv_has_rows($stmt) { return is_object($stmt) && !empty($stmt->rows); }

// JWT stand-in (common/jwt.php on the server).
class JwtGenerator {
    public function generateToken($row) { return 'jwt-for-' . ($row['usr_id'] ?? ''); }
}
