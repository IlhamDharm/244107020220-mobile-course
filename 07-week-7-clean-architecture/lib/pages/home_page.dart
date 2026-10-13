import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_errors.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/push/presentation/providers/push_provider.dart';
import '../providers/api_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _tokenPreview = 'Memuat...';
  String? _requestMessage;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _loadTokenPreview();
  }

  Future<void> _loadTokenPreview() async {
    final token = await ref.read(tokenStoreProvider).readAccess();
    if (!mounted) return;
    setState(() {
      if (token == null || token.isEmpty) {
        _tokenPreview = 'Tidak ada token';
      } else {
        final visibleLength = token.length < 12 ? token.length : 12;
        _tokenPreview = '${token.substring(0, visibleLength)}...';
      }
    });
  }

  Future<void> _tryRefresh() async {
    setState(() {
      _requesting = true;
      _requestMessage = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/protected');
      if (!mounted) return;
      setState(() => _requestMessage = response.data?['message'] as String?);
      await _loadTokenPreview();
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _requestMessage = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _tryExpiredRefresh() async {
    final store = ref.read(tokenStoreProvider);
    final access = await store.readAccess();
    if (access == null || access.isEmpty) return;
    await store.save(access: access, refresh: '');
    await _tryRefresh();
  }

  Future<void> _logout() => ref.read(authStateProvider.notifier).logout();

  Future<void> _copyFcmToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Token disalin. Jangan tampilkan token penuh di screenshot atau log.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pushService = ref.watch(pushServiceProvider);
    final firebaseError = ref.watch(firebaseInitializationErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            key: const Key('logout-button'),
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AnimatedBuilder(
                animation: pushService ?? _NoopListenable.instance,
                builder: (context, child) => Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selamat datang!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        if (pushService == null)
                          Text(
                            firebaseError ?? 'Firebase belum diinisialisasi.',
                            key: const Key('firebase-status-error'),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            pushService.permissionStatus == 'Belum diminta'
                                ? 'Aplikasi terhubung ke Firebase.'
                                : 'Status izin: ${pushService.permissionStatus}.',
                            key: const Key('firebase-status'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 26),
                        const Text(
                          'FCM Token (untuk uji notifikasi):',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          child: SelectableText(
                            pushService?.tokenPreview ?? 'Token belum tersedia. Tambahkan konfigurasi Firebase.',
                            key: const Key('fcm-token-preview'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('copy-fcm-token'),
                          onPressed: pushService?.token == null
                              ? null
                              : () => _copyFcmToken(pushService!.token!),
                          icon: const Icon(Icons.copy),
                          label: const Text('Salin Token'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          key: const Key('request-fcm-permission'),
                          onPressed: pushService == null || pushService.isBusy
                              ? null
                              : pushService.requestPermissionAndGetToken,
                          icon: const Icon(Icons.notifications),
                          label: const Text('Izin & ambil token FCM'),
                        ),
                        if (pushService?.statusMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            pushService!.statusMessage!,
                            key: const Key('fcm-action-status'),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          'Token hanya ditampilkan 12 karakter awal. '
                          'Tombol salin menyalin token lengkap untuk pengujian; '
                          'jangan tempelkan token penuh ke screenshot atau log.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: pushService ?? _NoopListenable.instance,
                builder: (context, child) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.campaign_outlined),
                    title: const Text('Topik pengumuman-kampus'),
                    subtitle: Text(
                      pushService == null
                          ? 'Memerlukan koneksi Firebase'
                          : pushService.isSubscribedToTopic
                          ? 'Berlangganan untuk pesan broadcast'
                          : 'Belum berlangganan',
                    ),
                    trailing: TextButton(
                      onPressed: pushService == null
                          ? null
                          : pushService.isSubscribedToTopic
                          ? pushService.unsubscribeFromCampusAnnouncements
                          : pushService.subscribeToCampusAnnouncements,
                      child: Text(
                        pushService?.isSubscribedToTopic == true
                            ? 'BERHENTI'
                            : 'LANGGANAN',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Buka contoh pengumuman'),
                  subtitle: const Text('Uji tujuan deep link /pengumuman/3'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.announcement('3')),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.verified_user_outlined),
                  ),
                  title: const Text(
                    'Login berhasil',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Sesi mock aktif. Token disimpan di secure storage.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('Access token (disamarkan)'),
                  subtitle: Text(
                    _tokenPreview,
                    key: const Key('token-preview'),
                  ),
                  trailing: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uji refresh otomatis saat 401',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'API demo mengembalikan 401 untuk access token lama. '
                        'Interceptor mencoba refresh sekali lalu mengulang '
                        'request.',
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        key: const Key('refresh-test'),
                        onPressed: _requesting ? null : _tryRefresh,
                        icon: _requesting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: const Text('Simulasikan request 401'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('expired-refresh-test'),
                        onPressed: _requesting ? null : _tryExpiredRefresh,
                        icon: const Icon(Icons.logout),
                        label: const Text('Uji refresh kedaluwarsa dan logout'),
                      ),
                      if (_requestMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _requestMessage!,
                          key: const Key('refresh-result'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Gunakan Logout untuk menghapus sesi. Tombol uji refresh '
                    'kedaluwarsa mengosongkan refresh token, memicu 401, '
                    'membersihkan sesi, lalu mengarahkan kembali ke login.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoopListenable implements Listenable {
  const _NoopListenable();

  static const instance = _NoopListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
