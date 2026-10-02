import 'package:alpaca_run_of_show/engine.dart';
import 'package:alpaca_run_of_show/models.dart';
import 'package:alpaca_run_of_show/sample_shows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 4, 9);
  final show = sundayGathering(now: now);

  test('sunday sample mixes durations and one clock hit', () {
    expect(show.cues.first.title, 'Walk-in');
    expect(show.cues.where((cue) => cue.timing == CueTiming.clock).length, 1);
    expect(show.cues[2].clockMinute, 10 * 60);
    expect(fridayAssembly().cues, isNotEmpty);
  });

  test('go fires the first cue and the next go advances', () {
    final first = goShow(show, const RundownState(), now);
    expect(first.fired?.cue.title, 'Walk-in');
    expect(first.state.index, 0);

    final later = now.add(const Duration(seconds: 30));
    final view = projectShow(show, first.state, later);
    expect(view.phase, Phase.running);
    expect(view.remainingSec, 12 * 60 - 30);

    final second = goShow(show, first.state, later);
    expect(second.fired?.cue.title, 'Countdown');
  });

  test('a finished duration waits for go', () {
    final started = goShow(show, const RundownState(), now);
    final over = now.add(const Duration(minutes: 13));
    final view = projectShow(show, started.state, over);
    expect(view.phase, Phase.overtime);
    expect(view.remainingSec, -60);
    expect(view.heroLabel, 'OVER');
    expect(goShow(show, started.state, over).fired?.cue.id, 'countdown');
  });

  test('hold freezes a duration countdown', () {
    final started = goShow(show, const RundownState(), now);
    final at = now.add(const Duration(seconds: 20));
    final held = holdShow(show, started.state, at);
    expect(held.fired, isNull);
    final later = at.add(const Duration(minutes: 5));
    final view = projectShow(show, held.state, later);
    expect(view.phase, Phase.held);
    expect(view.remainingSec, 12 * 60 - 20);
    final resumed = holdShow(show, held.state, later);
    final after = projectShow(
      show,
      resumed.state,
      later.add(const Duration(seconds: 1)),
    );
    expect(after.remainingSec, 12 * 60 - 21);
  });

  test('skip from ready starts the second cue', () {
    final skipped = skipShow(show, const RundownState(), now);
    expect(skipped.fired?.cue.title, 'Countdown');
  });

  test('the last go completes without another fire', () {
    final only = Show(title: 'One', subtitle: '', cues: [show.cues.first]);
    final live = goShow(only, const RundownState(), now);
    final done = goShow(only, live.state, now);
    expect(done.fired, isNull);
    expect(done.state.complete, isTrue);
    expect(projectShow(only, done.state, now).heroLabel, 'COMPLETE');
  });

  test('back refires the previous cue', () {
    final first = goShow(show, const RundownState(), now);
    final second = goShow(show, first.state, now);
    final back = backShow(show, second.state, now);
    expect(back.fired?.cue.title, 'Walk-in');
  });

  test('a clock hit more than 12 hours ago is tomorrow', () {
    final evening = DateTime(2026, 10, 4, 23, 30);
    final hit = clockOccurrence(evening, 10 * 60);
    expect(hit.day, 5);
    expect(hit.hour, 10);
  });
}
