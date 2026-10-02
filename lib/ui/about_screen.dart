import 'package:flutter/material.dart';

import '../brand.dart';
import '../theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              iconAsset,
              key: const Key('product-icon'),
              width: 144,
              height: 144,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          productName,
          key: const Key('about-title'),
          style: condensed(48, weight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          productTagline,
          style: const TextStyle(fontSize: 18, height: 1.35),
        ),
        const SizedBox(height: 8),
        Text(
          'Version $appVersion',
          style: const TextStyle(color: boothMuted, fontSize: 14),
        ),
        const SizedBox(height: 22),
        const Text(
          'Ordered cues carry a title, a duration or a clock time, and the note the booth needs.',
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 10),
        const Text(
          'Run mode is the countdown and the next cue. Stage is the whole rundown, with Take on any row.',
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 10),
        const Text(
          'Go starts the cue that is up. The countdown holds at zero until the operator advances.',
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
      ],
    );
  }
}
