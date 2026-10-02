import 'package:flutter/material.dart';

import '../engine.dart';
import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'widgets.dart';

class RunScreen extends StatelessWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShowScope.of(context);
    final now = controller.clock();
    final view = controller.project(now);
    final show = controller.show;
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy =
            constraints.maxHeight >= 560 && constraints.maxWidth >= 720;
        final wide = constraints.maxWidth >= 980;
        final service = _ServiceLine(show: show, view: view);
        final hero = _Hero(view: view);
        final side = _NextStack(view: view, show: show);
        final controls = _Controls(view: view, show: show);
        if (!roomy) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              service,
              const SizedBox(height: 8),
              SizedBox(height: 280, child: hero),
              if (view.nextDue) _DueBanner(view: view),
              side,
              const SizedBox(height: 12),
              controls,
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              service,
              if (view.nextDue) _DueBanner(view: view),
              const SizedBox(height: 8),
              Expanded(
                child: wide
                    ? Row(
                        children: [
                          Expanded(flex: 3, child: hero),
                          const SizedBox(width: 16),
                          SizedBox(width: 340, child: side),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: hero),
                          side,
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              controls,
            ],
          ),
        );
      },
    );
  }
}

class _ServiceLine extends StatelessWidget {
  const _ServiceLine({required this.show, required this.view});

  final Show show;
  final CueView view;

  @override
  Widget build(BuildContext context) {
    final count = view.cueCount;
    final number = view.heroIndex == null ? null : cueNumber(view.heroIndex!);
    final place = count == 0
        ? 'No cues yet'
        : view.phase == Phase.complete
        ? 'Show complete'
        : 'Cue $number / ${count.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                show.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: condensed(32, weight: FontWeight.w700),
              ),
              Text(
                show.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: boothMuted, fontSize: 14),
              ),
            ],
          ),
        ),
        if (show.sampleId != null) const StatusChip(label: 'EXAMPLE'),
        const SizedBox(width: 8),
        Text(place, style: const TextStyle(color: boothMuted, fontSize: 14)),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.view});

  final CueView view;

  @override
  Widget build(BuildContext context) {
    final cue = view.cue;
    final color = heroColor(view.heroLabel, view.remainingSec);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cue?.title ??
              (view.phase == Phase.complete ? 'Show complete' : 'Add a cue'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: condensed(40, weight: FontWeight.w700),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                view.phase == Phase.complete
                    ? '00:00'
                    : formatSpan(view.remainingSec),
                style: clockStyle(168, color),
              ),
            ),
          ),
        ),
        Text(
          view.heroLabel,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          cue?.notes ?? 'Edit builds the rundown. Go starts the first cue.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, height: 1.3),
        ),
      ],
    );
  }
}

class _NextStack extends StatelessWidget {
  const _NextStack({required this.view, required this.show});

  final CueView view;
  final Show show;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CueCard(
          kicker: 'NEXT UP',
          number: view.nextIndex == null ? null : cueNumber(view.nextIndex!),
          cue: view.next,
          empty: 'Nothing after this',
        ),
        const SizedBox(height: 8),
        _CueCard(
          kicker: 'THEN',
          number: view.afterIndex == null ? null : cueNumber(view.afterIndex!),
          cue: view.after,
          empty: planLine(show),
          dense: true,
        ),
      ],
    );
  }
}

class _CueCard extends StatelessWidget {
  const _CueCard({
    required this.kicker,
    required this.number,
    required this.cue,
    required this.empty,
    this.dense = false,
  });

  final String kicker;
  final String? number;
  final Cue? cue;
  final String empty;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 12 : 14),
      decoration: BoxDecoration(
        color: boothCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: boothLine),
      ),
      child: cue == null
          ? Text(empty, style: const TextStyle(color: boothMuted, fontSize: 14))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: const TextStyle(
                    color: boothBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${number ?? ''}  ${cue!.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: condensed(dense ? 22 : 28, weight: FontWeight.w600),
                ),
                Text(cue!.timingLabel, style: clockStyle(16, boothAmber)),
                if (!dense && cue!.notes.isNotEmpty)
                  Text(
                    cue!.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: boothMuted, fontSize: 14),
                  ),
              ],
            ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  const _DueBanner({required this.view});

  final CueView view;

  @override
  Widget build(BuildContext context) {
    final cue = view.next;
    if (cue == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'NEXT IS DUE · ${cue.title} · ${cue.timingLabel}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: boothAmber,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.view, required this.show});

  final CueView view;
  final Show show;

  @override
  Widget build(BuildContext context) {
    final controller = ShowScope.of(context);
    final active = view.activeIndex != null;
    final caption = _caption(view, show);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    show.cues.isEmpty ||
                        (!active && view.phase != Phase.complete)
                    ? null
                    : controller.back,
                child: const Text('BACK'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: active && view.phase == Phase.held
                  ? FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: boothAmber,
                        foregroundColor: const Color(0xFF1A1203),
                      ),
                      onPressed: controller.toggleHold,
                      child: const Text('HOLD'),
                    )
                  : OutlinedButton(
                      onPressed: active ? controller.toggleHold : null,
                      child: const Text('HOLD'),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: boothRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 56),
                ),
                onPressed: show.cues.isEmpty ? null : controller.go,
                child: const Text('GO'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: show.cues.isEmpty || view.phase == Phase.complete
                    ? null
                    : controller.skip,
                child: const Text('SKIP'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: view.phase == Phase.ready && view.showElapsedSec == 0
                    ? null
                    : () async {
                        final ok = await confirmAction(
                          context,
                          title: 'Reset the rundown?',
                          message:
                              'The clock returns to the top. Nothing is fired.',
                          confirm: 'Reset',
                        );
                        if (ok) controller.reset();
                      },
                child: const Text('RESET'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: boothMuted, fontSize: 13),
        ),
      ],
    );
  }

  String _caption(CueView view, Show show) {
    if (show.cues.isEmpty) return 'Add cues in Edit';
    if (view.phase == Phase.complete) return 'GO starts the rundown again';
    if (view.activeIndex == null) {
      return 'GO starts ${view.cue?.title ?? 'the first cue'}';
    }
    if (view.next == null) return 'GO ends the show';
    return 'GO takes ${view.next!.title}';
  }
}
