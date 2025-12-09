import '../responses/add_panel_response.dart';
import '../responses/delete_panel_response.dart';
import '../responses/panel_response.dart';
import '../responses/update_panel_response.dart';

abstract class PanelRepo {
  Future<AddPanelResponse> addPanel({
    required String userId,
    required String panelType,
    required String panelName,
    required String site,
    required String panelSimNumber,
    required String adminCode,
    required String adminMobileNumber,
    required String mobileNumberSubId,
    required String mobileNumber1,
    required String mobileNumber2,
    required String mobileNumber3,
    required String mobileNumber4,
    required String mobileNumber5,
    required String mobileNumber6,
    required String mobileNumber7,
    required String mobileNumber8,
    required String mobileNumber9,
    required String mobileNumber10,
    required String address,
    required String cOn,
    required String ip_address,
    required String port_no,
    required String static_ip_address,
    required String static_port_no,
    required String password,
    required bool is_ip_panel,
    required bool is_ip_gsm_panel,
  });

  Future<PanelResponse> getPanels(String userId);

  Future<DeletePanelResponse> deletePanel(String userId, int panelId);

  Future<UpdatePanelResponse> updateAdminMobileNumber(
    String userId,
    int panelId,
    String adminMobileNumber,
  );

  Future<UpdatePanelResponse> updatePanelSimNumber(
    String userId,
    int panelId,
    String panelSimNumber,
  );

  Future<UpdatePanelResponse> updateAdminCode(
    String userId,
    int panelId,
    int adminCode,
  );

  Future<UpdatePanelResponse> updateAddress(
    String userId,
    int panelId,
    String address,
  );

  Future<UpdatePanelResponse> updateSiteName(
    String userId,
    int panelId,
    String siteName,
  );

  Future<UpdatePanelResponse> updatePanelData(
      String userId,
      int panelId,
      String key,
      String value
      );

  Future<UpdatePanelResponse> updatePanelDataInList(
      String userId,
      int panelId,
      List<String> keys,
      List<dynamic> values,
      );


  Future<UpdatePanelResponse> updateSolitareMobileNumber(
    String userId,
    int panelId,
    String index,
    String number,
  );
}
