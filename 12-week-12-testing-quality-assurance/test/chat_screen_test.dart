import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/ai/ai_service.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/features/chat_screen.dart';

class MockAiService extends AiService {
  MockAiService({this.responseToReturn, this.shouldThrow = false});

  final String? responseToReturn;
  final bool shouldThrow;

  @override
  Future<String> ask(String question) async {
    if (shouldThrow) {
      throw Exception('Jaringan terputus / Timeout');
    }
    return responseToReturn ?? 'Jawaban mock dari AI';
  }

  @override
  Future<String?> getApiKey() async => 'dummy-api-key';

  @override
  Future<bool> hasApiKey() async => true;
}

void main() {
  group('ChatScreen Widget Tests', () {
    testWidgets('menampilkan pesan sambutan awal dari AI Assistant', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiServiceProvider.overrideWithValue(MockAiService())],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      expect(find.text('Campus AI Assistant'), findsOneWidget);
      expect(
        find.textContaining('Halo! Saya Campus AI Assistant'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('mengirim pesan dan menampilkan respon AI', (tester) async {
      final mockService = MockAiService(
        responseToReturn: 'Gunakan Clean Architecture untuk kode yang rapi.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiServiceProvider.overrideWithValue(mockService)],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );

      // Ketik pertanyaan
      await tester.enterText(
        find.byType(TextField),
        'Bagaimana tips arsitektur Flutter?',
      );
      await tester.tap(find.byIcon(Icons.send));

      // Pump frame untuk state update
      await tester.pump();

      // User bubble tampil
      expect(find.text('Bagaimana tips arsitektur Flutter?'), findsOneWidget);

      // Selesaikan async ask()
      await tester.pumpAndSettle();

      // Respons AI tampil
      expect(
        find.text('Gunakan Clean Architecture untuk kode yang rapi.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'menampilkan dialog fallback saat layanan AI sibuk atau terjadi error',
      (tester) async {
        final mockFailingService = MockAiService(shouldThrow: true);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              aiServiceProvider.overrideWithValue(mockFailingService),
            ],
            child: const MaterialApp(home: ChatScreen()),
          ),
        );

        // Ketik pertanyaan dan kirim
        await tester.enterText(find.byType(TextField), 'Halo error');
        await tester.tap(find.byIcon(Icons.send));

        await tester.pumpAndSettle();

        // Dialog Fallback sesuai Langkah 5 modul
        expect(find.text('Layanan AI Sibuk'), findsOneWidget);
        expect(
          find.text('Coba lagi nanti atau gunakan mode offline.'),
          findsOneWidget,
        );

        // Tekan tombol tutup
        await tester.tap(find.text('Tutup'));
        await tester.pumpAndSettle();

        expect(find.text('Layanan AI Sibuk'), findsNothing);
      },
    );
  });
}
