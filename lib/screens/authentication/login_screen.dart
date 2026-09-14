import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';

const _kRememberKey = 'remember_me_email';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadSavedEmail();
    // Navigate when auth state becomes authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppAuthProvider>().addListener(_onAuthChanged);
    });
  }

  void _onAuthChanged() {
    final auth = context.read<AppAuthProvider>();
    if (auth.status == AuthStatus.authenticated && mounted) {
      context.go('/home');
    }
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kRememberKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        _emailController.text = saved;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    context.read<AppAuthProvider>().removeListener(_onAuthChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    auth.clearError();
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_kRememberKey, _emailController.text.trim());
    } else {
      await prefs.remove(_kRememberKey);
    }

    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A),
      body: Column(
        children: [
          // ── Top illustrated half ──────────────────────────────────────
          SizedBox(
            height: size.height * 0.42,
            width: double.infinity,
            child: Stack(
              children: [
                // Background painter
                Positioned.fill(
                  child: CustomPaint(painter: _HeroPainter()),
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => context.go('/welcome'),
                  ),
                ),
                // Center content
                FadeTransition(
                  opacity: _fadeIn,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pets, size: 52, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'PetCore',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your pet\'s health companion',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom white card half ────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 28),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration('Email', Icons.email_outlined),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Please enter your email';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecoration(
                            'Password',
                            Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Please enter your password' : null,
                        ),

                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFF6A1B9A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (v) => setState(() => _rememberMe = v!),
                            ),
                            const Text('Remember me',
                                style: TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              child: const Text('Forgot Password?',
                                  style: TextStyle(color: Color(0xFF6A1B9A), fontSize: 13)),
                            ),
                          ],
                        ),

                        if (auth.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(auth.error!,
                                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A1B9A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: auth.loading ? null : _login,
                            child: auth.loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Log In',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: TextStyle(color: Colors.grey.shade600)),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFF6A1B9A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6A1B9A), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F0FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

// ── Hero background painter ────────────────────────────────────────────────

class _HeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Soft blobs
    paint.color = const Color(0xFF7B1FA2).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 80, paint);

    paint.color = const Color(0xFF4A148C).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 70, paint);

    paint.color = const Color(0xFF9C27B0).withValues(alpha: 0.25);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.05), 50, paint);

    // Scattered paw prints
    final pawPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    _drawPaw(canvas, pawPaint, Offset(size.width * 0.15, size.height * 0.2), 14);
    _drawPaw(canvas, pawPaint, Offset(size.width * 0.78, size.height * 0.55), 10);
    _drawPaw(canvas, pawPaint, Offset(size.width * 0.88, size.height * 0.82), 12);
    _drawPaw(canvas, pawPaint, Offset(size.width * 0.05, size.height * 0.6), 9);
    _drawPaw(canvas, pawPaint, Offset(size.width * 0.6, size.height * 0.88), 11);
  }

  void _drawPaw(Canvas canvas, Paint paint, Offset center, double size) {
    // Main pad
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size * 1.2, height: size),
      paint,
    );
    // 4 toe pads
    final toeSize = size * 0.38;
    final offsets = [
      Offset(center.dx - size * 0.55, center.dy - size * 0.65),
      Offset(center.dx - size * 0.18, center.dy - size * 0.82),
      Offset(center.dx + size * 0.18, center.dy - size * 0.82),
      Offset(center.dx + size * 0.55, center.dy - size * 0.65),
    ];
    for (final o in offsets) {
      canvas.drawCircle(o, toeSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Reuse for register screen too
InputDecoration authInputDecoration(String label, IconData icon, {Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF6A1B9A), size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF5F0FA),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
