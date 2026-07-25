import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "dart:async";
import "package:shared_preferences/shared_preferences.dart";
import "../services/auth_service.dart";
import "../services/firestore_service.dart";
import "../models/post_model.dart";

final authStreamProvider = StreamProvider<User?>((ref) {
  return AuthService.instance.userStream;
});

final userRoleProvider = StreamProvider<String>((ref) {
  final userAsync = ref.watch(authStreamProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value("user");
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data()?['role'] as String? ?? 'user');
});

final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirestoreService.instance.getPosts();
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', false);
    } else {
      state = ThemeMode.dark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', true);
    }
  }
}

// --- Categories ---
final categoriesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirestoreService.instance.getCategories();
});

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void setCategory(String category) => state = category;
}
final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

// --- Presence & Active Users ---
final presenceProvider = Provider<void>((ref) {
  final authState = ref.watch(authStreamProvider);
  final user = authState.value;
  if (user == null) return;

  // Update presence immediately
  _updatePresence(user.uid);

  // Periodic timer to update presence every 60 seconds
  final timer = Timer.periodic(const Duration(seconds: 60), (_) {
    _updatePresence(user.uid);
  });

  ref.onDispose(() {
    timer.cancel();
  });
});

void _updatePresence(String uid) {
  FirebaseFirestore.instance.collection('users').doc(uid).set({
    'lastActive': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

final activeUsersCountProvider = StreamProvider<int>((ref) async* {
  while (true) {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 3));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('lastActive', isGreaterThan: cutoff)
          .get();
      yield snap.docs.length;
    } catch (_) {
      yield 0;
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});

