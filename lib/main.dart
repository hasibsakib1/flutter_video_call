import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ui/home_screen.dart';
import 'ui/call_screen.dart';
import 'signaling/firestore_signaling.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Anonymous sign-in for stable uid
  final user = FirebaseAuth.instance.currentUser ?? (await FirebaseAuth.instance.signInAnonymously()).user;

  runApp(MyApp(localId: user?.uid ?? 'unknown'));
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
