import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'temp_firebase_options.dart'; // Temporary for testing
import 'core/constants/app_constants.dart';
import 'core/utils/hive_bootstrap.dart';
import 'shared/presentation/theme/app_theme.dart';
import 'core/utils/notification_service.dart';
import 'shared/presentation/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with better error handling
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: TempFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } else {
      print('⚠️ Firebase already initialized');
    }
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    // Continue execution even if Firebase fails to initialize
    // This allows the app to run for testing purposes
  }

  // Initialize Hive
  await HiveBootstrap.initAndOpen();

  // Initialize local notifications (no-op on web)
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: DepositsApp(),
    ),
  );
}

class DepositsApp extends ConsumerWidget {
  const DepositsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
