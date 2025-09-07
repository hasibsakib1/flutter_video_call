# flutter_video_call

An experimental Flutter app demonstrating WebRTC-based video/audio calls.

This repository is an experimental playground for building peer-to-peer
real-time audio and video using Flutter and the platform WebRTC bindings.

## Status

- Experimental: rough prototype, API and UI will change.
- Objective: provide a lightweight demo showing how to connect two peers
	(mobile, desktop, or web) with audio/video streams using WebRTC.
 
## Requirements

## Requirements

- Flutter (stable) -- see https://docs.flutter.dev/get-started/install
- Platform toolchains for targets you care about (Android SDK, Xcode for iOS,
	Chrome for web, desktop toolchains for Linux/macOS/Windows as needed).

## Dependencies

- Recommended package: `flutter_webrtc` for native WebRTC bindings.
- A signaling mechanism (not included). Typical options:
	- small WebSocket server (Node, Python, Go)
	- Firebase Realtime Database / Firestore (quick for prototyping)
	- existing open demo signaling servers

See `pubspec.yaml` for currently pinned package versions used by this repo.

## Setup

1. Install Flutter and confirm it works:

```bash
flutter --version
flutter doctor
```

2. Get packages:

```bash
flutter pub get
```

3. Platform-specific permissions and notes

- Android: ensure `AndroidManifest.xml` contains camera and audio permissions:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

- iOS: add usage descriptions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Used to share video during calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Used to share audio during calls</string>
```

- Web: when running in the browser, use a secure context (https or localhost)
	for getUserMedia to work.

## Signaling

WebRTC needs a signaling channel to exchange SDP offers/answers and ICE
candidates. This project intentionally leaves signaling flexible so you can
pick an approach. For quick experiments consider:

- Firebase Realtime Database or Firestore — no server code required.
- Small WebSocket server (Node + ws) — low-latency, easy to control sessions.
- Use a simple HTTP API that relays offers/candidates for a single pair.

Example minimal flow:

1. Peer A creates an RTCPeerConnection, gets local media, creates an offer.
2. Peer A sends the offer to Peer B over signaling.
3. Peer B sets remote description, creates an answer and sends it back.
4. Both peers exchange ICE candidates as they appear.

If you want, I can add a tiny example signaling server (Node WebSocket)
and a matching client snippet in this repo — say the word and I'll scaffold it.

## Run (common commands)

- Run on Android device/emulator:

```bash
flutter run -d android
```

- Run on iOS simulator/device:

```bash
flutter run -d ios
```

- Run for web (Chrome):

```bash
flutter run -d chrome
```

## Testing and quick loopback

- For quick local testing you can run two browser windows (or two devices)
	and use a signaling backend that stores offers/answers for a room id.
- You can also implement a "loopback" mode that connects the local stream
	back to a peer connection in the same app (useful for testing rendering
	without a second device).

## Known issues & tips

- Mobile platforms require runtime permission prompts; test flow for denied
	permission cases.
- Web and native builds may use different codec priorities; if you see
	black video or no audio, check SDP and ICE state in logs.
- On some Linux desktop setups, camera device names and permissions vary.

## Known issues & tips

- Mobile platforms require runtime permission prompts; test flow for denied
 	permission cases.
- Web and native builds may use different codec priorities; if you see
 	black video or no audio, check SDP and ICE state in logs.
- On some Linux desktop setups, camera device names and permissions vary.

## Contributing

This is experimental. Open an issue or a PR with small, focused changes.

## License

Check the project root for a LICENSE file. If none exists, add one before
releasing any derivative work.
# flutter_video_call
