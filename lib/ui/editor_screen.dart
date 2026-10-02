import 'package:flutter/material.dart';

import '../models.dart';
import '../sample_shows.dart';
import '../theme.dart';
import 'cue_dialog.dart';
import 'widgets.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _titleFocus = FocusNode();
  final _subtitleFocus = FocusNode();
  var _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final show = ShowScope.of(context).show;
    if (!_seeded) {
      _title.text = show.title;
      _subtitle.text = show.subtitle;
      _seeded = true;
      return;
    }
    if (!_titleFocus.hasFocus && _title.text != show.title) {
      _title.text = show.title;
    }
    if (!_subtitleFocus.hasFocus && _subtitle.text != show.subtitle) {
      _subtitle.text = show.subtitle;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _titleFocus.dispose();
    _subtitleFocus.dispose();
    super.dispose();
  }

  Future<void> _edit(Cue cue, {required bool isNew}) async {
    final result = await showCueDialog(context, cue, isNew: isNew);
    if (!mounted || result == null) return;
    final controller = ShowScope.of(context);
    if (result.deleted) {
      controller.deleteCue(cue.id);
    } else if (result.cue != null) {
      if (isNew) {
        controller.addCue(result.cue!);
      } else {
        controller.updateCue(result.cue!);
      }
    }
  }

  Future<void> _loadSample(Show sample, String name) async {
    final ok = await confirmAction(
      context,
      title: 'Load $name?',
      message: 'This replaces the rundown and stops the cue that is up.',
      confirm: 'Load',
    );
    if (!mounted || !ok) return;
    ShowScope.of(context).loadSample(sample);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShowScope.of(context);
    final show = controller.show;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _title,
                focusNode: _titleFocus,
                style: condensed(28, weight: FontWeight.w700),
                decoration: const InputDecoration(labelText: 'Service'),
                onChanged: (value) => controller.rename(value, _subtitle.text),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subtitle,
                focusNode: _subtitleFocus,
                decoration: const InputDecoration(labelText: 'Subtitle'),
                onChanged: (value) => controller.rename(_title.text, value),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _edit(
                      Cue(
                        id: newCueId(),
                        title: '',
                        notes: '',
                        timing: CueTiming.duration,
                        durationSec: 300,
                        clockMinute: 10 * 60,
                      ),
                      isNew: true,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add cue'),
                  ),
                  OutlinedButton(
                    onPressed: () => _loadSample(
                      sundayGathering(now: controller.clock()),
                      'Sunday Gathering',
                    ),
                    child: const Text('Sunday example'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _loadSample(fridayAssembly(), 'Friday Assembly'),
                    child: const Text('Assembly example'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: show.cues.isEmpty
              ? const Center(
                  child: Text(
                    'Add the first cue.',
                    style: TextStyle(color: boothMuted, fontSize: 18),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: show.cues.length,
                  onReorderItem: (oldIndex, newIndex) {
                    controller.moveCue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final cue = show.cues[index];
                    return Card(
                      key: ValueKey(cue.id),
                      color: boothCard,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: boothLine),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle,
                            color: boothMuted,
                          ),
                        ),
                        title: Text(
                          '${(index + 1).toString().padLeft(2, '0')}  ${cue.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${cue.timingLabel}  ${cue.notes}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          tooltip: 'Edit cue',
                          onPressed: () => _edit(cue, isNew: false),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        onTap: () => _edit(cue, isNew: false),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
