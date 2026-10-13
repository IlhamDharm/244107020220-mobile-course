import '../../domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.access, required super.refresh});

  Map<String, Object?> toMap() => {'access': access, 'refresh': refresh};

  factory AuthSessionModel.fromMap(Map<String, Object?> map) {
    return AuthSessionModel(
      access: map['access'] as String? ?? '',
      refresh: map['refresh'] as String? ?? '',
    );
  }

  AuthSession toEntity() => AuthSession(access: access, refresh: refresh);
}
