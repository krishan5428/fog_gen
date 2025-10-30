class WebUrlConstants {
  static const String baseUrl = 'https://securicoconnect.com/cms/apps/Securico/app_services/';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  static const String addPanel = 'add_panel_firenex.php';
  static const String getAllPanels = 'get_panel_firenex.php';
  static const String deletePanel = 'delete_panel_firenex.php';
  static const String updatePanel = 'update_panel_firenex.php';

  static const String loginUser = 'login.php';
  static const String delUser = 'del_user.php';
  static const String signUpUser = 'register_user.php';
  static const String forgetPass = 'forgot_pass.php';
  static const String updateUser = 'update_user.php';

  static const String delVendor = 'del_vendor.php';
  static const String getVendor = 'get_vendors.php';
  static const String addVendor = 'add_vendor.php';

  static const String addIntruNo = 'add_intru_nos.php';
  static const String getIntruNo = 'get_intru_nos.php';
  static const String updateIntruNo = 'update_intru_nos.php';
  static const String deleteIntruNo = 'del_intru_nos.php';

  static const String addFireNo = 'add_fire_no.php';
  static const String getFireNo = 'get_fire_nos.php';
  static const String updateFireNo = 'update_fire_nos.php';
  static const String deleteFireNo = 'del_fire_nos.php';

  // Error Messages
  static const String networkError = 'Please check your internet connection.';
  static const String unknownError = 'Something went wrong. Please try again.';
}
