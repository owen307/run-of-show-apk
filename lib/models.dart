import 'format.dart';

enum CueTiming { duration, clock }

enum Phase { ready, running, held, overtime, complete }

class CueView {
  const CueView({
    required this.phase,
    required this.activeIndex,
    required this.heroIndex,
    required this.cue,
    required this.next,
    required this.nextIndex,
    required this.after,
    required this.afterIndex,
    required this.remainingSec,
    required this.elapsedSec,
    required this.heroLabel,
    required this.nextDue,
    required this.showElapsedSec,
    required this.plannedSec,
    required this.doneCount,
    required this.cueCount,
  });

  final Phase phase;
  final int? activeIndex;
  final int? heroIndex;
  final Cue? cue;
  final Cue? next;
  final int? nextIndex;
  final Cue? after;
  final int? afterIndex;
  final int remainingSec;
  final int elapsedSec;
  final String heroLabel;
  final bool nextDue;
  final int showElapsedSec;
  final int plannedSec;
  final int doneCount;
  final int cueCount;
}

class Cue {
  const Cue({
    required this.id,
    required this.title,
    required this.notes,
    required this.timing,
    required this.durationSec,
    required this.clockMinute,
  });

  final String id;
  final String title;
  final String notes;
  final CueTiming timing;
  final int durationSec;
  final int clockMinute;

  String get timingLabel => timing == CueTiming.duration
      ? formatSpan(durationSec)
      : formatMinute(clockMinute);

  Cue copyWith({
    String? id,
    String? title,
    String? notes,
    CueTiming? timing,
    int? durationSec,
    int? clockMinute,
  }) {
    return Cue(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      timing: timing ?? this.timing,
      durationSec: durationSec ?? this.durationSec,
      clockMinute: clockMinute ?? this.clockMinute,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'timing': timing.name,
    'durationSec': durationSec,
    'clockMinute': clockMinute,
  };

  factory Cue.fromJson(Map<String, Object?> json) {
    final timingName = json['timing'] as String? ?? 'duration';
    return Cue(
      id: json['id'] as String? ?? 'cue',
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      timing: timingName == 'clock' ? CueTiming.clock : CueTiming.duration,
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 60,
      clockMinute: (json['clockMinute'] as num?)?.toInt().clamp(0, 1439) ?? 0,
    );
  }
}

class Show {
  const Show({
    required this.title,
    required this.subtitle,
    required this.cues,
    this.sampleId,
  });

  final String title;
  final String subtitle;
  final String? sampleId;
  final List<Cue> cues;

  String get displayTitle {
    final trimmed = title.trim();
    return trimmed.isEmpty ? 'Untitled' : trimmed;
  }

  Show copyWith({
    String? title,
    String? subtitle,
    String? sampleId,
    bool clearSample = false,
    List<Cue>? cues,
  }) {
    return Show(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      sampleId: clearSample ? null : (sampleId ?? this.sampleId),
      cues: cues ?? this.cues,
    );
  }

  Map<String, Object?> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'sampleId': sampleId,
    'cues': cues.map((cue) => cue.toJson()).toList(),
  };

  factory Show.fromJson(Map<String, Object?> json) {
    final rawCues = json['cues'];
    return Show(
      title: json['title'] as String? ?? 'Untitled',
      subtitle: json['subtitle'] as String? ?? '',
      sampleId: json['sampleId'] as String?,
      cues: rawCues is List
          ? rawCues
                .whereType<Map>()
                .map((item) => Cue.fromJson(Map<String, Object?>.from(item)))
                .toList()
          : const [],
    );
  }
}

class LinkSettings {
  const LinkSettings({
    this.enabled = true,
    this.emitClock = true,
    this.instanceId = '',
  });

  /// Sending starts on. This app is the hub.
  static const hub = LinkSettings();

  final bool enabled;
  final bool emitClock;
  final String instanceId;

  LinkSettings copyWith({bool? enabled, bool? emitClock, String? instanceId}) {
    return LinkSettings(
      enabled: enabled ?? this.enabled,
      emitClock: emitClock ?? this.emitClock,
      instanceId: instanceId ?? this.instanceId,
    );
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'emitClock': emitClock,
    'instanceId': instanceId,
  };

  factory LinkSettings.fromJson(Map<String, Object?> json) {
    return LinkSettings(
      enabled: json['enabled'] as bool? ?? true,
      emitClock: json['emitClock'] as bool? ?? true,
      instanceId: json['instanceId'] as String? ?? '',
    );
  }
}

class RundownState {
  const RundownState({
    this.index,
    this.cueStartedAt,
    this.held = false,
    this.frozenRemainingSec,
    this.complete = false,
    this.showStartedAt,
  });

  final int? index;
  final DateTime? cueStartedAt;
  final bool held;
  final int? frozenRemainingSec;
  final bool complete;
  final DateTime? showStartedAt;

  RundownState copy({
    int? index,
    bool clearIndex = false,
    DateTime? cueStartedAt,
    bool clearCueStartedAt = false,
    bool? held,
    int? frozenRemainingSec,
    bool clearFrozen = false,
    bool? complete,
    DateTime? showStartedAt,
    bool clearShowStartedAt = false,
  }) {
    return RundownState(
      index: clearIndex ? null : (index ?? this.index),
      cueStartedAt: clearCueStartedAt
          ? null
          : (cueStartedAt ?? this.cueStartedAt),
      held: held ?? this.held,
      frozenRemainingSec: clearFrozen
          ? null
          : (frozenRemainingSec ?? this.frozenRemainingSec),
      complete: complete ?? this.complete,
      showStartedAt: clearShowStartedAt
          ? null
          : (showStartedAt ?? this.showStartedAt),
    );
  }

  RundownState clampedTo(Show show) {
    if (index == null) return this;
    if (index! < 0 || index! >= show.cues.length) {
      return RundownState(showStartedAt: showStartedAt);
    }
    return this;
  }

  Map<String, Object?> toJson() => {
    'index': index,
    'cueStartedAt': cueStartedAt == null ? null : isoStamp(cueStartedAt!),
    'held': held,
    'frozenRemainingSec': frozenRemainingSec,
    'complete': complete,
    'showStartedAt': showStartedAt == null ? null : isoStamp(showStartedAt!),
  };

  factory RundownState.fromJson(Map<String, Object?> json) {
    DateTime? stamp(Object? value) {
      if (value is! String || value.isEmpty) return null;
      return parseStamp(value);
    }

    return RundownState(
      index: (json['index'] as num?)?.toInt(),
      cueStartedAt: stamp(json['cueStartedAt']),
      held: json['held'] as bool? ?? false,
      frozenRemainingSec: (json['frozenRemainingSec'] as num?)?.toInt(),
      complete: json['complete'] as bool? ?? false,
      showStartedAt: stamp(json['showStartedAt']),
    );
  }
}

class Persisted {
  const Persisted({
    required this.show,
    required this.link,
    required this.rundown,
  });

  final Show show;
  final LinkSettings link;
  final RundownState rundown;

  Map<String, Object?> toJson() => {
    'version': 1,
    'show': show.toJson(),
    'link': link.toJson(),
    'rundown': rundown.toJson(),
  };

  factory Persisted.fromJson(Map<String, Object?> json) {
    final showRaw = json['show'];
    final linkRaw = json['link'];
    final runRaw = json['rundown'];
    return Persisted(
      show: showRaw is Map
          ? Show.fromJson(Map<String, Object?>.from(showRaw))
          : const Show(title: 'Untitled', subtitle: '', cues: []),
      link: linkRaw is Map
          ? LinkSettings.fromJson(Map<String, Object?>.from(linkRaw))
          : LinkSettings.hub,
      rundown: runRaw is Map
          ? RundownState.fromJson(Map<String, Object?>.from(runRaw))
          : const RundownState(),
    );
  }
}
