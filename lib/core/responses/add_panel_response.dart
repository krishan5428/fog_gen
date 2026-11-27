import 'dart:convert';

class AddPanelResponse {
  final bool status;
  final String msg;
  // Returned by the server when available. G4 (4GCOM) provisioning writes
  // [panelAccNo] to the device and uses [pnlId] to roll back on failure.
  final String? panelAccNo;
  final int? pnlId;

  AddPanelResponse({
    required this.status,
    required this.msg,
    this.panelAccNo,
    this.pnlId,
  });

  factory AddPanelResponse.fromJson(dynamic jsonResponse) {
    Map<String, dynamic> json;
    if (jsonResponse is String) {
      try {
        json = jsonDecode(jsonResponse);
      } catch (_) {
        return AddPanelResponse(
          status: false,
          msg: "Invalid response from server: $jsonResponse",
        );
      }
    } else if (jsonResponse is Map<String, dynamic>) {
      json = jsonResponse;
    } else {
      return AddPanelResponse(status: false, msg: "Invalid response format");
    }

    final status = json['status'];
    return AddPanelResponse(
      status:
          status == true || status == 1 || status == '1' || status == 'true',
      msg: (json['message'] ?? json['msg'] ?? '').toString(),
      panelAccNo:
          json['panel_acc_no']?.toString() ??
          json['pnl_acc_no']?.toString() ??
          json['panel_id']?.toString(),
      pnlId: json['pnl_id'] is int
          ? json['pnl_id']
          : int.tryParse(json['pnl_id']?.toString() ?? ''),
    );
  }
}
