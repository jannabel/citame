import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      print('[LoginScreen] Form validated, starting login...');
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        print('[LoginScreen] Calling login with email: $email');
        await ref.read(authStateProvider.notifier).login(email, password);

        // Give the state a moment to update
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          final authState = ref.read(authStateProvider);
          print(
            '[LoginScreen] Auth state after login - isAuthenticated: ${authState.isAuthenticated}, businessId: ${authState.businessId}, error: ${authState.error}',
          );

          if (authState.isAuthenticated) {
            print('[LoginScreen] User authenticated, navigating to home...');
            // Router will automatically redirect, but we can also navigate explicitly
            context.go('/home');
            print('[LoginScreen] Navigation called');
          } else if (authState.error != null) {
            print('[LoginScreen] Login failed with error: ${authState.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authState.error!.replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            print(
              '[LoginScreen] Unexpected state: not authenticated but no error',
            );
          }
        }
      } catch (e) {
        print('[LoginScreen] Exception caught: $e');
        if (mounted) {
          final authState = ref.read(authStateProvider);
          final errorMessage =
              authState.error?.replaceAll('Exception: ', '') ??
              e.toString().replaceAll('Exception: ', '');
          print('[LoginScreen] Showing error: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      print('[LoginScreen] Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXL,
              vertical: AppTheme.spacingXXL,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    decoration: BoxDecoration(
                      color: AppTheme.indigoMain.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppTheme.indigoMain,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  // Title
                  Text(
                    l10n.welcomeBack,
                    style: AppTheme.textStyleH1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  // Subtitle
                  Text(
                    l10n.signInToManage,
                    style: AppTheme.textStyleBody.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),
                  // Form Card
                  AppTheme.card(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: AppTheme.textStyleBody,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu email';
                            }
                            if (!value.contains('@')) {
                              return 'Por favor ingresa un email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(
                              Icons.lock_outlined,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          style: AppTheme.textStyleBody,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterPassword;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingSM),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.indigoMain,
                            ),
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  // Login Button
                  AppTheme.primaryButton(
                    text: l10n.login,
                    onPressed: authState.isLoading ? null : _handleLogin,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes una cuenta? ',
                        style: AppTheme.textStyleBody.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup/business'),
                        child: const Text('Regístrate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
