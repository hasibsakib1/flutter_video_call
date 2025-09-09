import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/ice.dart';

/// Firestore-based signaling helper with RTCPeerConnection glue.
/// Responsibilities:
/// - Create RTCPeerConnection with `defaultIceServers`.
/// - Manage local media (getUserMedia).
/// - Create/send offer and answer documents and send ICE candidates.
/// - Queue remote ICE candidates until remote description is applied.
class FirestoreSignaling {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String roomId;
  final String localId;

  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _candidatesSub;

  // Public callbacks for UI or external hooks
  void Function(Map<String, dynamic> offer)? onOffer;
  void Function(Map<String, dynamic> answer)? onAnswer;
  void Function(Map<String, dynamic> candidate)? onCandidate;

  // Internal RTCPeerConnection state
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final List<Map<String, dynamic>> _remoteCandidateQueue = [];
  bool _remoteDescSet = false;

  FirestoreSignaling({required this.roomId, required this.localId});

  Future<void> join() async {
    final roomRef = _db.collection('rooms').doc(roomId);

    // ensure room exists
    try {
      await roomRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e, st) {
      // Surface a clearer debug message for permission/configuration errors and avoid an unhandled exception.
      // Typical causes: Firestore not enabled, projectId mismatch, or restrictive security rules.
      // Caller can observe logs and choose to show UI feedback if desired.
      // We return early so subscriptions are not created when the initial write failed.
      // Keep the stack trace in logs for debugging.
      // ignore: avoid_print
      print('Firestore: failed to ensure room exists: $e\n$st');
      return;
    }

    // subscribe to offer/answer/candidates
    _offerSub = roomRef.collection('offer').doc('sdp').snapshots().listen((snap) async {
      if (snap.exists) {
        final data = snap.data();
        if (data != null && data['senderId'] != localId) {
          // allow external hook
          onOffer?.call(data);
          // handle offer by default: create PC if needed and answer
          await _handleRemoteOffer(data);
        }
      }
    });

    _answerSub = roomRef.collection('answer').doc('sdp').snapshots().listen((snap) async {
      if (snap.exists) {
        final data = snap.data();
        if (data != null && data['senderId'] != localId) {
          onAnswer?.call(data);
          await _handleRemoteAnswer(data);
        }
      }
    });

    _candidatesSub = roomRef.collection('candidates').snapshots().listen((snaps) async {
      for (final docChange in snaps.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final data = docChange.doc.data();
          if (data != null && data['senderId'] != localId) {
            onCandidate?.call(data);
            await _handleRemoteCandidate(data);
          }
        }
      }
    });
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    if (_pc != null) return _pc!;

    final config = <String, dynamic>{'iceServers': defaultIceServers};
    final constraints = <String, dynamic>{'mandatory': {}, 'optional': []};

    final pc = await createPeerConnection(config, constraints);

    // set up event handlers
    pc.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) return;
      // send candidate to Firestore
      sendCandidate({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc.onIceConnectionState = (state) {
      print('PC iceConnectionState: $state');
    };

    pc.onAddStream = (stream) {
      print('PC onAddStream: stream=${stream.id} tracks=${stream.getTracks().length}');
    };

    pc.onTrack = (event) {
      print('PC onTrack: streams=${event.streams.length}');
    };

    // Add local stream tracks
    try {
      _localStream ??= await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'}
      });
      print('getUserMedia succeeded: audio=${_localStream?.getAudioTracks().length} video=${_localStream?.getVideoTracks().length}');
      await pc.addStream(_localStream!);
      // Also add individual tracks to ensure m= lines advertise send capability on all platforms.
      try {
        for (final track in _localStream!.getAudioTracks()) {
          pc.addTrack(track, _localStream!);
          print('Added audio track to PC');
        }
        for (final track in _localStream!.getVideoTracks()) {
          pc.addTrack(track, _localStream!);
          print('Added video track to PC');
        }
      } catch (e, st) {
        print('addTrack failed: $e\n$st');
      }
    } catch (e, st) {
      print('getUserMedia failed: $e\n$st');
      // if getUserMedia fails, still return pc; caller can handle UI
    }

    _pc = pc;
    return pc;
  }

  Future<void> startCall() async {
    final pc = await _createPeerConnection();

  final offer = await pc.createOffer();
  await pc.setLocalDescription(offer);
  print('Created offer: sdp length=${offer.sdp?.length} has_m=${offer.sdp?.contains('\nm=') ?? false}');
  await sendOffer({'sdp': offer.sdp, 'type': offer.type});
  }

  Future<void> _handleRemoteOffer(Map<String, dynamic> data) async {
    final pc = await _createPeerConnection();

    final sdp = data['sdp'] as String?;
    final type = data['type'] as String?;
    if (sdp == null || type == null) return;

    final desc = RTCSessionDescription(sdp, type);
    await pc.setRemoteDescription(desc);
    _remoteDescSet = true;

  // apply any queued remote candidates
  await _drainCandidateQueue();

  final answer = await pc.createAnswer();
  await pc.setLocalDescription(answer);
  print('Created answer: sdp length=${answer.sdp?.length} has_m=${answer.sdp?.contains('\nm=') ?? false}');

  await sendAnswer({'sdp': answer.sdp, 'type': answer.type});
  }

  Future<void> _handleRemoteAnswer(Map<String, dynamic> data) async {
    if (_pc == null) return;
    final sdp = data['sdp'] as String?;
    final type = data['type'] as String?;
    if (sdp == null || type == null) return;
    final desc = RTCSessionDescription(sdp, type);
    await _pc!.setRemoteDescription(desc);
    _remoteDescSet = true;
    await _drainCandidateQueue();
  }

  Future<void> _handleRemoteCandidate(Map<String, dynamic> data) async {
    final candidate = data['candidate'] as String?;
    final sdpMid = data['sdpMid'] as String?;
    final sdpMLineIndex = data['sdpMLineIndex'];
    if (candidate == null) return;

    final entry = <String, dynamic>{
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    };

    if (!_remoteDescSet || _pc == null) {
      _remoteCandidateQueue.add(entry);
      return;
    }

    final rtcCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex is int ? sdpMLineIndex : int.tryParse('$sdpMLineIndex'));
    await _pc!.addCandidate(rtcCandidate);
  }

  Future<void> _drainCandidateQueue() async {
    if (_pc == null) return;
    while (_remoteCandidateQueue.isNotEmpty) {
      final entry = _remoteCandidateQueue.removeAt(0);
      final rtcCandidate = RTCIceCandidate(entry['candidate'] as String?, entry['sdpMid'] as String?, entry['sdpMLineIndex'] is int ? entry['sdpMLineIndex'] as int : int.tryParse('${entry['sdpMLineIndex']}'));
      if (rtcCandidate.candidate != null) {
        await _pc!.addCandidate(rtcCandidate);
      }
    }
  }

  Future<void> sendOffer(Map<String, dynamic> sdp) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    await roomRef.collection('offer').doc('sdp').set({...sdp, 'senderId': localId, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> sendAnswer(Map<String, dynamic> sdp) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    await roomRef.collection('answer').doc('sdp').set({...sdp, 'senderId': localId, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> sendCandidate(Map<String, dynamic> candidate) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    await roomRef.collection('candidates').add({...candidate, 'senderId': localId, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> dispose() async {
    await _offerSub?.cancel();
    await _answerSub?.cancel();
    await _candidatesSub?.cancel();

    try {
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    _localStream = null;
  }
}
