import '../repositories/auth_repository.dart';

class RefreshAccessToken {
  const RefreshAccessToken(this._repository);

  final AuthRepository _repository;

  Future<AccessTokenResult> call(String refreshToken) {
    return _repository.refresh(refreshToken);
  }
}
