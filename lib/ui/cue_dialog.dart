import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';

class CueFormResult {
  const CueFormResult({this.cue, this.deleted = false});

  final Cue? cue;
  final bool deleted;
}

Future<CueFormResult?> showCueDialog(
  BuildContext context,
  Cue cue, {
  required bool isNew,
}) {
  return showDialog<CueFormResult>(
    context: context,
    builder: (context) => _CueDialog(cue: cue, isNew: isNew),
  );
}

class _CueDialog extends StatefulWidget {
  const _CueDialog({required this.cue, required this.isNew});

  final Cue cue;
  final bool isNew;

  @override
  State<_CueDialog> createState() => _CueDialogState();
}

class _CueDialogState extends State<_CueDialog> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _minutes;
  late final TextEditingController _seconds;
  late CueTiming _timing;
  late int _clockMinute;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.cue.title);
    _notes = TextEditingController(text: widget.cue.notes);
    _minutes = TextEditingController(
      text: (widget.cue.durationSec ~/ 60).toString(),
    );
    _seconds = TextEditingController(
      text: (widget.cue.durationSec % 60).toString().padLeft(2, '0'),
    );
    _timing = widget.cue.timing;
    _clockMinute = widget.cue.clockMinute == 0
        ? 10 * 60
        : widget.cue.clockMinute;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _setDuration(int seconds) {
    _minutes.text = (seconds ~/ 60).toString();
    _seconds.text = (seconds % 60).toString().padLeft(2, '0');
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give the cue a title.');
      return;
    }
    var duration = widget.cue.durationSec;
    if (_timing == CueTiming.duration) {
      final minutes = int.tryParse(_minutes.text.trim()) ?? 0;
      final seconds = int.tryParse(_seconds.text.trim()) ?? 0;
      duration = minutes * 60 + seconds;
      if (duration < 1) {
        setState(() => _error = 'Duration needs at least one second.');
        return;
      }
    }
    Navigator.pop(
      context,
      CueFormResult(
        cue: widget.cue.copyWith(
          title: title,
          notes: _notes.text.trim(),
          timing: _timing,
          durationSec: duration,
          clockMinute: _clockMinute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isNew ? 'New cue' : 'Edit cue',
                style: condensed(28, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 14),
              SegmentedButton<CueTiming>(
                segments: const [
                  ButtonSegment(
                    value: CueTiming.duration,
                    label: Text('Duration'),
                  ),
                  ButtonSegment(
                    value: CueTiming.clock,
                    label: Text('Clock time'),
                  ),
                ],
                selected: {_timing},
                onSelectionChanged: (value) =>
                    setState(() => _timing = value.first),
              ),
              const SizedBox(height: 12),
              if (_timing == CueTiming.duration) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minutes,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(labelText: 'Minutes'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _seconds,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(labelText: 'Seconds'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final seconds in [
                      30,
                      60,
                      120,
                      180,
                      300,
                      600,
                      900,
                      1800,
                    ])
                      ActionChip(
                        label: Text(formatSpan(seconds)),
                        onPressed: () => setState(() => _setDuration(seconds)),
                      ),
                  ],
                ),
              ] else
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: _clockMinute ~/ 60,
                        minute: _clockMinute % 60,
                      ),
                    );
                    if (picked == null) return;
                    setState(
                      () => _clockMinute = picked.hour * 60 + picked.minute,
                    );
                  },
                  child: Text(formatMinute(_clockMinute)),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: boothRed)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!widget.isNew)
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const CueFormResult(deleted: true),
                      ),
                      child: const Text('Delete'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
