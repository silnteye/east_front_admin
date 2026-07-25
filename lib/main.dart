import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "firebase_options.dart";
import "core/app_router.dart";
import "services/auth_service.dart";
import "services/settings_provider.dart";
import "services/theme_provider.dart";
import "services/firestore_service.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthSession.init();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await FirestoreService.instance.initializeDefaultCategories();

  // runApp(
  //   DevicePreview(
  //       enabled: !kReleaseMode,
  //       builder: (context) => const ProviderScope(child: AdminApp()) // Wrap your app
  //   ),
  // );
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeProvider);
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: "East Front Admin",
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontSize.scaleFactor),
          ),
          child: child!,
        );
      },
      theme: selectedTheme.getThemeData(),
      routerConfig: appRouter,
    );
  }
}
