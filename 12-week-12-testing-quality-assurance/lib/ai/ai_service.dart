import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Service to communicate with AI APIs securely.
///
/// Supports both:
/// 1. Google Gemini API (native REST endpoint)
/// 2. 9Router / OpenAI-compatible API Gateways (local or remote LLM router)
class AiService {
  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    this.apiUrl,
    this.readStorage,
    this.writeStorage,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _client = client ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String? apiUrl;
  final Future<String?> Function({required String key})? readStorage;
  final Future<void> Function({required String key, required String? value})?
  writeStorage;

  static const String _storageKey = 'ai_api_key';
  static const String _providerKey = 'ai_provider';
  static const String _baseUrlKey = 'ai_base_url';
  static const String _modelKey = 'ai_model';

  /// List of Gemini models to try in priority order to prevent 404s on retired models.
  static const List<String> _geminiModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash',
    'gemini-pro',
  ];

  /// List of active 9Router models (combos and codex models from 9Router catalog).
  static const List<String> _default9RouterModels = [
    'combo1',
    'cx/gpt-6-luna',
    'combo2',
    'gh/gpt-4o-mini',
  ];

  /// Sends a prompt [question] to the configured AI API (Gemini or 9Router) and returns the generated text.
  Future<String> ask(String question) async {
    final provider = await getProvider();
    if (provider == '9router') {
      return _ask9Router(question);
    }
    return _askGemini(question);
  }

  /// Communicates with 9Router or any OpenAI-compatible API gateway.
  Future<String> _ask9Router(String question) async {
    final apiKey = (await getApiKey())?.trim() ?? '';
    final rawBaseUrl = (await getBaseUrl())?.trim();
    final baseUrl = (rawBaseUrl != null && rawBaseUrl.isNotEmpty)
        ? rawBaseUrl
        : 'http://localhost:20128/v1';

    final rawModel = (await getModel())?.trim();
    final candidateModels = [
      if (rawModel != null && rawModel.isNotEmpty) rawModel,
      ..._default9RouterModels,
    ];

    final endpoint = baseUrl.endsWith('/')
        ? '${baseUrl}chat/completions'
        : '$baseUrl/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };

    String lastError = '';

    for (final model in candidateModels) {
      final bodyMap = <String, dynamic>{
        'model': model,
        'messages': [
          {'role': 'user', 'content': question},
        ],
      };

      final response = await _client.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          throw Exception('9Router tidak menghasilkan jawaban.');
        }
        final message = choices[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content == null || content.isEmpty) {
          throw Exception('Konten respon 9Router kosong.');
        }
        return content;
      }

      // If specific model is not found or has no credentials, cascade to next candidate model
      if (response.statusCode == 404 ||
          response.body.contains('No active credentials') ||
          response.body.contains('model_not_found') ||
          response.body.contains('Missing model')) {
        lastError = response.body;
        continue;
      }

      throw Exception(
        'Gagal memanggil 9Router (${response.statusCode}): ${response.body}',
      );
    }

    throw Exception('Gagal memanggil 9Router: $lastError');
  }

  /// Communicates with Google Gemini API directly.
  Future<String> _askGemini(String question) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan AI.');
    }

    final cleanKey = apiKey.trim();

    // If explicit apiUrl was provided in constructor (e.g. for testing), use that
    final customUrl = apiUrl;
    if (customUrl != null) {
      return _callGeminiEndpoint(customUrl, cleanKey, question);
    }

    // Try active models sequentially to prevent 404 deprecated model errors
    String lastError = '';
    for (final model in _geminiModels) {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
      try {
        return await _callGeminiEndpoint(url, cleanKey, question);
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('404')) {
          lastError = 'Model $model tidak tersedia (404).';
          continue;
        }
        rethrow;
      }
    }

    throw Exception('Gagal memanggil Gemini API: $lastError');
  }

  Future<String> _callGeminiEndpoint(
    String baseUrl,
    String apiKey,
    String question,
  ) async {
    final uri = Uri.parse('$baseUrl?key=$apiKey');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': question},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('AI tidak menghasilkan jawaban.');
      }
      final parts = candidates[0]['content']['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Format respon AI kosong.');
      }
      return parts[0]['text'] as String;
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  /// Securely stores the API key in encrypted storage.
  Future<void> saveApiKey(String key) async {
    await _write(_storageKey, key.trim());
  }

  /// Retrieves the stored API key.
  Future<String?> getApiKey() async {
    return _read(_storageKey);
  }

  /// Checks if an API key is currently saved.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Gets the currently selected AI provider ('gemini' or '9router').
  Future<String> getProvider() async {
    final provider = await _read(_providerKey);
    return provider ?? 'gemini';
  }

  /// Saves the selected AI provider.
  Future<void> saveProvider(String provider) async {
    await _write(_providerKey, provider.trim().toLowerCase());
  }

  /// Gets the custom base URL (used for 9Router).
  Future<String?> getBaseUrl() async {
    return _read(_baseUrlKey);
  }

  /// Saves the custom base URL for 9Router.
  Future<void> saveBaseUrl(String url) async {
    await _write(_baseUrlKey, url.trim());
  }

  /// Gets the configured model name for 9Router.
  Future<String?> getModel() async {
    return _read(_modelKey);
  }

  /// Saves the configured model name for 9Router.
  Future<void> saveModel(String model) async {
    await _write(_modelKey, model.trim());
  }

  Future<void> _write(String key, String value) async {
    if (writeStorage != null) {
      await writeStorage!(key: key, value: value);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (readStorage != null) {
      return readStorage!(key: key);
    }
    return _storage.read(key: key);
  }
}
