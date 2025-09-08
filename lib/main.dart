import 'package:firebase_core/firebase_core.dart';
// removed firebase_auth for experiment simplicity; using a generated localId
import 'package:flutter/material.dart';

import 'ui/home_screen.dart';
import 'ui/call_screen.dart';
import 'signaling/firestore_signaling.dart';
import 'firebase_options.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // For this learning experiment we don't require Firebase Auth.
  // Generate a localId for signaling (non-persistent across app restarts).
  final localId = DateTime.now().millisecondsSinceEpoch.toString();
  runApp(MyApp(localId: localId));
}

class MyApp extends StatelessWidget {
  final String localId;

  const MyApp({Key? key, required this.localId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Video Call',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: navigatorKey,
      home: HomeScreen(onJoin: (roomId) {
        final signaling = FirestoreSignaling(roomId: roomId, localId: localId);
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => CallScreen(roomId: roomId, signaling: signaling)));
      }),
    );
  }
}
