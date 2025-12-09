import '../data/pojo/panel_data.dart';

class PanelResponse {
  final bool status;
  final List<PanelData> panelsData;
  final String msg;

  PanelResponse({
    required this.status,
    required this.panelsData,
    required this.msg,
  });

  factory PanelResponse.fromJson(Map<String, dynamic> json) {
    return PanelResponse(
      status: json['status'] == true,
      panelsData:
          json['panels'] != null
              ? List<PanelData>.from(
                json['panels'].map((e) => PanelData.fromJson(e)),
              )
              : [],
      msg: json['msg'],
    );
  }
}
