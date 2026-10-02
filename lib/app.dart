import 'package:flutter/material.dart';

import 'brand.dart';
import 'controller.dart';
import 'theme.dart';
import 'ui/shell.dart';
import 'ui/widgets.dart';

class RunOfShowApp extends StatelessWidget {
  const RunOfShowApp({super.key, required this.controller});

  final ShowController controller;

  @override
  Widget build(BuildContext context) {
    return ShowScope(
      controller: controller,
      child: MaterialApp(
        title: productName,
        debugShowCheckedModeBanner: false,
        theme: buildBoothTheme(),
        home: const BoothShell(),
      ),
    );
  }
}
