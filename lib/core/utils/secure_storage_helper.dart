import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyRootCa = 'mqtt_cert_root_ca';
  static const _keyClientCert = 'mqtt_cert_client_cert';
  static const _keyPrivateKey = 'mqtt_cert_private_key';
  static const _keyVersion = 'mqtt_cert_version';

  static Future<void> saveCertificates({
    required String rootCa,
    required String clientCert,
    required String privateKey,
    required int version,
  }) async {
    await _storage.write(key: _keyRootCa, value: rootCa);
    await _storage.write(key: _keyClientCert, value: clientCert);
    await _storage.write(key: _keyPrivateKey, value: privateKey);
    await _storage.write(key: _keyVersion, value: version.toString());
  }

  static Future<String?> getRootCa() => _storage.read(key: _keyRootCa);

  static Future<String?> getClientCert() => _storage.read(key: _keyClientCert);

  static Future<String?> getPrivateKey() => _storage.read(key: _keyPrivateKey);

  static Future<int?> getVersion() async {
    final value = await _storage.read(key: _keyVersion);
    return value != null ? int.tryParse(value) : null;
  }

  static Future<void> clearCertificates() async {
    await _storage.delete(key: _keyRootCa);
    await _storage.delete(key: _keyClientCert);
    await _storage.delete(key: _keyPrivateKey);
    await _storage.delete(key: _keyVersion);
  }
}
