import 'package:flutter_test/flutter_test.dart';
import 'package:fog_gen_new/core/api/web_url_constants.dart';

void main() {
  test('every API call goes to the FogShield backend folder', () {
    expect(
      WebUrlConstants.baseUrl,
      'https://securicoconnect.com/cms/apps/Securico/app_services/fogshield/',
    );
    expect(
      {
        WebUrlConstants.addPanel,
        WebUrlConstants.getAllPanels,
        WebUrlConstants.updatePanel,
        WebUrlConstants.deletePanel,
        WebUrlConstants.fetchLogs,
        WebUrlConstants.loginUser,
        WebUrlConstants.signUpUser,
        WebUrlConstants.forgetPass,
        WebUrlConstants.updateUser,
        WebUrlConstants.delUser,
        WebUrlConstants.addVendor,
        WebUrlConstants.getVendor,
        WebUrlConstants.delVendor,
      },
      {
        'add_panel.php',
        'get_panels.php',
        'update_panel.php',
        'delete_panel.php',
        'fetch_logs.php',
        'login.php',
        'signup.php',
        'forgot_password.php',
        'update_user.php',
        'del_user.php',
        'add_vendor.php',
        'get_vendors.php',
        'del_vendor.php',
      },
    );
  });

  test('MQTT certificates keep their own absolute path', () {
    expect(
      WebUrlConstants.mqttCertificatesUrl,
      endsWith('/app_services/mqtt_certificates/get_mqtt_certificates.php'),
    );
  });
}
