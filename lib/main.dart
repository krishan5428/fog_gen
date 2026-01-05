import 'package:flutter/material.dart';
import 'package:fog_gen_new/utils/app_info.dart';

import 'app/fogshield_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.instance.init();
  runApp(const FogShieldApp());
}
