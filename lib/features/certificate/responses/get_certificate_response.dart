import 'dart:convert';

class GetCertificateResponse {
  final bool status;
  final String rootCa;
  final String clientCert;
  final String privateKey;
  final int version;
  final String msg;

  GetCertificateResponse({
    required this.status,
    this.rootCa = '',
    this.clientCert = '',
    this.privateKey = '',
    this.version = 1,
    this.msg = '',
  });

  factory GetCertificateResponse.fromJson(Map<String, dynamic> json) {
    return GetCertificateResponse(
      status: json['status'] ?? false,
      rootCa: _decodeBase64(json['root_ca']),
      clientCert: _decodeBase64(json['client_cert']),
      privateKey: _decodeBase64(json['private_key']),
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      msg: json['msg'] ?? '',
    );
  }

  static String _decodeBase64(dynamic value) {
    if (value == null) return '';
    try {
      return utf8.decode(base64.decode(value.toString()));
    } catch (e) {
      return '';
    }
  }
}
