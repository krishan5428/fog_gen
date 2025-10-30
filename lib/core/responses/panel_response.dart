import '../data/pojo/panel_data.dart';

class PanelResponse {
  final bool status;
  final List<PanelData> panelsData;

  PanelResponse({required this.status, required this.panelsData});

  factory PanelResponse.fromJson(Map<String, dynamic> json) {
    return PanelResponse(
      status: json['status'] == true,
      panelsData:
          json['panels'] != null
              ? List<PanelData>.from(
                json['panels'].map((e) => PanelData.fromJson(e)),
              )
              : [],
    );
  }
}
