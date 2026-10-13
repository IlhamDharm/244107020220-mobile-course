import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

final apiClientProvider = Provider<Dio>((ref) {
  return buildDemoApiClient(
    tokenStore: ref.read(tokenStoreProvider),
    authRepository: ref.read(authRepositoryProvider),
    onSessionExpired: ref.read(authStateProvider.notifier).logout,
    adapter: DemoApiAdapter(),
  );
});
