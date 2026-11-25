import '../data/pojo/panel_data.dart';

class UpdatePanelResponse {
  final bool status;
  final String msg;
  final PanelData? panelData; // make nullable for safety

  UpdatePanelResponse({
    required this.status,
    required this.msg,
    this.panelData,
  });

  factory UpdatePanelResponse.fromJson(Map<String, dynamic> json) {
    return UpdatePanelResponse(
      status: json['status'] == true,
      msg: json['msg'] ?? '',
      panelData: json['data'] is Map<String, dynamic>
          ? PanelData.fromJson(json['data'])
          : null,
    );
  }
}
