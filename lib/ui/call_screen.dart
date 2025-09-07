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
                IconButton(onPressed: () {}, icon: const Icon(Icons.mic)),
                const SizedBox(width: 16),
                IconButton(onPressed: () {}, icon: const Icon(Icons.videocam)),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hang up')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
