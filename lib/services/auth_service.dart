import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class AuthSession {
  static bool isAdminLoggedIn = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isAdminLoggedIn = prefs.getBool('is_admin_logged_in') ?? false;
  }

  static Future<void> setLoggedIn(bool loggedIn) async {
    isAdminLoggedIn = loggedIn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged_in', loggedIn);
  }
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();

  Future<void> initializeAnonymousUser() async {
    try {
      if (_auth.currentUser != null) return;
      final cred = await _auth.signInAnonymously();
      try {
        await FirestoreService.instance.createUserIfNotExists(uid: cred.user!.uid);
      } catch (e) {
        print("Error creating user document: $e");
      }
    } catch (e) {
      print("Error signing in anonymously: $e");
    }
  }

  Future<UserCredential> adminLogin({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;

    final usersCollection = FirebaseFirestore.instance.collection('users');

    // 1. Check if any admins/super_admins exist in the database yet
    final adminsQuery = await usersCollection
        .where('role', whereIn: ['admin', 'super_admin'])
        .limit(1)
        .get();

    if (adminsQuery.docs.isEmpty) {
      // Bootstrap the very first login as super_admin
      await usersCollection.doc(uid).set({
        'uid': uid,
        'email': email,
        'role': 'super_admin',
        'isActive': true,
        'isAnonymous': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await AuthSession.setLoggedIn(true);
      return cred;
    }

    // 2. Fetch logging-in user's role from Firestore
    final doc = await usersCollection.doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      await AuthSession.setLoggedIn(false);
      throw "Access Denied: User account not found in Database.";
    }

    final role = doc.data()?['role'] as String? ?? 'user';
    if (role != 'admin' && role != 'super_admin') {
      await _auth.signOut();
      await AuthSession.setLoggedIn(false);
      throw "Access Denied: This is a normal user account. Admins must use their own dedicated admin emails.";
    }

    await AuthSession.setLoggedIn(true);
    return cred;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await AuthSession.setLoggedIn(false);
  }
}
