import 'package:campus_notify/app_router.dart';
import 'package:campus_notify/data/token_store.dart';
import 'package:campus_notify/main.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenStore implements TokenStore {
  String? access;
  String? refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }
}

void main() {
  testWidgets('unauthenticated user logs in and is routed to the home page', (
    tester,
  ) async {
    final store = _FakeTokenStore();
    final container = ProviderContainer(
      overrides: [tokenStoreProvider.overrideWithValue(store)],
    );
    await container.read(authStateProvider.future);
    final router = createAppRouter(container);
    addTearDown(() {
      router.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: CampusNotifyApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Campus Notify'), findsOneWidget);
    expect(find.text('Masuk untuk menerima pengumuman kampus'), findsOneWidget);
    expect(find.byKey(const Key('login-submit')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'mahasiswa@kampus.test',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'praktikum123',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.byKey(const Key('request-fcm-permission')), findsOneWidget);
    expect(store.access, startsWith('mock-access-'));
    expect(store.refresh, startsWith('mock-refresh-'));
  });

  testWidgets('authenticated deep link opens its announcement route', (
    tester,
  ) async {
    final store = _FakeTokenStore()
      ..access = 'mock-access'
      ..refresh = 'mock-refresh';
    final container = ProviderContainer(
      overrides: [tokenStoreProvider.overrideWithValue(store)],
    );
    await container.read(authStateProvider.future);
    final router = createAppRouter(container)..go('/pengumuman/3');
    addTearDown(() {
      router.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: CampusNotifyApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('announcement-detail')), findsOneWidget);
    expect(find.text('Pengumuman #3'), findsOneWidget);
  });
}
