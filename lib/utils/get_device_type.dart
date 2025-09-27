import 'dart:io';

String getDeviceType() {
  if (Platform.isAndroid) {
    return 'ANDROID';
  } else if (Platform.isIOS) {
    return 'IOS';
  } else {
    return '';
  }
}
