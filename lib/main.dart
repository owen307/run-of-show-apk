import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'controller.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await WakelockPlus.enable();
  } on Object {
    // Desktop builds without a screensaver service still run the clock.
  }
  final controller = ShowController(store: PrefsStore());
  await controller.load();
  runApp(RunOfShowApp(controller: controller));
}
