import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class SendSms with WidgetsBindingObserver {
  final String phone;
  final List<String> messages;
  final void Function(void Function()) setState;
  final List<bool> smsStatus;
  final VoidCallback? onComplete;

  int _currentIndex = 0;

  SendSms(this.phone, this.messages, this.setState, this.smsStatus, {this.onComplete});

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _sendNext();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  void _sendNext() async {
    if (_currentIndex >= messages.length) {
      dispose();
      if(onComplete != null) onComplete!();
      return;
    }

    final encoded = Uri.encodeComponent(messages[_currentIndex]);
    final smsUri = Uri.parse(Platform.isIOS ? "sms:$phone&body=$encoded" : "sms:$phone?body=$encoded");

    final launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    if (launched) {
      debugPrint("Opened composer for SMS ${_currentIndex + 1}");
      setState(() {
        smsStatus[_currentIndex] = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _currentIndex++;
      _sendNext();
    }
  }
}
