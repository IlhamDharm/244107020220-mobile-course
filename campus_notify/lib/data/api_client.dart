import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_store.dart';

class AuthInterceptor extends Interceptor {
  factory AuthInterceptor({
    required Dio dio,
    required TokenStore tokenStore,
    required AuthRepository authRepository,
    required Future<void> Function() onSessionExpired,
  }) => AuthInterceptor._(
    dio: dio,
    tokenStore: tokenStore,
    authRepository: authRepository,
    onSessionExpired: onSessionExpired,
  );

  AuthInterceptor._({
    required this._dio,
    required this._tokenStore,
    required this._authRepository,
    required this._onSessionExpired,
  });

  final Dio _dio;
  final TokenStore _tokenStore;
  final AuthRepository _authRepository;
  final Future<void> Function() _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final access = await _tokenStore.readAccess();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        request.extra['authRetried'] != true &&
        request.path != '/auth/refresh';
    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final refresh = await _tokenStore.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      await _expireSession(err, handler);
      return;
    }

    try {
      final renewedAccess = await _authRepository.refresh(refresh);
      await _tokenStore.save(access: renewedAccess, refresh: refresh);
      final retryRequest = request.copyWith(
        headers: {...request.headers, 'Authorization': 'Bearer $renewedAccess'},
        extra: {...request.extra, 'authRetried': true},
      );
      final response = await _dio.fetch<dynamic>(retryRequest);
      handler.resolve(response);
    } on AuthSessionExpiredException {
      await _expireSession(err, handler);
    } on DioException catch (refreshOrRetryError) {
      if (refreshOrRetryError.response?.statusCode == 401) {
        await _expireSession(refreshOrRetryError, handler);
      } else {
        handler.next(refreshOrRetryError);
      }
    }
  }

  Future<void> _expireSession(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    await _tokenStore.clear();
    await _onSessionExpired();
    handler.next(error);
  }
}

Dio buildDemoApiClient({
  required TokenStore tokenStore,
  required AuthRepository authRepository,
  required Future<void> Function() onSessionExpired,
  HttpClientAdapter? adapter,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://campus-notify-demo.invalid',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStore: tokenStore,
      authRepository: authRepository,
      onSessionExpired: onSessionExpired,
    ),
  );
  return dio;
}

class DemoApiAdapter implements HttpClientAdapter {
  int requestCount = 0;
  final authorizationHeaders = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    final authorization = options.headers['Authorization'] as String? ?? '';
    authorizationHeaders.add(authorization);
    if (authorization.startsWith('Bearer mock-access-renewed-')) {
      return ResponseBody.fromString(
        '{"ok":true,"message":"Request berhasil setelah refresh token."}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      '{"message":"Access token kedaluwarsa."}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
