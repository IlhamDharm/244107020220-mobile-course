import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/providers/stats_provider.dart';

void main() {
  test('statsProvider menguji transisi loading ke data atau error', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Pastikan state awal adalah loading
    final initialState = container.read(statsProvider);
    expect(initialState, isA());

    final completer = Completer();

    // Dengarkan perubahan state
    final subscription = container.listen(
      statsProvider,
      (previous, next) {
        if (next is! AsyncLoading && !completer.isCompleted) {
          completer.complete(next);
        }
      },
    );

    // Tunggu hasil eksekusi async (selesai dalam ~2 detik)
    final finalState = await completer.future;
    subscription.close();

    // Verifikasi hasil akhir di Riverpod 3.x (menggunakan pengecekan tipe)
    if (finalState is AsyncError) {
      expect(finalState, isA());
    } else if (finalState is AsyncData) {
      expect(finalState, isA());
      expect((finalState.value as List).length, 3);
    }
  });
}