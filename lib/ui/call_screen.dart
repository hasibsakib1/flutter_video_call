import 'package:flutter/material.dart';
import '../signaling/firestore_signaling.dart';

class CallScreen extends StatefulWidget {
  final String roomId;
  final FirestoreSignaling signaling;

  const CallScreen({Key? key, required this.roomId, required this.signaling}) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    widget.signaling.dispose();
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
                    child: const Center(child: Text('Local preview')),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(child: Text('Remote video')),
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
                    // Start an outbound call (create & send offer)
                    try {
                      await widget.signaling.startCall();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer created and sent')));
                    } catch (e, st) {
                      // ignore: avoid_print
                      print('startCall failed: $e\n$st');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create offer: $e')));
                    }
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
                    try {
                      await widget.signaling.startCall();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer created and sent')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create offer: $e')));
                    }
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
}
