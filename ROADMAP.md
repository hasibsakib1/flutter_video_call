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
3. Minimal UI and permission handling
4. Add diagnostics and optional candidate batching if you encounter cost or
   connectivity issues

Concrete next step (pick one)
- I can scaffold the Firestore signaling helper + Emulator config and a tiny
  `HomeScreen`/`CallScreen` wired to it (estimated 3–4 hours).
- Or I can add `docs/SIGNALLING.md` + `lib/config/ice.dart` and an example
  message schema if you prefer to read before code (estimated 30–60m).

Tell me which and I'll implement it.

---

### Optional: Firebase-based signaling (Firestore / Realtime Database)

Contract
- Inputs: writes/updates to a Firestore document tree or RTDB paths representing
  offers, answers and per-client ICE candidate entries.
- Outputs: real-time snapshot listeners or child listeners deliver offers/answers
  and candidates to peers in the same room.
- Success: two peers exchange SDP and ICE via Firebase and establish a
  connected RTCPeerConnection.
- Failure modes: billing from high write volumes, listener race conditions,
  security rules misconfiguration.

Files to add
- `lib/signaling/firestore_signaling.dart` (or `firebase_database_signaling.dart`)
- `firebase/README.md` (setup notes and emulator instructions)
- `test/unit/firestore_signaling_test.dart` (using Firestore emulator)

Implementation notes
- Use `cloud_firestore` (or `firebase_database`) and `firebase_auth` for anonymous
  sign-in to provide stable client ids.
- Model: `rooms/{roomId}/offer`, `rooms/{roomId}/answer`,
  `rooms/{roomId}/candidates/{candidateId}`. Clients listen for changes and
  filter out their own writes by `senderId`.
- To reduce writes: batch candidates into arrays or use short TTLs and cleanup.
- Local testing: use the Firebase Emulator Suite to avoid production billing.

Security & cost notes
- Require authentication; use security rules to limit write sizes and
  per-room write rates.
- Firestore bills per write/read/delete; RTDB bills by bandwidth and concurrent
  connections. If you expect many small writes (candidates), RTDB or a
  WebSocket relay may be cheaper.
- Add scheduled cleanup (Cloud Function or cron) or TTL fields to avoid
  unbounded storage growth.

Tests & verification
- Use the Firestore emulator in CI to run unit tests without incurring cost.
- Integration: run two app instances against emulator and confirm negotiation.

Estimated effort: ~3–6 hours to implement basic Firestore signaling + emulator
tests; ~2–4 hours for RTDB variant and cost-hardening.

Updated ordering suggestion
1. Pick Firebase transport: Firestore (structured, easy SDK) or RTDB
  (lower latency / cheaper for many small writes). Scaffold
  `lib/signaling/firestore_signaling.dart` (or `firebase_database_signaling.dart`) and test with the Emulator Suite.
2. Implement Dart `Signaling` helper that uses the Firebase transport.
3. Add minimal UI and tests.

If you want I can scaffold the Firestore signaling helper and emulator
configuration now — say "scaffold firebase" and I'll implement it.

## Medium-term

- Improve UI/UX for mobile and web (responsive layout, call controls).
- Add NAT/turn/STUN configuration options and document them.
- Add recording/archiving option (with opt-in and storage recommendations).

## Long-term

- Integrate with a lightweight backend for authentication and room
  management.
- Add call quality metrics and a dashboard for monitoring sessions.
- Package app examples for distribution on Play Store / App Store / desktop
  installers.

## Experimental ideas

- Use Firestore as an optional signaling backend for serverless demos.
- Add an automated CI smoke test that spins up two browser instances with a
  test signaling server and verifies audio/video connectivity.


---

If you want any of these scaffolded now (for example, the Node WebSocket
signaling server and matching Dart `Signaling` helper), tell me which item to
start and I'll implement it in this repo.
