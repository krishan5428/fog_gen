<?php
// PHPMailer stand-in: records every mail in FS_MAIL_LOG instead of sending.
class PHPMailer {
    public $Host, $SMTPAuth, $Username, $Password, $SMTPSecure, $Port, $Subject, $Body, $ErrorInfo = '';
    private $to = [];
    private $from = '';
    public function __construct($e = false) {}
    public function isSMTP() {}
    public function isHTML($b) {}
    public function setFrom($a, $n = '') { $this->from = "$n <$a>"; }
    public function addAddress($a, $n = '') { $this->to[] = $a; }
    public function addBCC($a) {}
    public function send() {
        if (getenv('FS_MAIL_FAIL')) throw new Exception('smtp down');
        file_put_contents(getenv('FS_MAIL_LOG'), json_encode(['username' => $this->Username, 'password' => $this->Password, 'from' => $this->from,'to' => $this->to, 'subject' => $this->Subject, 'body' => $this->Body]) . "\n", FILE_APPEND);
        return true;
    }
}
