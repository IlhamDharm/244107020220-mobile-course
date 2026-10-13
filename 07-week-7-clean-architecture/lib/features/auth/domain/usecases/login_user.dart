import '../repositories/auth_repository.dart';

class LoginUser {
  const LoginUser(this._repository);

  final AuthRepository _repository;

  Future<AuthSessionResult> call({
    required String email,
    required String password,
    bool simulateExpiredRefresh = false,
  }) {
    return _repository.login(
      email: email,
      password: password,
      simulateExpiredRefresh: simulateExpiredRefresh,
    );
  }
}
