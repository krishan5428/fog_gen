<?php
// Runs one fogshield endpoint in this process. Called by run_tests.php.
// argv: endpoint, json POST body
$_SERVER['REQUEST_METHOD'] = getenv('FS_METHOD') ?: 'POST';
$_POST = json_decode($argv[2] ?? '{}', true) ?: [];

// FS_RAW_INPUT stands in for the request body (php://input), which the CLI
// cannot fake. Only php://input is replaced; other php:// streams still work.
if (getenv('FS_RAW_INPUT') !== false) {
    class FsRawInput {
        private $data; private $pos = 0; private $real; public $context;
        public function stream_open($path, $mode, $options, &$opened) {
            if (strtolower($path) === 'php://input') { $this->data = getenv('FS_RAW_INPUT'); return true; }
            stream_wrapper_restore('php');
            $this->real = fopen($path, $mode);
            stream_wrapper_unregister('php');
            stream_wrapper_register('php', self::class);
            return $this->real !== false;
        }
        public function stream_read($n) {
            if ($this->real) return fread($this->real, $n);
            $r = substr($this->data, $this->pos, $n); $this->pos += strlen($r); return $r;
        }
        public function stream_write($d) { return $this->real ? fwrite($this->real, $d) : 0; }
        public function stream_eof() { return $this->real ? feof($this->real) : $this->pos >= strlen($this->data); }
        public function stream_stat() { return []; }
    }
    stream_wrapper_unregister('php');
    stream_wrapper_register('php', 'FsRawInput');
}
chdir(__DIR__ . '/fx/run/here'); // so include("../../common/…") finds the fakes
require __DIR__ . '/../fogshield/' . $argv[1];
