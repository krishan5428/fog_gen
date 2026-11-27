/// FogShield's backend: its own folder `app_services/fogshield/`
/// (same layout as FireNex's `app_services/firenex/`).
/// Server code and tables: docs/PLAN_FOGSHIELD_BACKEND.md.
class WebUrlConstants {
  static const String baseUrl =
      'https://securicoconnect.com/cms/apps/Securico/app_services/fogshield/';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  // Panels (tbl_panel_fogshield)
  static const String addPanel = 'add_panel.php';
  static const String getAllPanels = 'get_panels.php';
  static const String updatePanel = 'update_panel.php';
  static const String deletePanel = 'delete_panel.php';
  static const String fetchLogs = 'fetch_logs.php';

  // Users (tbl_fogshield_users, tbl_fogshield_device_tokens)
  static const String loginUser = 'login.php';
  static const String signUpUser = 'signup.php';
  static const String forgetPass = 'forgot_password.php';
  static const String updateUser = 'update_user.php';
  static const String delUser = 'del_user.php';

  // Vendor (stored in the user's row)
  static const String addVendor = 'add_vendor.php';
  static const String getVendor = 'get_vendors.php';
  static const String delVendor = 'del_vendor.php';

  // G4 (4GCOM) MQTT client certificates. Absolute URL — served from a
  // different app_services path than [baseUrl], so Dio uses it as-is.
  static const String mqttCertificatesUrl =
      'https://securicoconnect.com/cms/apps/Securico/app_services/mqtt_certificates/get_mqtt_certificates.php';

  // Error Messages
  static const String networkError = 'Please check your internet connection.';
  static const String unknownError = 'Something went wrong. Please try again.';
}
