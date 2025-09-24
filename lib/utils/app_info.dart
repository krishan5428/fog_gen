import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static final AppInfo _instance = AppInfo._internal();
  late PackageInfo _packageInfo;
  late final String _cachedVersion;

  AppInfo._internal();

  static AppInfo get instance => _instance;

  String get version => _cachedVersion;
  String get buildNumber => _packageInfo.buildNumber;
  String get appName => _packageInfo.appName;
  String get packageName => _packageInfo.packageName;

  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _cachedVersion = _packageInfo.version;
  }
}
