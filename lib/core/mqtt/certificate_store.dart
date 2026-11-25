import 'dart:async';

import 'package:fog_gen_new/core/utils/secure_storage_helper.dart';
import 'package:fog_gen_new/features/certificate/repository/certificate_repo.dart';
import 'package:fog_gen_new/features/certificate/repository/certificate_repo_impl.dart';
import 'package:fog_gen_new/core/logging/app_logger.dart';

/// Fetches MQTT client certificates from the API, caches them in secure
/// storage, and keeps them in memory for the app session. Certificates are
/// re-checked (and rotated if the server reports a new version) in the
/// background so cert rotation doesn't require an app update.
class CertificateStore {
  CertificateStore._internal();

  static final CertificateStore instance = CertificateStore._internal();

  final CertificateRepo _repo = CertificateRepoImpl();

  String? _rootCa;
  String? _clientCert;
  String? _privateKey;
  int? _version;

  String get rootCa => _rootCa ?? '';

  String get clientCert => _clientCert ?? '';

  String get privateKey => _privateKey ?? '';

  Future<void> initialize() async {
    await ensureCertificatesAvailable();
    unawaited(_checkForUpdates());
  }

  Future<bool> ensureCertificatesAvailable() async {
    if (_rootCa != null && _clientCert != null && _privateKey != null) {
      return true;
    }

    if (await _loadFromSecureStorage()) {
      return true;
    }

    return _fetchAndCache();
  }

  Future<bool> _loadFromSecureStorage() async {
    final rootCa = await SecureStorageHelper.getRootCa();
    final clientCert = await SecureStorageHelper.getClientCert();
    final privateKey = await SecureStorageHelper.getPrivateKey();

    if (rootCa == null || clientCert == null || privateKey == null) {
      return false;
    }

    _rootCa = rootCa;
    _clientCert = clientCert;
    _privateKey = privateKey;
    _version = await SecureStorageHelper.getVersion();
    return true;
  }

  Future<bool> _fetchAndCache() async {
    final response = await _repo.fetchCertificates();
    if (!response.status ||
        response.rootCa.isEmpty ||
        response.clientCert.isEmpty ||
        response.privateKey.isEmpty) {
      AppLogger.d('Certificate fetch failed: ${response.msg}');
      return false;
    }

    _rootCa = response.rootCa;
    _clientCert = response.clientCert;
    _privateKey = response.privateKey;
    _version = response.version;

    await SecureStorageHelper.saveCertificates(
      rootCa: response.rootCa,
      clientCert: response.clientCert,
      privateKey: response.privateKey,
      version: response.version,
    );
    return true;
  }

  Future<void> _checkForUpdates() async {
    try {
      final response = await _repo.fetchCertificates();
      if (!response.status) return;

      if (response.version != _version) {
        _rootCa = response.rootCa;
        _clientCert = response.clientCert;
        _privateKey = response.privateKey;
        _version = response.version;

        await SecureStorageHelper.saveCertificates(
          rootCa: response.rootCa,
          clientCert: response.clientCert,
          privateKey: response.privateKey,
          version: response.version,
        );
        AppLogger.d('Certificates updated to version ${response.version}');
      }
    } catch (e) {
      AppLogger.d('Certificate update check failed: $e');
    }
  }
}
