import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/notifications/route_from_message.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStore implements TokenStore {
  String? access;
  String? refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

void main() {
  group('routeFromMessage', () {
    test('normalizes an empty route and routes without a leading slash', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('keeps announcement id in the data payload', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};

      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });

    test('uses home route for a non-string route payload', () {
      expect(routeFromMessage({'route': 3}), '/');
    });
  });

  group('secure token flow', () {
    test('auth provider reads stored access token', () async {
      final store = FakeTokenStore()..access = 'mock-access';
      final container = ProviderContainer(
        overrides: [tokenStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(await container.read(authStateProvider.future), isTrue);
    });

    test('mock login stores both tokens in the token store', () async {
      final store = FakeTokenStore();
      final container = ProviderContainer(
        overrides: [tokenStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container
          .read(authStateProvider.notifier)
          .login('mahasiswa@kampus.test', 'praktikum123');

      expect(container.read(authStateProvider).requireValue, isTrue);
      expect(store.access, startsWith('mock-access-'));
      expect(store.refresh, startsWith('mock-refresh-'));
    });

    test('logout clears both tokens and updates auth state', () async {
      final store = FakeTokenStore()
        ..access = 'mock-access'
        ..refresh = 'mock-refresh';
      final container = ProviderContainer(
        overrides: [tokenStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).logout();

      expect(container.read(authStateProvider).requireValue, isFalse);
      expect(store.access, isNull);
      expect(store.refresh, isNull);
    });
  });

  group('Dio 401 refresh', () {
    test('refreshes once and retries the original request', () async {
      final store = FakeTokenStore()
        ..access = 'mock-access-old'
        ..refresh = 'mock-refresh-valid';
      final adapter = DemoApiAdapter();
      var sessionExpired = false;
      final dio = buildDemoApiClient(
        tokenStore: store,
        authRepository: AuthRepository(),
        onSessionExpired: () async => sessionExpired = true,
        adapter: adapter,
      );
      addTearDown(dio.close);

      final response = await dio.get<Map<String, dynamic>>('/protected');

      expect(response.statusCode, 200);
      expect(response.data?['ok'], isTrue);
      expect(adapter.requestCount, 2);
      expect(
        adapter.authorizationHeaders.first,
        'Bearer mock-access-old',
      );
      expect(
        adapter.authorizationHeaders.last,
        startsWith('Bearer mock-access-renewed-'),
      );
      expect(store.access, startsWith('mock-access-renewed-'));
      expect(sessionExpired, isFalse);
    });

    test('expired refresh clears the session and triggers logout callback',
        () async {
      final store = FakeTokenStore()
        ..access = 'mock-access-old'
        ..refresh = '';
      final adapter = DemoApiAdapter();
      var sessionExpired = false;
      final dio = buildDemoApiClient(
        tokenStore: store,
        authRepository: AuthRepository(),
        onSessionExpired: () async => sessionExpired = true,
        adapter: adapter,
      );
      addTearDown(dio.close);

      await expectLater(
        dio.get<Map<String, dynamic>>('/protected'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requestCount, 1);
      expect(store.access, isNull);
      expect(store.refresh, isNull);
      expect(sessionExpired, isTrue);
    });
  });
}
