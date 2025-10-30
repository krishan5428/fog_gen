class UpdateFireNoResponse {
  final String message;

  UpdateFireNoResponse({required this.message});

  factory UpdateFireNoResponse.fromJson(Map<String, dynamic> json) {
    return UpdateFireNoResponse(message: json['message'] ?? 'Unknown error');
  }
}
