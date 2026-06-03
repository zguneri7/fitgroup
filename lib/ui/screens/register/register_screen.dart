import 'package:flutter/material.dart';
import 'package:fitgroup/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final AuthService _authService = AuthService();
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
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

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return 'Sifre tekrari gerekli.';
    }
    if (confirmPassword != _passwordController.text) {
      return 'Sifreler ayni degil.';
    }
    return null;
  }

  String? _validateBirthDate() {
    if (_selectedBirthDate == null) {
      return 'Dogum tarihi gerekli.';
    }

    if (_selectedBirthDate!.isAfter(DateTime.now())) {
      return 'Dogum tarihi bugunden sonra olamaz.';
    }

    return null;
  }

  String? _validateGender() {
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      return 'Cinsiyet secimi gerekli.';
    }

    return null;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(now.year - 18, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Dogum tarihini sec',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedBirthDate = pickedDate;
      _birthDateController.text = _formatDate(pickedDate);
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final birthDateError = _validateBirthDate();
    final genderError = _validateGender();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showNotification(
        'Lutfen hatali alanlari duzelt.',
        isError: true,
      );
      return;
    }

    if (birthDateError != null || genderError != null) {
      _showNotification(
        birthDateError ?? genderError!,
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.register(
      fullName,
      email,
      password,
      _selectedBirthDate!,
      _selectedGender!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showNotification(
        'Kayit basarili. Simdi giris yapabilirsin.',
        isSuccess: true,
      );
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      _showNotification(
        'Kayit basarisiz. Bu email zaten kullaniliyor olabilir.',
        isError: true,
      );
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
      appBar: AppBar(title: const Text('Kayit Ol')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                onTap: _pickBirthDate,
                decoration: const InputDecoration(
                  labelText: 'Dogum Tarihi',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'erkek', child: Text('Erkek')),
                  DropdownMenuItem(value: 'kadin', child: Text('Kadin')),
                  DropdownMenuItem(value: 'diger', child: Text('Diger')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Cinsiyet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: _validatePassword,
                decoration: const InputDecoration(
                  labelText: 'Sifre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: _validateConfirmPassword,
                decoration: const InputDecoration(
                  labelText: 'Sifre Tekrar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kayit Ol'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
