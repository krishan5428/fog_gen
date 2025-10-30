class AddFireNo {
  final String msg;

  AddFireNo({required this.msg});

  factory AddFireNo.fromJson(Map<String, dynamic> json) {
    return AddFireNo(msg: json['message'] ?? 'Unknown error');
  }
}
