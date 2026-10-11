import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/announcement_page.dart';
import 'providers/auth_provider.dart';
import 'routes.dart';

class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(ProviderContainer container) {
    _subscription = container.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }

  late final ProviderSubscription<AsyncValue<bool>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

GoRouter createAppRouter(ProviderContainer container) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: AuthRouterRefresh(container),
    redirect: (context, state) {
      final auth = container.read(authStateProvider);
      if (auth.isLoading) return null;

      final signedIn = auth.value ?? false;
      final goingToLogin = state.matchedLocation == AppRoutes.login;
      if (!signedIn && !goingToLogin) return AppRoutes.login;
      if (signedIn && goingToLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (context, state) => AnnouncementPage(
          id: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );
}
