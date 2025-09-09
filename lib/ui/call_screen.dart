import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../signaling/firestore_signaling.dart';

class CallScreen extends StatefulWidget {
  final String roomId;
  final FirestoreSignaling signaling;

  const CallScreen({Key? key, required this.roomId, required this.signaling}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // local stream is attached directly to the renderer; no separate field required
  @override
  void initState() {
    super.initState();
  _localRenderer.initialize();
  _remoteRenderer.initialize();
    widget.signaling.onOffer = (offer) {
      // placeholder: handle incoming offer
      debugPrint('Received offer: $offer');
    };
    widget.signaling.onAnswer = (answer) {
      debugPrint('Received answer: $answer');
    };
    widget.signaling.onCandidate = (candidate) {
      debugPrint('Received candidate: $candidate');
    };
    widget.signaling.join();

    widget.signaling.onLocalStream = (stream) {
      _localRenderer.srcObject = stream;
      setState(() {});
    };

    widget.signaling.onRemoteStream = (stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    };
  }

  @override
  void dispose() {
  widget.signaling.dispose();
  _localRenderer.dispose();
  _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room: ${widget.roomId}')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black12,
                    child: RTCVideoView(_localRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.black26,
                    child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    await _ensurePermissionsAndStart();
                  },
                  icon: const Icon(Icons.mic),
                ),
                const SizedBox(width: 16),
                IconButton(onPressed: () {}, icon: const Icon(Icons.videocam)),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hang up')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await _ensurePermissionsAndStart();
                  },
                  child: const Text('Start call'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _ensurePermissionsAndStart() async {
    try {
      // Trigger permission prompt by requesting a short getUserMedia stream.
      final tmp = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
      // Immediately stop tracks; actual signaling will re-acquire or reuse via FirestoreSignaling.
      for (final t in tmp.getTracks()) {
        t.stop();
      }
      await widget.signaling.startCall();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer created and sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permission denied or error: $e')));
    }
  }
}
