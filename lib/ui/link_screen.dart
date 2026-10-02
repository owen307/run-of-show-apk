import 'package:flutter/material.dart';

import '../brand.dart';
import '../format.dart';
import '../theme.dart';
import 'widgets.dart';

class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShowScope.of(context);
    final link = controller.link;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Link', style: condensed(32, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
          'Alpaca Link is on. This booth is the hub, so cue.fire leaves when you hit Go.',
          style: TextStyle(color: boothText, fontSize: 16, height: 1.35),
        ),
        const SizedBox(height: 8),
        Text(
          'Multicast $linkGroup:$linkPort · TTL $linkTtl',
          style: clockStyle(16, boothAmber),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Send Alpaca Link'),
          subtitle: Text(
            link.enabled
                ? 'cue.fire goes out when a cue starts'
                : 'Packets stay on this booth',
            style: const TextStyle(color: boothMuted),
          ),
          value: link.enabled,
          onChanged: (value) =>
              controller.setLink(link.copyWith(enabled: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Also emit clock.time'),
          subtitle: const Text(
            'On for this hub. One packet a second, under the 4 Hz cap.',
            style: TextStyle(color: boothMuted),
          ),
          value: link.emitClock,
          onChanged: (value) =>
              controller.setLink(link.copyWith(emitClock: value)),
        ),
        const SizedBox(height: 8),
        Text('Instance ${link.instanceId}', style: clockStyle(13, boothMuted)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: link.enabled ? controller.testFire : null,
            child: const Text('Test fire'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.linkError ??
              '${controller.sentCount} packets this session',
          style: TextStyle(
            color: controller.linkError == null ? boothMuted : boothRed,
          ),
        ),
        const SizedBox(height: 16),
        Text('Recent packets', style: condensed(22, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (controller.log.isEmpty)
          const Text(
            'Go, Take, or Test fire writes a line here.',
            style: TextStyle(color: boothMuted),
          )
        else
          for (final entry in controller.log)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${formatWall(entry.at)}  ${entry.type}  ${entry.name}${entry.ok ? '' : '  ${entry.error ?? 'failed'}'}',
                style: clockStyle(13, entry.ok ? boothText : boothRed),
              ),
            ),
        const SizedBox(height: 18),
        const Text(
          'Stage Presets and LS Mobile can listen later. Join 239.255.42.77 port 44771 and read one JSON object per datagram. source.app is run-of-show. The cue name is the name field on cue.fire.',
          style: TextStyle(color: boothMuted, fontSize: 14, height: 1.4),
        ),
      ],
    );
  }
}
