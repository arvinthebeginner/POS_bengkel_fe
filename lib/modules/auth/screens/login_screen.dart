import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/neumorphic.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal terhubung ke server. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            children: [
              // ---------- Logo badge ----------
              NeumorphicBox(
                width: 140,
                height: 140,
                borderRadius: 70,
                padding: const EdgeInsets.all(28),
                child: Image.asset('assets/icon/app_icon.png'),
              ),
              const SizedBox(height: 20),
              Text(
                'PRATAMA MOTOR',
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'CEPAT • TEPAT • TERPERCAYA',
                style: TextStyle(
                  color: AppColors.primaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              // ---------- Form card ----------
              NeumorphicBox(
                borderRadius: 28,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Masuk ke Akun',
                        style: TextStyle(
                          fontFamily: Theme.of(context).textTheme.titleLarge?.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masukkan kredensial kamu untuk melanjutkan',
                        style: TextStyle(color: AppColors.secondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      NeumorphicTextField(
                        controller: _usernameController,
                        hintText: 'Username',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      NeumorphicTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 18,
                                color: AppColors.errorText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.errorText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      NeumorphicPrimaryButton(
                        label: 'Login',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
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
