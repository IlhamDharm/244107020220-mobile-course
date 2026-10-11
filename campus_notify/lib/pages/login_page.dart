import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authStateProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final busy = auth.isLoading;
    final error = auth.hasError ? auth.error.toString() : null;

    final colors = Theme.of(context).colorScheme;
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: Color(0xFF938D97), width: 1.2),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 34,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.school, size: 64, color: colors.primary),
                        const SizedBox(height: 24),
                        Text(
                          'Campus Notify',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masuk untuk menerima pengumuman kampus',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: const Color(0xFF8A858E)),
                        ),
                        const SizedBox(height: 42),
                        TextFormField(
                          key: const Key('login-email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            prefixIcon: const Icon(Icons.mail_outline),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 18,
                            ),
                            enabledBorder: outline,
                            focusedBorder: outline.copyWith(
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 1.6,
                              ),
                            ),
                            errorBorder: outline.copyWith(
                              borderSide: BorderSide(color: colors.error),
                            ),
                            focusedErrorBorder: outline.copyWith(
                              borderSide: BorderSide(
                                color: colors.error,
                                width: 1.6,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value != null && value.contains('@')
                              ? null
                              : 'Masukkan email yang valid.',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('login-password'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Kata Sandi',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 18,
                            ),
                            enabledBorder: outline,
                            focusedBorder: outline.copyWith(
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 1.6,
                              ),
                            ),
                            errorBorder: outline.copyWith(
                              borderSide: BorderSide(color: colors.error),
                            ),
                            focusedErrorBorder: outline.copyWith(
                              borderSide: BorderSide(
                                color: colors.error,
                                width: 1.6,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value != null && value.length >= 6
                              ? null
                              : 'Kata sandi minimal 6 karakter.',
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            error,
                            key: const Key('login-error'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            key: const Key('login-submit'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: busy ? null : _login,
                            child: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
