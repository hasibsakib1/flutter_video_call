import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final void Function(String roomId) onJoin;

  const HomeScreen({Key? key, required this.onJoin}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Video Call')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Room ID'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => widget.onJoin(_controller.text.trim()),
                  child: const Text('Join'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    _controller.text = id;
                    widget.onJoin(id);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
