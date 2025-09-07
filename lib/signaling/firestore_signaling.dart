import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal Firestore-based signaling helper.
/// Usage (high level):
/// 1) Sign in (anonymous) and call `Signaling.joinRoom(roomId, uid)`
/// 2) Use `onOffer/onAnswer/onCandidate` callbacks to hook into RTCPeerConnection
class FirestoreSignaling {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String roomId;
  final String localId;

  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _candidatesSub;

  void Function(Map<String, dynamic> offer)? onOffer;
  void Function(Map<String, dynamic> answer)? onAnswer;
  void Function(Map<String, dynamic> candidate)? onCandidate;

  FirestoreSignaling({required this.roomId, required this.localId});

  Future<void> join() async {
    final roomRef = _db.collection('rooms').doc(roomId);

    // ensure room exists
    await roomRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    // subscribe to offer/answer/candidates
    _offerSub = roomRef.collection('offer').doc('sdp').snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        if (data != null && data['senderId'] != localId) onOffer?.call(data);
      }
    });

    _answerSub = roomRef.collection('answer').doc('sdp').snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>?;
        if (data != null && data['senderId'] != localId) onAnswer?.call(data);
      }
    });

    _candidatesSub = roomRef.collection('candidates').snapshots().listen((snaps) {
      for (final doc in snaps.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data() as Map<String, dynamic>?;
          if (data != null && data['senderId'] != localId) onCandidate?.call(data);
        }
      }
    });
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
  }
}
