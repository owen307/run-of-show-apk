import 'dart:convert';
import 'dart:io';

import 'package:alpaca_run_of_show/brand.dart';
import 'package:alpaca_run_of_show/controller.dart';
import 'package:alpaca_run_of_show/link.dart';
import 'package:alpaca_run_of_show/sample_shows.dart';
import 'package:alpaca_run_of_show/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the locked destination is multicast ttl 1', () {
    expect(linkGroup, '239.255.42.77');
    expect(linkPort, 44771);
    expect(linkTtl, 1);
    expect(linkApp, 'run-of-show');
    expect(
      clockInterval.inMilliseconds,
      greaterThanOrEqualTo(1000 ~/ clockMaxHz),
    );
  });

  test('cue.fire uses the locked envelope', () {
    final now = DateTime.utc(2026, 10, 4, 14);
    final show = sundayGathering(now: now);
    final envelope = cueFireEnvelope(
      show: show,
      cue: show.cues.first,
      index: 0,
      now: now,
      instanceId: 'ros-test',
      id: 'ros-test-1',
    );
    expect(envelope.keys.toList(), [
      'version',
      'source',
      'type',
      'name',
      'payload',
      'timestamp',
      'id',
      'show',
    ]);
    expect(envelope['version'], 1);
    expect(envelope['type'], 'cue.fire');
    expect(envelope['name'], 'Walk-in');
    expect(envelope['show'], 'Sunday Gathering');
    expect(envelope['id'], 'ros-test-1');
    final source = envelope['source'] as Map<String, Object?>;
    expect(source['app'], 'run-of-show');
    expect(source['instance'], 'ros-test');
    expect(source['name'], productName);
    expect(envelope.containsKey('v'), isFalse);
    expect(envelope.containsKey('from'), isFalse);
  });

  test('go emits cue.fire and clock.time stays at or under 4 Hz', () async {
    final packets = <Map<String, Object?>>[];
    final now = DateTime(2026, 10, 4, 9);
    final controller = ShowController(
      store: MemoryStore(),
      sender: (bytes) async {
        packets.add(jsonDecode(utf8.decode(bytes)) as Map<String, Object?>);
      },
      now: () => now,
    );
    await controller.load();
    controller.go();
    await _flush();
    expect(packets.single['type'], 'cue.fire');
    expect(packets.single['name'], 'Walk-in');

    await controller.emitClock(now);
    await _flush();
    expect(packets[1]['type'], 'clock.time');
    await controller.emitClock(now);
    await _flush();
    expect(packets, hasLength(2));

    controller.setLink(controller.link.copyWith(enabled: false));
    final before = packets.length;
    controller.go();
    await _flush();
    expect(packets, hasLength(before));
    controller.dispose();
  });

  test('clock.time can be turned off', () async {
    final packets = <String>[];
    final controller = ShowController(
      store: MemoryStore(),
      sender: (bytes) async {
        final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
        packets.add(decoded['type'] as String);
      },
      now: () => DateTime(2026, 10, 4, 9),
    );
    await controller.load();
    controller.setLink(controller.link.copyWith(emitClock: false));
    await controller.emitClock(DateTime(2026, 10, 4, 9));
    await _flush();
    expect(packets, isEmpty);
    controller.dispose();
  });

  test('the socket ttl is 1', () async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    addTearDown(socket.close);
    configureLinkSocket(socket);
    expect(socket.multicastHops, linkTtl);
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
