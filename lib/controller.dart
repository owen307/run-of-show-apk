import 'dart:async';

import 'package:flutter/foundation.dart';

import 'brand.dart';
import 'engine.dart';
import 'link.dart';
import 'models.dart';
import 'sample_shows.dart';
import 'store.dart';

class ShowController extends ChangeNotifier {
  ShowController({
    required this._store,
    PacketSender? sender,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    if (sender == null) {
      final udp = UdpSender();
      _udp = udp;
      _sender = udp.send;
    } else {
      _udp = null;
      _sender = sender;
    }
  }

  final ShowStore _store;
  final DateTime Function() _now;
  late final PacketSender _sender;
  late final UdpSender? _udp;

  Show _show = const Show(title: '', subtitle: '', cues: []);
  LinkSettings _link = LinkSettings.hub;
  RundownState _run = const RundownState();
  var _loaded = false;
  var _seq = 0;
  var _sent = 0;
  var _paintedSecond = -1;
  DateTime? _lastClockEmit;
  String? _linkError;
  final List<LinkLogEntry> _log = [];
  Future<void> _saveChain = Future<void>.value();

  bool get loaded => _loaded;
  Show get show => _show;
  LinkSettings get link => _link;
  RundownState get rundown => _run;
  String? get linkError => _linkError;
  int get sentCount => _sent;
  List<LinkLogEntry> get log => List.unmodifiable(_log);

  DateTime clock() => _now();

  CueView project([DateTime? now]) => projectShow(_show, _run, now ?? _now());

  Future<void> load() async {
    var seeded = false;
    try {
      final saved = await _store.load();
      if (saved == null) {
        _show = sundayGathering(now: _now());
        _link = LinkSettings(instanceId: newInstanceId(_now()));
        _run = const RundownState();
        seeded = true;
      } else {
        _show = saved.show;
        _link = _withInstance(saved.link);
        _run = saved.rundown.clampedTo(saved.show);
        if (_link.instanceId != saved.link.instanceId) seeded = true;
      }
    } on Object {
      _show = sundayGathering(now: _now());
      _link = LinkSettings(instanceId: newInstanceId(_now()));
      _run = const RundownState();
      seeded = true;
    }
    _loaded = true;
    notifyListeners();
    if (seeded) _save();
  }

  void onFrame() {
    if (!_loaded) return;
    final now = _now();
    final second = now.millisecondsSinceEpoch ~/ 1000;
    if (second == _paintedSecond) return;
    _paintedSecond = second;
    notifyListeners();
    unawaited(emitClock(now));
  }

  void go() => _apply(goShow(_show, _run, _now()));

  void skip() => _apply(skipShow(_show, _run, _now()));

  void back() => _apply(backShow(_show, _run, _now()));

  void toggleHold() => _apply(holdShow(_show, _run, _now()));

  void take(int index) => _apply(takeShow(_show, _run, index, _now()));

  void reset() {
    _run = const RundownState();
    _save();
    notifyListeners();
  }

  void rename(String title, String subtitle) {
    if (title == _show.title && subtitle == _show.subtitle) return;
    _show = _show.copyWith(title: title, subtitle: subtitle, clearSample: true);
    _save();
    notifyListeners();
  }

  void setCues(List<Cue> cues, {bool clearSample = true}) {
    final previous = _show;
    final next = _show.copyWith(cues: cues, clearSample: clearSample);
    _show = next;
    _run = followRun(_run, previous, next);
    _save();
    notifyListeners();
  }

  void addCue(Cue cue) => setCues([..._show.cues, cue]);

  void updateCue(Cue cue) {
    setCues([for (final item in _show.cues) item.id == cue.id ? cue : item]);
  }

  void deleteCue(String id) {
    setCues(_show.cues.where((cue) => cue.id != id).toList());
  }

  void moveCue(int from, int to) {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= _show.cues.length ||
        to >= _show.cues.length) {
      return;
    }
    final cues = [..._show.cues];
    final item = cues.removeAt(from);
    cues.insert(to, item);
    setCues(cues);
  }

  void loadSample(Show sample) {
    _show = sample;
    _run = const RundownState();
    _save();
    notifyListeners();
  }

  void setLink(LinkSettings settings) {
    _link = settings;
    _save();
    notifyListeners();
  }

  Future<void> testFire() {
    if (!_link.enabled) return Future<void>.value();
    final now = _now();
    final cue = Cue(
      id: 'link-test',
      title: 'Link test',
      notes: 'Operator test from Run of Show',
      timing: CueTiming.duration,
      durationSec: 0,
      clockMinute: 0,
    );
    return _emit(
      cueFireEnvelope(
        show: _show,
        cue: cue,
        index: 0,
        now: now,
        instanceId: _link.instanceId,
        id: _messageId(),
        test: true,
      ),
    );
  }

  Future<void> emitClock(DateTime now) async {
    if (!_link.enabled || !_link.emitClock) return;
    final last = _lastClockEmit;
    if (last != null && now.difference(last) < clockInterval) return;
    _lastClockEmit = now;
    await _emit(
      clockEnvelope(
        show: _show,
        view: projectShow(_show, _run, now),
        now: now,
        instanceId: _link.instanceId,
        id: _messageId(),
      ),
    );
  }

  void _apply(Step step) {
    _run = step.state;
    final fired = step.fired;
    if (fired != null) unawaited(_sendFire(fired));
    _save();
    notifyListeners();
  }

  Future<void> _sendFire(Fired fired) {
    if (!_link.enabled) return Future<void>.value();
    return _emit(
      cueFireEnvelope(
        show: _show,
        cue: fired.cue,
        index: fired.index,
        now: _now(),
        instanceId: _link.instanceId,
        id: _messageId(),
      ),
    );
  }

  LinkSettings _withInstance(LinkSettings settings) {
    if (settings.instanceId.trim().isNotEmpty) return settings;
    return settings.copyWith(instanceId: newInstanceId(_now()));
  }

  String _messageId() => '${_link.instanceId}-${_nextSeq()}';

  Future<void> _emit(Map<String, Object?> envelope) async {
    final type = envelope['type'] as String? ?? '';
    final name = envelope['name'] as String? ?? '';
    try {
      await _sender(encodeEnvelope(envelope));
      _sent += 1;
      _linkError = null;
      _pushLog(type: type, name: name, ok: true);
    } on Object catch (error) {
      _linkError = describeSendError(error);
      _pushLog(type: type, name: name, ok: false, error: _linkError);
    }
    notifyListeners();
  }

  void _pushLog({
    required String type,
    required String name,
    required bool ok,
    String? error,
  }) {
    _log.insert(
      0,
      LinkLogEntry(at: _now(), type: type, name: name, ok: ok, error: error),
    );
    if (_log.length > 20) _log.removeRange(20, _log.length);
  }

  int _nextSeq() => ++_seq;

  void _save() {
    final snapshot = Persisted(show: _show, link: _link, rundown: _run);
    _saveChain = _saveChain
        .then((_) => _store.save(snapshot))
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _udp?.close();
    super.dispose();
  }
}
