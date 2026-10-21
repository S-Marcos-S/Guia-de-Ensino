import 'package:app/core/di/app_dependencies.dart';
import 'package:app/core/localization/app_strings.dart';
import 'package:app/infrastructure/auth/exceptions/auth_exceptions.dart';
import 'package:flutter/material.dart';

/// Modo ativo do formulário de autenticação.
enum AuthFormMode {
  /// Login de usuário existente.
  login,

  /// Cadastro de novo docente.
  register,
}

/// Tela de autenticação pedagógica (Login e Cadastro de Usuário).
///
/// Permite o acesso seguro com e-mail institucional/pessoal e senha, além de
/// viabilizar o uso no modo Convidado 100% offline e local-first.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialMode = AuthFormMode.login,
    this.onSuccess,
  });

  /// Modo inicial com o qual a tela é aberta.
  final AuthFormMode initialMode;

  /// Callback opcional executado após autenticação bem-sucedida.
  final VoidCallback? onSuccess;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  late AuthFormMode _mode;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthFormMode newMode) {
    if (_isLoading) return;
    setState(() {
      _mode = newMode;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final deps = AppDependencyScope.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_mode == AuthFormMode.login) {
        await deps.authRepository.login(email: email, password: password);
      } else {
        await deps.authRepository.register(email: email, password: password);
      }

      if (!mounted) return;

      final successMsg = _mode == AuthFormMode.login
          ? AppStrings.authSuccessLogin
          : AppStrings.authSuccessRegister;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg),
          backgroundColor: Colors.green.shade700,
        ),
      );

      widget.onSuccess?.call();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on InvalidCredentialsException catch (e) {
      setState(() => _errorMessage = e.message);
    } on EmailAlreadyInUseException catch (e) {
      setState(() => _errorMessage = e.message);
    } on AuthNetworkException {
      setState(
        () => _errorMessage =
            'Falha de conexão com o servidor. Verifique sua internet.',
      );
    } on AuthValidationException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(
        () => _errorMessage =
            'Ocorreu um erro inesperado ao processar sua solicitação: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _continueAsGuest() {
    if (_isLoading) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mode == AuthFormMode.login
              ? AppStrings.authScreenTitleLogin
              : AppStrings.authScreenTitleRegister,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: AppStrings.backButton,
          onPressed: _isLoading ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ícone e Título Superior
                    Icon(
                      Icons.school_rounded,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.appTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Alternador Segmentado: Login / Cadastro
                    SegmentedButton<AuthFormMode>(
                      segments: const [
                        ButtonSegment(
                          value: AuthFormMode.login,
                          label: Text(AppStrings.authTabLogin),
                          icon: Icon(Icons.login),
                        ),
                        ButtonSegment(
                          value: AuthFormMode.register,
                          label: Text(AppStrings.authTabRegister),
                          icon: Icon(Icons.person_add_alt_1),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selected) {
                        if (selected.isNotEmpty) {
                          _switchMode(selected.first);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Mensagem de Erro, se houver
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.error),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Campo de E-mail
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: AppStrings.authEmailLabel,
                        hintText: AppStrings.authEmailHint,
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final val = value?.trim() ?? '';
                        if (val.isEmpty) {
                          return AppStrings.authValidationEmailRequired;
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return AppStrings.authValidationEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de Senha
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: _obscurePassword,
                      textInputAction: _mode == AuthFormMode.login
                          ? TextInputAction.done
                          : TextInputAction.next,
                      onFieldSubmitted: (_) {
                        if (_mode == AuthFormMode.login) {
                          _submit();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: AppStrings.authPasswordLabel,
                        hintText: AppStrings.authPasswordHint,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        final val = value ?? '';
                        if (val.isEmpty) {
                          return AppStrings.authValidationPasswordRequired;
                        }
                        if (val.length < 8) {
                          return AppStrings.authValidationPasswordMinLength;
                        }
                        return null;
                      },
                    ),

                    // Campo de Confirmação de Senha (apenas Cadastro)
                    if (_mode == AuthFormMode.register) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        enabled: !_isLoading,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: AppStrings.authConfirmPasswordLabel,
                          hintText: AppStrings.authConfirmPasswordHint,
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: _obscureConfirmPassword
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            onPressed: () {
                              setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (_mode != AuthFormMode.register) return null;
                          final val = value ?? '';
                          if (val.isEmpty) {
                            return AppStrings.authValidationPasswordRequired;
                          }
                          if (val != _passwordController.text) {
                            return AppStrings.authValidationPasswordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botão Principal (Entrar ou Cadastrar)
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _mode == AuthFormMode.login
                                      ? AppStrings.authLoadingLogin
                                      : AppStrings.authLoadingRegister,
                                ),
                              ],
                            )
                          : Text(
                              _mode == AuthFormMode.login
                                  ? AppStrings.authLoginButton
                                  : AppStrings.authRegisterButton,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Alternância entre Login e Cadastro via texto
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _switchMode(
                                _mode == AuthFormMode.login
                                    ? AuthFormMode.register
                                    : AuthFormMode.login,
                              );
                            },
                      child: Text(
                        _mode == AuthFormMode.login
                            ? AppStrings.authSwitchToRegister
                            : AppStrings.authSwitchToLogin,
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Botão para Modo Convidado (Preservação Local/Offline)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.offline_bolt_outlined),
                      label: const Text(AppStrings.authGuestButton),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _continueAsGuest,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.authGuestSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
