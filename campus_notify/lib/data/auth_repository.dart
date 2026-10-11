 class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

class AuthSessionExpiredException implements Exception {
  const AuthSessionExpiredException();
}

class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
    bool simulateExpiredRefresh = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!email.contains('@') || password.length < 6) {
      throw const FormatException('Email atau kata sandi tidak valid.');
    }

    final suffix = DateTime.now().microsecondsSinceEpoch;
    return AuthSession(
      access: 'mock-access-$suffix',
      refresh: simulateExpiredRefresh ? '' : 'mock-refresh-$suffix',
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (refreshToken.isEmpty) {
      throw const AuthSessionExpiredException();
    }
    return 'mock-access-renewed-${DateTime.now().microsecondsSinceEpoch}';
  }
}
