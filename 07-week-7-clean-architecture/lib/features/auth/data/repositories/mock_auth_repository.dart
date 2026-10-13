import '../../../../core/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_session_model.dart';

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<AuthSessionResult> login({
    required String email,
    required String password,
    bool simulateExpiredRefresh = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!email.contains('@') || password.length < 6) {
      return (
        session: null,
        failure: const AuthFailure('Email atau kata sandi tidak valid.'),
      );
    }

    final suffix = DateTime.now().microsecondsSinceEpoch;
    final session = AuthSessionModel(
      access: 'mock-access-$suffix',
      refresh: simulateExpiredRefresh ? '' : 'mock-refresh-$suffix',
    );
    return (session: session.toEntity(), failure: null);
  }

  @override
  Future<AccessTokenResult> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (refreshToken.isEmpty) {
      return (
        accessToken: null,
        failure: const AuthFailure('Refresh token hilang atau kedaluwarsa.'),
      );
    }
    return (
      accessToken:
          'mock-access-renewed-${DateTime.now().microsecondsSinceEpoch}',
      failure: null,
    );
  }
}
