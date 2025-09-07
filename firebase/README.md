# Firebase local setup (Emulator)

This project uses Firestore as the default signaling transport for experiments.
Use the Firebase Emulator Suite to develop locally without touching production.

1. Ensure Firebase CLI is installed and you're logged in:

```bash
firebase login
```

2. Initialize emulator for firestore and auth (if not already done):

```bash
firebase init emulators
# select Firestore and Auth emulators
```

3. Start emulators:

```bash
firebase emulators:start --only firestore,auth
```

4. Use `firebase.json` and `.firebaserc` created by `firebase init` for config.

5. In your Flutter app, sign in anonymously and use the Firestore endpoint.

Notes:
- Use the Firestore emulator during development and tests to avoid billing.
- For auth, enable anonymous sign-in in the Firebase console if you plan to
  use production later.
