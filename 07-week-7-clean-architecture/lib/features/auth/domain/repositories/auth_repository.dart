import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

typedef AuthSessionResult = ({AuthSession? session, Failure? failure});
typedef AccessTokenResult = ({String? accessToken, Failure? failure});

abstract interface class AuthRepository {
  Future<AuthSessionResult> login({
    required String email,
    required String password,
    bool simulateExpiredRefresh = false,
  });

  Future<AccessTokenResult> refresh(String refreshToken);
}
