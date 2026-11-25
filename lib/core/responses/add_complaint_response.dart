class AddComplaintResponse {
  final bool status;
  final String message;

  AddComplaintResponse({required this.status, required this.message});

  factory AddComplaintResponse.fromJson(Map<String, dynamic> json) {
    return AddComplaintResponse(
      status: json['status'] == true,
      message: json['msg']?.toString() ?? '',
    );
  }
}
