import '../features/auth/data/repositories/mock_auth_repository.dart';

export '../features/auth/domain/repositories/auth_repository.dart';
export '../features/auth/domain/entities/auth_session.dart';
export '../features/auth/data/repositories/mock_auth_repository.dart'
    show MockAuthRepository;

class AuthSessionExpiredException implements Exception {
  const AuthSessionExpiredException();
}

typedef AuthRepository = MockAuthRepository;
