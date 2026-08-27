import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../logic/controllers/auth_controller.dart';
import '../../di/service_locator.dart';
import 'package:frontend/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _controller = getIt<AuthController>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  void _onSwitchMode(String mode) {
    _controller.switchMode(mode);
    _emailController.clear();
    _passwordController.clear();
    _usernameController.clear();
    _pinController.clear();
  }

  void _handleLogin() async {
    final route = await _controller.login(
      email: _emailController.text,
      password: _passwordController.text,
      username: _usernameController.text,
      pin: _pinController.text,
    );

    if (!mounted) return;

    if (route != null) {
      context.go(route);
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginEmailRequired),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final success = await _controller.forgotPassword(email);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginPasswordResetSentMsg(email)),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No account found with this email address.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final mode = _controller.mode;
        final isLoading = _controller.isLoading;
        final error = _controller.error;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  // Logo Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: Image.asset(
                        'assets/images/levelup_logo_full.png',
                        height: 260,
                        width: 260,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),



                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (mode == 'staff') ...[
                          Text(l10n.loginEmailAddressLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(hintText: l10n.emailHint),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),
                          Text(l10n.loginPasswordLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(hintText: l10n.passwordHint),
                            obscureText: true,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: isLoading ? null : () => _onSwitchMode('student'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "I'm a Student",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: isLoading ? null : _handleForgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n.loginForgotPassword,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(l10n.loginUsernameLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(hintText: l10n.usernameHint),
                          ),
                          const SizedBox(height: 18),
                          Text(l10n.loginPinCodeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _pinController,
                            decoration: InputDecoration(
                              hintText: l10n.pinHint,
                              counterText: '',
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            obscureText: true,
                          ),
                        ],

                        if (error.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.errorBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFfca5a5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                                const SizedBox(width: 8),
                                Expanded(child: Text(error, style: const TextStyle(fontSize: 13, color: AppColors.error))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          child: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.text, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(l10n.signInButton),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                        if (mode == 'student') ...[
                          const SizedBox(height: 18),
                          Center(
                            child: TextButton(
                              onPressed: isLoading ? null : () => _onSwitchMode('staff'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "I'm a Staff",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
