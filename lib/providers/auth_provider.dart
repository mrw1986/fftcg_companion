import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FFTCGAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Guest mode implementation
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Will expand with more authentication methods
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
