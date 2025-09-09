# Roadmap & Planning

This file contains experimental plans, next steps, and roadmap items for the
`flutter_video_call` project. It is intentionally separated from `README.md` to
keep the README strictly focused on project information and setup.

## Short-term (learning-focused)

This project is primarily an experiment to learn WebRTC with Flutter. The
short-term roadmap below focuses on the minimal set of items you actually
need to learn the technology quickly, plus a few optional items you can add
later if desired.

Do now (minimal, recommended for learning)
- Firebase signaling (Firestore) + Emulator for local development and tests
- Anonymous Firebase auth (use `uid` as `senderId`)
- `lib/signaling/firestore_signaling.dart` implementing basic offer/answer/
  candidate flow (queue candidates until remote-desc applied)
- Minimal UI: `HomeScreen` (create/join) and `CallScreen` (local preview +
  remote video + basic controls)
- Permission handling + simple retry UX
- STUN config using a public STUN (e.g. `stun:stun.l.google.com:19302`) in
  your `iceServers` configuration
- Console/logging hooks for SDP/ICE diagnostics

Optional (nice-to-have while learning)
- Candidate batching helper to reduce Firestore writes (or switch to RTDB)
- Basic Firestore security rules sketch and emulator-based rule tests
- Small diagnostics panel in-app showing ICE/SDP/connection state and timestamps
- Smoke-test script using the Emulator Suite (two web instances) for quick E2E checks

Defer (not needed for learning the basics)
- TURN server (only add if you hit NAT/firewall failures you cannot bypass)
- Cloud Functions cleanup / scheduled jobs (production housekeeping)
- CI wiring and full cost-hardening
- Multi-party (SFU) or recording features

Recommended ordering
1. Firebase signaling + data model + Emulator
2. Dart `Signaling` helper wired to Firestore/RTDB
# Roadmap & Planning

This file contains experimental plans, next steps, and roadmap items for the
`flutter_video_call` project. It's intentionally concise and focused on the
learning path so you can iterate quickly.

Current decisions
- Signaling transport: Cloud Firestore (serverless Firestore document model).
- Authentication: removed for the quick experiment — the app now generates a
  short-lived `localId` (timestamp-based) instead of requiring Firebase Auth.
  This reduces platform config friction while learning. For production,
  re-introduce an auth system (Firebase Auth or your own) for stable client ids.
- ICE: STUN-only by default (`stun:stun.l.google.com:19302`) in
  `lib/config/ice.dart`. Add TURN only when NAT traversal requires it.

Short-term (learning-focused, prioritized)

1. Fix native Firebase platform config for device testing
   - Why: the app initializes `firebase_core` and uses Firestore; Android/iOS
     still require the native configuration (`google-services.json` /
     `GoogleService-Info.plist`) that matches the app package id, or you can
     use the Firebase Emulator Suite to avoid native config during local dev.
   - Time: 15–30m if the Android app is already registered in Firebase.

2. Implement RTCPeerConnection glue in `lib/signaling/firestore_signaling.dart`
   - What: create/manage `RTCPeerConnection`, attach local streams, create/send
     offers and answers, apply remote descriptions, and handle ICE candidates.
   - Important: queue remote ICE candidates until the remote description is
     applied to avoid race conditions.
   - Time: 3–6 hours (learning + implementation).

3. Persist local client id across restarts (helpful)
   - Use `shared_preferences` or a tiny file to store a UUID/localId so peers
     can be identified consistently between app launches.
   - Time: ~15–30m.

4. Add Firebase Emulator Suite guide and local workflow (`firebase/README.md`)
   - Why: lets you iterate without native platform config and without incurring
     production billing while testing signaling flows.
   - Time: 30–60m to document and verify.

5. Add a light diagnostics overlay in `CallScreen`
   - Shows connection state, ICE gathering state, last SDP sizes, and event
     timestamps to speed debugging when negotiating calls.
   - Time: 1–2 hours.

Optional (later / if needed)
- Candidate batching or switching to RTDB if Firestore write costs become an issue.
- TURN server for reliable connectivity in restrictive networks.
- Security rules + emulator-based rule tests before public testing.

Next concrete actions (pick one)
- Implement RTCPeerConnection glue in `lib/signaling/firestore_signaling.dart`
  and wire it to `CallScreen` so you can establish P2P calls (recommended).
  Estimated 3–6 hours.

- Implement persistent `localId` using `shared_preferences` now (quick, 15–30m).

- Update `firebase/README.md` with an Emulator Suite guide and small scripts to
  start it (quick, 30–60m).

Notes & rationale
- For a quick learning experiment it's fine to avoid auth; a generated or
  persisted local id is sufficient for signaling. When moving toward
  multi-user or production scenarios, add an auth system to provide identity.

- The repo no longer depends on `firebase_auth` in `pubspec.yaml`. Generated
  or build artifacts may still mention firebase_auth in caches; run
  `flutter clean` before a full rebuild to refresh those artifacts.

Quality gates before production
- Add Firestore security rules and test them against the Emulator.
- Add TURN or SFU options for multi-party and NAT traversal reliability.
- Add unit tests for signaling helpers and a small emulator-based integration
  smoke test.

If you want me to implement any of the "Next concrete actions" above, tell me
which one and I'll start — I can implement the persistent `localId` now and
then follow with RTCPeerConnection glue in the signaling helper.

```

