import 'format.dart';
import 'link.dart';
import 'models.dart';

class Step {
  const Step(this.state, this.fired);

  final RundownState state;
  final Fired? fired;
}

DateTime clockOccurrence(DateTime now, int minute) {
  final clamped = minute.clamp(0, 1439);
  final today = DateTime(
    now.year,
    now.month,
    now.day,
    clamped ~/ 60,
    clamped % 60,
  );
  if (today.isBefore(now.subtract(const Duration(hours: 12)))) {
    return today.add(const Duration(days: 1));
  }
  return today;
}

int plannedSeconds(Show show) {
  var total = 0;
  for (final cue in show.cues) {
    if (cue.timing == CueTiming.duration) total += cue.durationSec;
  }
  return total;
}

String planLine(Show show) {
  final clocks = show.cues.where((cue) => cue.timing == CueTiming.clock).length;
  final clockBit = clocks == 0
      ? ''
      : ' · $clocks clock ${clocks == 1 ? 'hit' : 'hits'}';
  return '${show.cues.length} cues · ${formatSpan(plannedSeconds(show))} planned$clockBit';
}

CueView projectShow(Show show, RundownState state, DateTime now) {
  final planned = plannedSeconds(show);
  final showElapsed = state.showStartedAt == null
      ? 0
      : now.difference(state.showStartedAt!).inSeconds.clamp(0, 1 << 30);
  if (show.cues.isEmpty) {
    return CueView(
      phase: Phase.ready,
      activeIndex: null,
      heroIndex: null,
      cue: null,
      next: null,
      nextIndex: null,
      after: null,
      afterIndex: null,
      remainingSec: 0,
      elapsedSec: 0,
      heroLabel: 'EMPTY',
      nextDue: false,
      showElapsedSec: showElapsed,
      plannedSec: planned,
      doneCount: 0,
      cueCount: 0,
    );
  }
  if (state.complete) {
    return CueView(
      phase: Phase.complete,
      activeIndex: null,
      heroIndex: null,
      cue: null,
      next: null,
      nextIndex: null,
      after: null,
      afterIndex: null,
      remainingSec: 0,
      elapsedSec: 0,
      heroLabel: 'COMPLETE',
      nextDue: false,
      showElapsedSec: showElapsed,
      plannedSec: planned,
      doneCount: show.cues.length,
      cueCount: show.cues.length,
    );
  }

  final active = state.index;
  final heroIndex = active ?? 0;
  final cue = show.cues[heroIndex];
  final remaining = _remaining(state, cue, now, active == null);
  final phase = active == null
      ? Phase.ready
      : state.held
      ? Phase.held
      : remaining < 0
      ? Phase.overtime
      : Phase.running;
  final nextIndex = heroIndex + 1 < show.cues.length ? heroIndex + 1 : null;
  final afterIndex = nextIndex != null && nextIndex + 1 < show.cues.length
      ? nextIndex + 1
      : null;
  final next = nextIndex == null ? null : show.cues[nextIndex];
  final nextDue =
      next != null &&
      next.timing == CueTiming.clock &&
      !clockOccurrence(now, next.clockMinute).isAfter(now);
  return CueView(
    phase: phase,
    activeIndex: active,
    heroIndex: heroIndex,
    cue: cue,
    next: next,
    nextIndex: nextIndex,
    after: afterIndex == null ? null : show.cues[afterIndex],
    afterIndex: afterIndex,
    remainingSec: remaining,
    elapsedSec: _elapsed(state, cue, now, active != null),
    heroLabel: _heroLabel(phase, cue, remaining),
    nextDue: nextDue,
    showElapsedSec: showElapsed,
    plannedSec: planned,
    doneCount: active ?? 0,
    cueCount: show.cues.length,
  );
}

int _remaining(RundownState state, Cue cue, DateTime now, bool preview) {
  if (preview) {
    if (cue.timing == CueTiming.duration) return cue.durationSec;
    return clockOccurrence(now, cue.clockMinute).difference(now).inSeconds;
  }
  if (state.held &&
      cue.timing == CueTiming.duration &&
      state.frozenRemainingSec != null) {
    return state.frozenRemainingSec!;
  }
  if (cue.timing == CueTiming.clock) {
    return clockOccurrence(now, cue.clockMinute).difference(now).inSeconds;
  }
  final started = state.cueStartedAt ?? now;
  return cue.durationSec - now.difference(started).inSeconds;
}

int _elapsed(RundownState state, Cue cue, DateTime now, bool active) {
  if (!active || state.cueStartedAt == null) return 0;
  if (state.held &&
      cue.timing == CueTiming.duration &&
      state.frozenRemainingSec != null) {
    return cue.durationSec - state.frozenRemainingSec!;
  }
  final elapsed = now.difference(state.cueStartedAt!).inSeconds;
  return elapsed < 0 ? 0 : elapsed;
}

String _heroLabel(Phase phase, Cue cue, int remaining) {
  switch (phase) {
    case Phase.complete:
      return 'COMPLETE';
    case Phase.ready:
      if (cue.timing == CueTiming.clock) {
        return remaining < 0
            ? 'LATE'
            : 'UNTIL ${formatMinute(cue.clockMinute)}';
      }
      return 'READY';
    case Phase.held:
      return 'HOLD';
    case Phase.overtime:
      return cue.timing == CueTiming.clock ? 'LATE' : 'OVER';
    case Phase.running:
      if (cue.timing == CueTiming.clock) {
        return remaining < 0 ? 'LATE' : 'HIT ${formatMinute(cue.clockMinute)}';
      }
      return 'REMAINING';
  }
}

Step goShow(Show show, RundownState state, DateTime now) {
  if (show.cues.isEmpty) return Step(state, null);
  if (state.complete || state.index == null) {
    return _start(
      show,
      0,
      now,
      showStartedAt: state.complete ? now : (state.showStartedAt ?? now),
    );
  }
  final next = state.index! + 1;
  if (next >= show.cues.length) return _finish(state);
  return _start(show, next, now, showStartedAt: state.showStartedAt ?? now);
}

Step skipShow(Show show, RundownState state, DateTime now) {
  if (show.cues.isEmpty || state.complete) return Step(state, null);
  if (state.index == null) {
    final index = show.cues.length >= 2 ? 1 : 0;
    return _start(show, index, now, showStartedAt: state.showStartedAt ?? now);
  }
  final next = state.index! + 1;
  if (next >= show.cues.length) return _finish(state);
  return _start(show, next, now, showStartedAt: state.showStartedAt ?? now);
}

Step backShow(Show show, RundownState state, DateTime now) {
  if (show.cues.isEmpty) return Step(state, null);
  if (state.complete) {
    return _start(
      show,
      show.cues.length - 1,
      now,
      showStartedAt: state.showStartedAt ?? now,
    );
  }
  if (state.index == null) return Step(state, null);
  final index = state.index == 0 ? 0 : state.index! - 1;
  return _start(show, index, now, showStartedAt: state.showStartedAt ?? now);
}

Step holdShow(Show show, RundownState state, DateTime now) {
  if (state.index == null ||
      state.complete ||
      state.index! < 0 ||
      state.index! >= show.cues.length) {
    return Step(state, null);
  }
  final cue = show.cues[state.index!];
  if (state.held) {
    if (cue.timing == CueTiming.duration && state.frozenRemainingSec != null) {
      final elapsed = cue.durationSec - state.frozenRemainingSec!;
      return Step(
        state.copy(
          held: false,
          cueStartedAt: now.subtract(Duration(seconds: elapsed)),
          clearFrozen: true,
        ),
        null,
      );
    }
    return Step(state.copy(held: false, clearFrozen: true), null);
  }
  final remaining = _remaining(state, cue, now, false);
  return Step(state.copy(held: true, frozenRemainingSec: remaining), null);
}

Step takeShow(Show show, RundownState state, int index, DateTime now) {
  if (index < 0 || index >= show.cues.length) return Step(state, null);
  if (state.index == index && !state.complete && state.cueStartedAt != null) {
    return Step(state, null);
  }
  return _start(show, index, now, showStartedAt: state.showStartedAt ?? now);
}

Step resetShow() => const Step(RundownState(), null);

RundownState followRun(RundownState run, Show previous, Show next) {
  if (next.cues.isEmpty) return const RundownState();
  if (run.index == null) return run;
  if (run.index! < 0 || run.index! >= previous.cues.length) {
    return RundownState(showStartedAt: run.showStartedAt);
  }
  final id = previous.cues[run.index!].id;
  final found = next.cues.indexWhere((cue) => cue.id == id);
  if (found < 0) return RundownState(showStartedAt: run.showStartedAt);
  return run.copy(index: found);
}

String rowStatus(Show show, CueView view, int index, DateTime now) {
  if (index < 0 || index >= show.cues.length) return '';
  if (view.phase == Phase.complete) return 'DONE';
  if (view.activeIndex == null) {
    if (index == 0) return 'NEXT';
    return _clockDue(show.cues[index], now) ? 'DUE' : '';
  }
  if (view.activeIndex == index) {
    if (view.phase == Phase.held) return 'HOLD';
    if (view.phase == Phase.overtime) return 'OVER';
    return 'LIVE';
  }
  if (index < view.activeIndex!) return 'DONE';
  if (view.nextIndex == index) {
    return _clockDue(show.cues[index], now) ? 'DUE' : 'NEXT';
  }
  return _clockDue(show.cues[index], now) ? 'DUE' : '';
}

bool _clockDue(Cue cue, DateTime now) {
  if (cue.timing != CueTiming.clock) return false;
  return !clockOccurrence(now, cue.clockMinute).isAfter(now);
}

Step _start(
  Show show,
  int index,
  DateTime now, {
  required DateTime showStartedAt,
}) {
  return Step(
    RundownState(index: index, cueStartedAt: now, showStartedAt: showStartedAt),
    Fired(show.cues[index], index),
  );
}

Step _finish(RundownState state) {
  return Step(
    state.copy(
      clearIndex: true,
      clearCueStartedAt: true,
      held: false,
      clearFrozen: true,
      complete: true,
    ),
    null,
  );
}
