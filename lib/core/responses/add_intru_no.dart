class AddIntruNo {
  final bool status;
  final String msg;

  AddIntruNo({required this.status, required this.msg});

  factory AddIntruNo.fromJson(Map<String, dynamic> json) {
    return AddIntruNo(status: json['status'] ?? false, msg: json['msg'] ?? '');
  }
}
