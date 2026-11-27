<?php
// fogshield/forgot_password.php — from firenex/forgot_password.php: emails
// the stored password to the user's registered email (same mailer account
// as FireNex). Only the product name in the email is changed to FogShield.
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);

include("../../common/db.php");
require '../../phpmailer/PHPMailerAutoload.php';
require_once __DIR__ . '/config_loader.php';
header('Content-Type: application/json');

function fs_json($status, $msg) {
    echo json_encode(["status" => $status, "msg" => $msg]);
    exit;
}

function fs_send_password_email($to, $subject, $message) {
    // Mailer login lives in config.php (smtp_user / smtp_pass), not in code.
    $smtpUser = fogshield_config('smtp_user');
    $smtpPass = fogshield_config('smtp_pass');
    if ($smtpUser === '' || $smtpPass === '') {
        error_log("Mailer Error: smtp_user/smtp_pass missing in fogshield/config.php");
        return false;
    }
    $mail = new PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host       = 'smtp.gmail.com';
        $mail->SMTPAuth   = true;
        $mail->Username   = $smtpUser;
        $mail->Password   = $smtpPass;
        $mail->SMTPSecure = 'tls';
        $mail->Port       = 587;

        $mail->setFrom($smtpUser, 'Securico FogShield');
        $mail->addAddress($to, 'Securico FogShield User');
        $mail->addBCC('customer.support3@securicoelectronics.in');
        $mail->isHTML(false);
        $mail->Subject = $subject;
        $mail->Body    = $message;

        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("Mailer Error: " . $mail->ErrorInfo);
        return false;
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    fs_json(false, "Invalid request method.");
}

$mobile = trim($_POST['mobile'] ?? '');
if (empty($mobile)) {
    fs_json(false, "Mobile number is required.");
}

$stmt = sqlsrv_query($con, "SELECT email, password FROM tbl_fogshield_users WHERE mobile = ?", [$mobile]);
if ($stmt === false) {
    error_log("SQL Error: " . print_r(sqlsrv_errors(), true));
    fs_json(false, "Server error.");
}

if ($row = sqlsrv_fetch_array($stmt, SQLSRV_FETCH_ASSOC)) {
    $email = trim((string)$row['email']);
    $pass  = trim((string)$row['password']);
    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fs_json(false, "Invalid or missing registered email.");
    }
    $subject = "Securico FogShield Password Request";
    $message = "Your password for the Securico FogShield app is:\n\n" . $pass;
    if (fs_send_password_email($email, $subject, $message)) {
        fs_json(true, "Password has been sent to your email.");
    }
    fs_json(false, "Failed to send email. Please try again.");
}
fs_json(false, "Invalid Mobile - User not found.");
