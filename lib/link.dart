import 'dart:convert';
import 'dart:io';

import 'brand.dart';
import 'format.dart';
import 'models.dart';

typedef PacketSender = Future<void> Function(List<int> bytes);

class Fired {
  const Fired(this.cue, this.index);

  final Cue cue;
  final int index;
}

class LinkLogEntry {
  const LinkLogEntry({
    required this.at,
    required this.type,
    required this.name,
    required this.ok,
    this.error,
  });

  final DateTime at;
  final String type;
  final String name;
  final bool ok;
  final String? error;
}

String newInstanceId(DateTime now) =>
    'ros-${now.microsecondsSinceEpoch.toRadixString(36)}';

Map<String, Object?> buildEnvelope({
  required String type,
  required String name,
  required Map<String, Object?> payload,
  required DateTime now,
  required String id,
  required String show,
  required String instanceId,
}) {
  return {
    'version': 1,
    'source': {'app': linkApp, 'instance': instanceId, 'name': productName},
    'type': type,
    'name': name,
    'payload': payload,
    'timestamp': isoStamp(now),
    'id': id,
    'show': show,
  };
}

Map<String, Object?> cueFireEnvelope({
  required Show show,
  required Cue cue,
  required int index,
  required DateTime now,
  required String instanceId,
  required String id,
  bool test = false,
}) {
  final payload = <String, Object?>{
    'cueId': cue.id,
    'cueIndex': index,
    'cueCount': show.cues.length,
    'notes': clipText(cue.notes, 240),
    'timing': cue.timing.name,
  };
  if (cue.timing == CueTiming.duration) {
    payload['durationSec'] = cue.durationSec;
  } else {
    payload['clockTime'] = formatMinute(cue.clockMinute);
    payload['clockMinute'] = cue.clockMinute;
  }
  if (test) payload['test'] = true;
  return buildEnvelope(
    type: 'cue.fire',
    name: cue.title,
    payload: payload,
    now: now,
    id: id,
    show: show.displayTitle,
    instanceId: instanceId,
  );
}

Map<String, Object?> clockEnvelope({
  required Show show,
  required CueView view,
  required DateTime now,
  required String instanceId,
  required String id,
}) {
  return buildEnvelope(
    type: 'clock.time',
    name: view.cue?.title ?? show.displayTitle,
    now: now,
    id: id,
    show: show.displayTitle,
    instanceId: instanceId,
    payload: {
      'cueId': view.cue?.id,
      'cueIndex': view.heroIndex,
      'cueCount': show.cues.length,
      'remainingSec': view.remainingSec,
      'elapsedSec': view.elapsedSec,
      'overtime': view.phase == Phase.overtime,
      'held': view.phase == Phase.held,
      'running':
          view.phase == Phase.running ||
          view.phase == Phase.held ||
          view.phase == Phase.overtime,
      'phase': view.phase.name,
      'showElapsedSec': view.showElapsedSec,
      'plannedSec': view.plannedSec,
    },
  );
}

String describeSendError(Object error) {
  final text = error.toString();
  if (text.contains('Network is unreachable')) {
    return 'Multicast did not leave this machine. The LAN must pass 239.255.42.77.';
  }
  return text
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Exception: ', '');
}

void configureLinkSocket(RawDatagramSocket socket) {
  socket.multicastHops = linkTtl;
  socket.multicastLoopback = false;
}

class UdpSender {
  RawDatagramSocket? _socket;

  Future<void> send(List<int> bytes) async {
    try {
      final socket = _socket ??= await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      configureLinkSocket(socket);
      final sent = socket.send(bytes, InternetAddress(linkGroup), linkPort);
      if (sent != bytes.length) {
        throw StateError('UDP accepted $sent of ${bytes.length} bytes');
      }
    } on Object {
      close();
      rethrow;
    }
  }

  void close() {
    _socket?.close();
    _socket = null;
  }
}

List<int> encodeEnvelope(Map<String, Object?> envelope) =>
    utf8.encode(jsonEncode(envelope));
