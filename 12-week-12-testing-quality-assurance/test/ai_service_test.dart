import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:week5_offline_notes/ai/ai_service.dart';

class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this._handler);
  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('AiService Tests', () {
    late Map<String, String> inMemoryStorage;

    setUp(() {
      inMemoryStorage = {};
    });

    test('ask() melempar exception saat API key belum diatur', () async {
      final service = AiService(
        readStorage: ({required key}) async => inMemoryStorage[key],
        writeStorage: ({required key, required value}) async =>
            inMemoryStorage[key] = value ?? '',
      );

      expect(
        () => service.ask('Halo AI'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API key tidak tersedia'),
          ),
        ),
      );
    });

    test(
      'saveApiKey() dan getApiKey() menyimpan dan mengambil key dengan benar',
      () async {
        final service = AiService(
          readStorage: ({required key}) async => inMemoryStorage[key],
          writeStorage: ({required key, required value}) async =>
              inMemoryStorage[key] = value ?? '',
        );

        expect(await service.hasApiKey(), isFalse);
        await service.saveApiKey('test-gemini-key-123');

        expect(await service.hasApiKey(), isTrue);
        expect(await service.getApiKey(), equals('test-gemini-key-123'));
      },
    );

    test('ask() sukses mengurai respon JSON dari Gemini API', () async {
      final fakeClient = FakeHttpClient((request) async {
        expect(request.url.queryParameters['key'], equals('secret-key'));
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Ini adalah jawaban dari Gemini AI.'},
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      inMemoryStorage['ai_api_key'] = 'secret-key';

      final service = AiService(
        client: fakeClient,
        readStorage: ({required key}) async => inMemoryStorage[key],
        writeStorage: ({required key, required value}) async =>
            inMemoryStorage[key] = value ?? '',
      );

      final result = await service.ask('Jelaskan Clean Architecture');
      expect(result, equals('Ini adalah jawaban dari Gemini AI.'));
    });

    test(
      'ask() melempar exception saat server Gemini mengembalikan HTTP error',
      () async {
        final fakeClient = FakeHttpClient((request) async {
          return http.Response('Rate limit exceeded', 429);
        });

        inMemoryStorage['ai_api_key'] = 'secret-key';

        final service = AiService(
          client: fakeClient,
          readStorage: ({required key}) async => inMemoryStorage[key],
          writeStorage: ({required key, required value}) async =>
              inMemoryStorage[key] = value ?? '',
        );

        expect(
          () => service.ask('Pertanyaan saya'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Gagal memanggil AI API: 429'),
            ),
          ),
        );
      },
    );

    test(
      'ask() sukses mengurai respon dari 9Router (OpenAI-compatible format)',
      () async {
        final fakeClient = FakeHttpClient((request) async {
          expect(request.url.path, contains('/chat/completions'));
          expect(
            request.headers['authorization'],
            equals('Bearer 9router-key'),
          );
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'Jawaban cerdas dari 9Router gateway.',
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        inMemoryStorage['ai_provider'] = '9router';
        inMemoryStorage['ai_api_key'] = '9router-key';
        inMemoryStorage['ai_base_url'] = 'http://localhost:20128/v1';
        inMemoryStorage['ai_model'] = 'gpt-4o-mini';

        final service = AiService(
          client: fakeClient,
          readStorage: ({required key}) async => inMemoryStorage[key],
          writeStorage: ({required key, required value}) async =>
              inMemoryStorage[key] = value ?? '',
        );

        final result = await service.ask('Halo 9Router');
        expect(result, equals('Jawaban cerdas dari 9Router gateway.'));
      },
    );

    test(
      'ask() sukses mengurai respon dari 9Router (OpenAI-compatible format)',
      () async {
        final fakeClient = FakeHttpClient((request) async {
          expect(request.url.path, contains('/chat/completions'));
          expect(
            request.headers['authorization'],
            equals('Bearer 9router-key'),
          );
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'role': 'assistant',
                    'content': 'Jawaban cerdas dari 9Router gateway.',
                  },
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        inMemoryStorage['ai_provider'] = '9router';
        inMemoryStorage['ai_api_key'] = '9router-key';
        inMemoryStorage['ai_base_url'] = 'http://localhost:20128/v1';
        inMemoryStorage['ai_model'] = 'gpt-4o-mini';

        final service = AiService(
          client: fakeClient,
          readStorage: ({required key}) async => inMemoryStorage[key],
          writeStorage: ({required key, required value}) async =>
              inMemoryStorage[key] = value ?? '',
        );

        final result = await service.ask('Halo 9Router');
        expect(result, equals('Jawaban cerdas dari 9Router gateway.'));
      },
    );
  });
}
