import 'dart:convert';

import 'package:alpaca_run_of_show/app.dart';
import 'package:alpaca_run_of_show/brand.dart';
import 'package:alpaca_run_of_show/controller.dart';
import 'package:alpaca_run_of_show/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('run, stage, edit, and about use the product name', (
    tester,
  ) async {
    final packets = <Map<String, Object?>>[];
    final controller = ShowController(
      store: MemoryStore(),
      sender: (bytes) async {
        packets.add(jsonDecode(utf8.decode(bytes)) as Map<String, Object?>);
      },
      now: () => DateTime(2026, 10, 4, 9),
    );
    await controller.load();
    addTearDown(controller.dispose);

    Future<void> show(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(RunOfShowApp(controller: controller));
      await tester.pump();
      expect(find.text(productName), findsWidgets);
      expect(find.textContaining('Alpaca Run'), findsNothing);
      expect(tester.takeException(), isNull);
    }

    await show(const Size(1280, 800));
    expect(find.text('Walk-in'), findsWidgets);
    expect(find.text('READY'), findsOneWidget);
    await tester.ensureVisible(find.text('GO'));
    await tester.tap(find.text('GO'));
    await tester.pump();
    expect(find.text('REMAINING'), findsOneWidget);
    final fire = packets.where((packet) => packet['type'] == 'cue.fire').single;
    expect(fire['name'], 'Walk-in');
    final source = fire['source'] as Map<String, Object?>;
    expect(source['app'], linkApp);

    await show(const Size(800, 600));
    await show(const Size(390, 844));

    await tester.tap(find.text('About'));
    await tester.pump();
    expect(find.byKey(const Key('about-title')), findsOneWidget);
    expect(find.byKey(const Key('product-icon')), findsOneWidget);
    expect(find.text(productName), findsWidgets);

    await tester.tap(find.text('Link'));
    await tester.pump();
    expect(find.textContaining('239.255.42.77:44771'), findsOneWidget);
    expect(find.textContaining('Alpaca Link'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
