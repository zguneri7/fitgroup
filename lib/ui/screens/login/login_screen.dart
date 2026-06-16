import 'package:flutter/material.dart';
import 'package:fitgroup/services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Email gerekli.';
    }
    if (!_isValidEmail(email)) {
      return 'Gecerli bir email gir.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Sifre gerekli.';
    }
    if (password.length < 6) {
      return 'Sifre en az 6 karakter olmali.';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showNotification(
        'Lutfen hatali alanlari duzelt.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService().login(email, password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      _showNotification(
        'Giris basarili!',
        isSuccess: true,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } else {
      switch (result.status) {
        case LoginStatus.invalidCredentials:
          _showNotification(
            'Giris basarisiz. Email veya sifre yanlis.',
            isError: true,
          );
          break;
        case LoginStatus.serverError:
          _showNotification(
            result.message ?? 'Sunucu hatasi. Lutfen daha sonra tekrar dene.',
            isError: true,
          );
          break;
        case LoginStatus.networkError:
          _showNotification(
            result.message ?? 'Sunucuya baglanilamadi. Backend calisiyor mu kontrol et.',
            isError: true,
          );
          break;
        case LoginStatus.success:
          break;
      }
    }
  }

  void _showNotification(
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    final backgroundColor = isSuccess
        ? Colors.green
        : isError
            ? Colors.red
            : Colors.orange;

    final icon = isSuccess
        ? Icons.check_circle
        : isError
            ? Icons.error
            : Icons.warning;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "FitGroup",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: passwordController,
                obscureText: true,
                validator: _validatePassword,
                decoration: const InputDecoration(
                  labelText: 'Sifre',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Giris Yap'),
                ),
              ),

              TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final result = await Navigator.pushNamed(context, '/forgot-password');
                        if (!mounted) {
                          return;
                        }
                        if (result == true) {
                          _showNotification(
                            'Sifre degisti. Yeni sifrenle giris yapabilirsin.',
                            isSuccess: true,
                          );
                        }
                      },
                child: const Text('Sifremi Unuttum'),
              ),

              TextButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(context, '/register');
                  if (!mounted) {
                    return;
                  }
                  if (result == true) {
                    _showNotification(
                      'Kayit tamamlandi. Simdi giris yapabilirsin.',
                      isSuccess: true,
                    );
                  }
                },
                child: const Text('Kayit Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
