import 'models.dart';

int upcomingHour(DateTime now) {
  final next = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
  ).add(const Duration(hours: 1));
  return next.hour * 60 + next.minute;
}

Show sundayGathering({DateTime? now}) {
  final hit = upcomingHour(now ?? DateTime.now());
  return Show(
    title: 'Sunday Gathering',
    subtitle: 'Example church service',
    sampleId: 'sunday',
    cues: [
      const Cue(
        id: 'walk-in',
        title: 'Walk-in',
        notes: 'Pads under the room. House lights at 40%. Lobby doors open.',
        timing: CueTiming.duration,
        durationSec: 12 * 60,
        clockMinute: 0,
      ),
      const Cue(
        id: 'countdown',
        title: 'Countdown',
        notes: 'Roll the countdown. Band to the wings. Lyric screens black.',
        timing: CueTiming.duration,
        durationSec: 5 * 60,
        clockMinute: 0,
      ),
      Cue(
        id: 'welcome',
        title: 'Welcome',
        notes: 'Host on stage left. Greet guests. Dismiss kids at the end of this cue.',
        timing: CueTiming.clock,
        durationSec: 3 * 60,
        clockMinute: hit,
      ),
      const Cue(
        id: 'song-faithfulness',
        title: 'Song · Great Is Thy Faithfulness',
        notes: 'Keys lead. Full lyric on the center screen.',
        timing: CueTiming.duration,
        durationSec: 4 * 60 + 30,
        clockMinute: 0,
      ),
      const Cue(
        id: 'song-creatures',
        title: 'Song · All Creatures',
        notes: 'Band in. Drummer clicks it off.',
        timing: CueTiming.duration,
        durationSec: 4 * 60 + 15,
        clockMinute: 0,
      ),
      const Cue(
        id: 'prayer',
        title: 'Prayer',
        notes: 'Pastor from center. Sermon look on the amen.',
        timing: CueTiming.duration,
        durationSec: 2 * 60,
        clockMinute: 0,
      ),
      const Cue(
        id: 'announcements',
        title: 'Announcements',
        notes:
            'Fall retreat, baptism Sunday, youth night. Slides are in order.',
        timing: CueTiming.duration,
        durationSec: 3 * 60 + 30,
        clockMinute: 0,
      ),
      const Cue(
        id: 'offering',
        title: 'Offering',
        notes: 'Ushers from the back. Text-to-give slide stays up.',
        timing: CueTiming.duration,
        durationSec: 4 * 60,
        clockMinute: 0,
      ),
      const Cue(
        id: 'message',
        title: 'Message',
        notes: 'John 15. Clicker is with the speaker. Confidence monitor on.',
        timing: CueTiming.duration,
        durationSec: 25 * 60,
        clockMinute: 0,
      ),
      const Cue(
        id: 'response',
        title: 'Response',
        notes: 'Song under the prayer. Invite people forward on the second chorus.',
        timing: CueTiming.duration,
        durationSec: 5 * 60,
        clockMinute: 0,
      ),
      const Cue(
        id: 'benediction',
        title: 'Benediction',
        notes: 'House lights up on the amen. Band holds.',
        timing: CueTiming.duration,
        durationSec: 90,
        clockMinute: 0,
      ),
      const Cue(
        id: 'postlude',
        title: 'Postlude',
        notes: 'Play-out. Coffee in the lobby. House to full.',
        timing: CueTiming.duration,
        durationSec: 6 * 60,
        clockMinute: 0,
      ),
    ],
  );
}

Show fridayAssembly() {
  return const Show(
    title: 'Friday Assembly',
    subtitle: 'Example school assembly',
    sampleId: 'assembly',
    cues: [
      Cue(
        id: 'enter',
        title: 'Students enter',
        notes: 'Gym lights up. Walk-in playlist. Teachers on the aisles.',
        timing: CueTiming.duration,
        durationSec: 8 * 60,
        clockMinute: 0,
      ),
      Cue(
        id: 'pledge',
        title: 'Pledge and silence',
        notes: 'Flag on the center screen. Hold the room after the pledge.',
        timing: CueTiming.duration,
        durationSec: 2 * 60,
        clockMinute: 0,
      ),
      Cue(
        id: 'principal',
        title: 'Principal welcome',
        notes: 'Podium mic. One joke, then the schedule.',
        timing: CueTiming.duration,
        durationSec: 3 * 60,
        clockMinute: 0,
      ),
      Cue(
        id: 'awards',
        title: 'Awards',
        notes: 'Names on the side screen. Students stay seated until called.',
        timing: CueTiming.duration,
        durationSec: 6 * 60,
        clockMinute: 0,
      ),
      Cue(
        id: 'speakers',
        title: 'Eighth-grade speakers',
        notes: 'Two speakers. Clicker backstage. Applause slide between them.',
        timing: CueTiming.duration,
        durationSec: 8 * 60,
        clockMinute: 0,
      ),
      Cue(
        id: 'school-announcements',
        title: 'Announcements',
        notes: 'Picture day, early release Friday, game tonight.',
        timing: CueTiming.duration,
        durationSec: 4 * 60,
        clockMinute: 0,
      ),
      Cue(
        id: 'dismissal',
        title: 'Dismissal',
        notes: 'By grade, youngest first. Buses on the west lot.',
        timing: CueTiming.duration,
        durationSec: 3 * 60,
        clockMinute: 0,
      ),
    ],
  );
}

String newCueId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
