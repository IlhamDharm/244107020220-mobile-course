import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'app_router.dart';
import 'notifications/push_service.dart';
import 'providers/auth_provider.dart';
import 'providers/push_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseError;
  PushService? pushService;
  String? initialRoute;
  if (kIsWeb) {
    firebaseError = 'FCM belum tersedia di Web tanpa FirebaseOptions. Jalankan aplikasi di Android untuk uji FCM.';
  } else {
    try {
      await Firebase.initializeApp();
      pushService = PushService();
      await pushService.initialize(onRoute: (route) => initialRoute = route);
    } on FirebaseException catch (error) {
      firebaseError =
          'Firebase belum siap (${error.code}). Periksa konfigurasi Android Firebase.';
      pushService?.dispose();
      pushService = null;
    } on PlatformException catch (error) {
      firebaseError =
          'Plugin notifikasi belum siap (${error.code}). Jalankan ulang aplikasi.';
      pushService?.dispose();
      pushService = null;
    }
  }

  final container = ProviderContainer(
    overrides: [
      pushServiceProvider.overrideWithValue(pushService),
      firebaseInitializationErrorProvider.overrideWithValue(firebaseError),
    ],
  );
  container.read(authStateProvider);
  final router = createAppRouter(container);
  if (initialRoute != null) router.go(initialRoute!);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: CampusNotifyApp(router: router),
    ),
  );
}

class CampusNotifyApp extends StatelessWidget {
  const CampusNotifyApp({required this.router, super.key});

  final RouterConfig<Object> router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7043C2),
          surface: const Color(0xFFFFF8FF),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
