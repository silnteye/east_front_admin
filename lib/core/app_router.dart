import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/create_post_screen.dart';
import '../screens/admin/post_detail_screen.dart';
import '../screens/admin/book_subcategories_screen.dart';
import '../screens/admin/categories_screen.dart';
import '../screens/admin/category_stats_screen.dart';
import '../screens/admin/users_screen.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      notifyListeners();
    });
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: RouterNotifier(),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = AuthSession.isAdminLoggedIn && user != null;
    final isLoggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn) {
      return isLoggingIn ? null : '/login';
    }

    if (isLoggingIn || state.matchedLocation == '/') {
      return '/admin';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/admin'),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
    GoRoute(path: '/admin/create', builder: (context, state) => const CreatePostScreen()),
    GoRoute(
      path: '/admin/edit',
      builder: (context, state) => CreatePostScreen(post: state.extra as dynamic),
    ),
    GoRoute(
      path: '/admin/post',
      builder: (context, state) => PostDetailScreen(post: state.extra as dynamic),
    ),
    GoRoute(
      path: '/admin/book_subcategories',
      builder: (context, state) => const BookSubcategoriesScreen(),
    ),
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/admin/stats',
      builder: (context, state) => const CategoryStatsScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const UsersScreen(),
    ),
  ],
);
