import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/token_store.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/refresh_access_token.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => const MockAuthRepository(),
);

final loginUserProvider = Provider<LoginUser>(
  (ref) => LoginUser(ref.watch(authRepositoryProvider)),
);

final refreshAccessTokenProvider = Provider<RefreshAccessToken>(
  (ref) => RefreshAccessToken(ref.watch(authRepositoryProvider)),
);

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.read(tokenStoreProvider).readAccess();
    return token != null && token.isNotEmpty;
  }

  Future<void> login(
    String email,
    String password, {
    bool simulateExpiredRefresh = false,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(loginUserProvider)
          .call(
            email: email,
            password: password,
            simulateExpiredRefresh: simulateExpiredRefresh,
          );
      final failure = result.failure;
      final session = result.session;
      if (failure != null || session == null) {
        throw Exception(failure?.message ?? 'Login gagal.');
      }
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    state = const AsyncData(false);
  }
}
