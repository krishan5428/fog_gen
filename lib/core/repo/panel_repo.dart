import '../responses/add_panel_response.dart';
import '../responses/delete_panel_response.dart';
import '../responses/panel_response.dart';
import '../responses/update_panel_response.dart';

abstract class PanelRepo {
  Future<AddPanelResponse> addPanel(
    String userId,
    String panelType,
    String panelName,
    String site,
    String panelSimNumber,
    String adminCode,
    String adminMobileNumber,
    String mobileNumberSubId,
    String mobileNumber2,
    String mobileNumber3,
    String mobileNumber4,
    String mobileNumber5,
    String mobileNumber6,
    String mobileNumber7,
    String mobileNumber8,
    String mobileNumber9,
    String mobileNumber10,
    String address,
    String cOn,
    String ip_address,
    String port_no,
    String static_ip_address,
    String static_port_no,
    String password,
    bool is_ip_panel,
    bool is_ip_gsm_panel,
  );

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

  Future<UpdatePanelResponse> updateSolitareMobileNumber(
    String userId,
    int panelId,
    String index,
    String number,
  );
}
