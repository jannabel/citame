import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/auth_models.dart';
import '../../core/providers/api_providers.dart';

class BusinessSignUpScreen extends ConsumerStatefulWidget {
  const BusinessSignUpScreen({super.key});

  @override
  ConsumerState<BusinessSignUpScreen> createState() =>
      _BusinessSignUpScreenState();
}

class _BusinessSignUpScreenState extends ConsumerState<BusinessSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.businessSignUp(
          BusinessSignUpRequest(
            password: _passwordController.text,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
          ),
        );

        // After successful sign up, check if businessId is returned
        if (response.businessId.isNotEmpty) {
          // BusinessId is returned, login automatically with email
          await ref
              .read(authStateProvider.notifier)
              .login(_emailController.text.trim(), _passwordController.text);

          if (mounted) {
            context.go('/home');
          }
        } else {
          // No businessId returned, update auth state with token and navigate to business setup screen
          // The token is already set in ApiClient by the signup response
          // We need to update authState to reflect that user is authenticated
          await ref
              .read(authStateProvider.notifier)
              .setAccessToken(
                response.accessToken,
                refreshToken: response.refreshToken,
              );

          if (mounted) {
            context.go(
              '/business/setup',
              extra: {
                'email': _emailController.text.trim(),
                'phone': _phoneController.text.trim(),
              },
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
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
                      Icons.business,
                      size: 48,
                      color: AppTheme.indigoMain,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  // Title
                  Text(
                    'Crear cuenta de negocio',
                    style: AppTheme.textStyleH1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  // Subtitle
                  Text(
                    'Regístrate para gestionar tu negocio',
                    style: AppTheme.textStyleBody.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),
                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMD),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.error),
                      ),
                      child: Text(
                        _error!,
                        style: AppTheme.textStyleBodySmall.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                  ],
                  // Form Card
                  AppTheme.card(
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Negocio',
                            prefixIcon: Icon(
                              Icons.store_outlined,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          style: AppTheme.textStyleBody,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el nombre del negocio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(
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
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: AppTheme.textStyleBody,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu teléfono';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          style: AppTheme.textStyleBody,
                          onChanged: (_) {
                            // Trigger validation of confirm password when password changes
                            if (_confirmPasswordController.text.isNotEmpty) {
                              _formKey.currentState?.validate();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa una contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingMD),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSignUp(),
                          style: AppTheme.textStyleBody,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor confirma la contraseña';
                            }
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  // Sign Up Button
                  AppTheme.primaryButton(
                    text: 'Registrarse',
                    onPressed: _isLoading ? null : _handleSignUp,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes una cuenta? ',
                        style: AppTheme.textStyleBody.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Iniciar sesión'),
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
