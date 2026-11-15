import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

/// Data model representing a message in the AI chat interface.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Halo! Saya Campus AI Assistant. Saya siap membantu Anda menyusun ide catatan, merangkum materi kuliah, atau memberi saran belajar. Ada yang bisa saya bantu hari ini?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _activeProvider = 'gemini';

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    final aiService = ref.read(aiServiceProvider);
    final provider = await aiService.getProvider();
    if (mounted) {
      setState(() {
        _activeProvider = provider;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (presetText == null) {
      _textController.clear();
    }

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);

      // System Prompt framing for mobile context
      final systemContext =
          'Kamu adalah asisten catatan kampus yang ramah dan cerdas. '
          'Jawablah dalam Bahasa Indonesia yang singkat, padat, dan solutif. '
          'Pertanyaan: $text';

      final response = await aiService.ask(systemContext);

      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Fallback dialog as specified in Module Week 10
      _showFallbackDialog(e.toString());
    }
  }

  void _showFallbackDialog(String errorMessage) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Layanan AI Sibuk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Coba lagi nanti atau gunakan mode offline.'),
            const SizedBox(height: 12),
            Text(
              'Info Teknis: $errorMessage',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSettingsDialog();
            },
            child: const Text('Atur Provider / Key'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsDialog() async {
    final aiService = ref.read(aiServiceProvider);
    final currentKey = await aiService.getApiKey() ?? '';
    final currentProvider = await aiService.getProvider();
    final currentBaseUrl =
        await aiService.getBaseUrl() ?? 'http://localhost:20128/v1';
    final currentModel = await aiService.getModel() ?? 'combo1';

    if (!mounted) return;

    var selectedProvider = currentProvider;
    final keyController = TextEditingController(text: currentKey);
    final baseUrlController = TextEditingController(text: currentBaseUrl);
    final modelController = TextEditingController(text: currentModel);

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final is9Router = selectedProvider == '9router';
          return AlertDialog(
            title: const Text('Pengaturan Provider AI'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih provider AI yang ingin digunakan untuk Campus AI Assistant:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'gemini',
                        label: Text('Google Gemini'),
                        icon: Icon(Icons.auto_awesome),
                      ),
                      ButtonSegment(
                        value: '9router',
                        label: Text('9Router / OpenAI'),
                        icon: Icon(Icons.router),
                      ),
                    ],
                    selected: {selectedProvider},
                    onSelectionChanged: (newSelection) {
                      setDialogState(() {
                        selectedProvider = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!is9Router) ...[
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'AIzaSy...',
                        border: OutlineInputBorder(),
                        helperText: 'Kunci disimpan aman di Secure Storage.',
                      ),
                      obscureText: true,
                    ),
                  ] else ...[
                    TextField(
                      controller: baseUrlController,
                      decoration: const InputDecoration(
                        labelText: '9Router Base URL',
                        hintText: 'http://localhost:20128/v1',
                        border: OutlineInputBorder(),
                        helperText: 'Endpoint gateway 9Router lokal/remote.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model 9Router (Default: combo1)',
                        hintText: 'combo1 atau cx/gpt-6-luna',
                        border: OutlineInputBorder(),
                        helperText: 'Gunakan combo1 atau cx/gpt-6-luna.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'API Key 9Router',
                        hintText: 'Masukkan API Key dari dashboard 9Router',
                        border: OutlineInputBorder(),
                        helperText: 'Key dari dasbor 9Router (diperlukan).',
                      ),
                      obscureText: true,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  await aiService.saveProvider(selectedProvider);
                  await aiService.saveApiKey(keyController.text);
                  if (is9Router) {
                    await aiService.saveBaseUrl(baseUrlController.text);
                    await aiService.saveModel(modelController.text);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _activeProvider = selectedProvider;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Provider berhasil disetel ke ${is9Router ? "9Router / OpenAI" : "Google Gemini"}.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    keyController.dispose();
    baseUrlController.dispose();
    modelController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Campus AI Assistant'),
            Text(
              _activeProvider == '9router'
                  ? 'Engine: 9Router (OpenAI Gateway)'
                  : 'Engine: Google Gemini API',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Pengaturan Provider & Kunci AI',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _QuickPromptBar(onSelect: _sendMessage),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI sedang merespon...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          _ChatInputField(
            controller: _textController,
            isLoading: _isLoading,
            onSend: () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}

class _QuickPromptBar extends StatelessWidget {
  const _QuickPromptBar({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.lightbulb_outline, size: 16),
            label: const Text('Ide Catatan Kuliah'),
            onPressed: () => onSelect(
              'Berikan 3 ide catatan terstruktur untuk persiapan ujian pemrograman mobile.',
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.summarize_outlined, size: 16),
            label: const Text('Tips Rangkum Cepat'),
            onPressed: () => onSelect(
              'Bagaimana cara merangkum materi kuliah yang padat menjadi poin-poin efektif?',
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.schedule, size: 16),
            label: const Text('Jadwal Belajar'),
            onPressed: () => onSelect(
              'Buatkan rekomendasi jadwal belajar harian mahasiswa teknik informatika.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return RepaintBoundary(
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color:
                      (isUser
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.outline)
                          .withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatInputField extends StatelessWidget {
  const _ChatInputField({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Tanyakan sesuatu ke AI...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isLoading ? null : onSend,
              icon: const Icon(Icons.send),
              tooltip: 'Kirim pesan',
            ),
          ],
        ),
      ),
    );
  }
}
