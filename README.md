# Run of Show

![Run of Show](docs/icon.png)

Service timeline and cue clock for churches and schools. The booth sees ordered cues, a large countdown, the next cue, and the full stage list. Go starts the cue that is up.

The show stays on the device. The first launch loads a Sunday gathering you can replace.

## Run

Flutter stable (this project was built with Flutter 3.47 / Dart 3.13).

```bash
flutter pub get
flutter run -d linux
flutter run -d android
```

Windows and macOS projects are in the tree. Build those on the matching host with `flutter run -d windows` or `flutter run -d macos`.

```bash
flutter analyze
flutter test
```

On a wide window the sections sit in a side rail. A phone keeps them in the bottom bar: Run, Stage, Edit, Link, About.

Keyboard on the desktop window, when a text field is not focused: Space or G starts the cue, H holds, Left arrow goes back, Right arrow skips.

## Screens

1. **Run** — the cue that is up, a large countdown, the next cue, and Go. A duration cue that reaches zero stays in overtime until Go. Clock cues show the time until that hit, then how late the booth is.
2. **Stage** — every cue, its length or clock time, and Take. Take starts that cue.
3. **Edit** — title, notes, duration or clock time, reorder, and the two example rundowns.
4. **Link** — Alpaca Link send, the optional clock, and the recent packets.
5. **About** — the mark and the name Run of Show.

Sunday Gathering is the church example. Friday Assembly is the school example. Loading either one replaces the rundown.

## Android debug APK

No Play signing. Debug builds use the Android debug keystore.

```bash
tool/build_apk.sh
```

That runs `flutter build apk --debug --split-per-abi` and copies the arm64 package to `dist/run-of-show-arm64-debug.apk`. Install with `adb install -r` that file. The same split build is `.github/workflows/android-apk.yml`, which publishes `run-of-show-arm64-debug.apk` as a GitHub release.

## Alpaca Link

This booth is the hub. **Sending is on by default.** Turn it off on the Link screen when the room should stay quiet. **clock.time is also on by default** for this hub, at one packet a second. The protocol cap is 4 Hz. Turn clock.time off to send `cue.fire` only.

Go, Skip, Back, and Take start a cue. Each of those sends one `cue.fire`. The countdown reaching zero does not send another fire and does not advance.

Stage Presets and LS Mobile do not listen yet. When they do, they join this group:

| | |
| --- | --- |
| Address | `239.255.42.77` |
| Port | `44771` |
| TTL | `1` |
| Encoding | UTF-8 JSON, one object per UDP datagram |

`source.app` is `run-of-show`. `source.name` is `Run of Show`. `source.instance` is a stable id for this install. `show` is the service title. `name` is the cue name. `timestamp` is UTC. `id` is unique per datagram.

```json
{
  "version": 1,
  "source": {
    "app": "run-of-show",
    "instance": "ros-example",
    "name": "Run of Show"
  },
  "type": "cue.fire",
  "name": "Walk-in",
  "payload": {
    "cueId": "walk-in",
    "cueIndex": 0,
    "cueCount": 12,
    "notes": "Pads under the room.",
    "timing": "duration",
    "durationSec": 720
  },
  "timestamp": "2026-10-04T14:00:00.000Z",
  "id": "ros-example-1",
  "show": "Sunday Gathering"
}
```

`clock.time` uses the same envelope. `type` is `clock.time`, `name` is the cue on the clock, and `payload` includes `remainingSec`, `elapsedSec`, `phase`, `held`, `overtime`, and `running`.

A listener:

```python
import json, socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(("", 44771))
group = socket.inet_aton("239.255.42.77") + socket.inet_aton("0.0.0.0")
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, group)
while True:
    data, _addr = sock.recvfrom(4096)
    msg = json.loads(data.decode())
    if msg.get("source", {}).get("app") != "run-of-show":
        continue
    if msg["type"] == "cue.fire":
        print("FIRE", msg["name"])
    elif msg["type"] == "clock.time":
        print("CLOCK", msg["name"], msg["payload"].get("remainingSec"))
```

TTL 1 keeps the datagram on the local subnet. The phone and the listeners need the same LAN. Guest Wi-Fi that blocks multicast will not deliver it.

## Fonts

Barlow and JetBrains Mono are used for the booth UI. Their OFL notices are in `third_party/fonts/`.
