import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';
import '../../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'admin@pos.com');
  final _passCtrl  = TextEditingController(text: 'Admin@123');
  bool  _obscure   = true;
  bool  _isTA      = false;

  @override
  void initState() {
    super.initState();
    SessionManager.instance.lang.then((l) {
      if (mounted) setState(() => _isTA = l == 'ta');
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  String t(String en, String ta) => _isTA ? ta : en;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

              const Gap(20),
              // Language toggle
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _LangPill(label: 'EN',    active: !_isTA, onTap: () => _setLang(false)),
                const Gap(6),
                _LangPill(label: 'தமிழ்', active: _isTA,  onTap: () => _setLang(true)),
              ]).animate().fadeIn(duration: 400.ms),

              const Gap(40),

              // Logo
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: C.gradPrimary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(
                      color: C.primary.withOpacity(.4), blurRadius: 30)]),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 44)),
              )
              .animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const Gap(20),

              Center(child: Text('Sri Murugan Masala',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: C.text, letterSpacing: -.4)))
              .animate().fadeIn(delay: 200.ms),

              const Gap(6),

              Center(child: Text(t('Sign in to your account', 'உங்கள் கணக்கில் உள்நுழைக'),
                style: const TextStyle(fontSize: 13, color: C.textSub)))
              .animate().fadeIn(delay: 300.ms),

              const Gap(36),

              // Error
              Consumer<AuthProvider>(builder: (_, auth, __) =>
                auth.error.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: C.red.withOpacity(.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: C.red.withOpacity(.3))),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: C.red, size: 18),
                        const Gap(8),
                        Expanded(child: Text(auth.error,
                          style: const TextStyle(color: C.red, fontSize: 13))),
                      ]))
                    .animate().fadeIn().shakeX(amount: 4)
                  : const SizedBox.shrink()),

              // Email field
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: C.text),
                decoration: InputDecoration(
                  labelText: t('Email', 'மின்னஞ்சல்'),
                  prefixIcon: const Icon(Icons.alternate_email, color: C.textSub, size: 20)),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? t('Required', 'தேவை') : null,
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -.05),

              const Gap(14),

              // Password field
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                style: const TextStyle(color: C.text),
                decoration: InputDecoration(
                  labelText: t('Password', 'கடவுச்சொல்'),
                  prefixIcon: const Icon(Icons.lock_outline, color: C.textSub, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                        color: C.textSub, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure))),
                validator: (v) => (v?.isEmpty ?? true)
                    ? t('Required', 'தேவை') : null,
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -.05),

              const Gap(28),

              // Login button
              Consumer<AuthProvider>(
                builder: (_, auth, __) => PrimaryButton(
                  label: t('Login', 'உள் நுழைய'),
                  icon: Icons.login_rounded,
                  loading: auth.loading,
                  onTap: _login,
                ).animate().fadeIn(delay: 600.ms).slideY(begin: .2)),

              const Gap(20),

              // Hint
              Center(child: Text('admin@pos.com / Admin@123',
                style: const TextStyle(fontSize: 11, color: C.textMuted)))
              .animate().fadeIn(delay: 700.ms),

              const Gap(40),
            ]),
          ),
        ),
      ),
    );
  }

  void _setLang(bool ta) {
    setState(() => _isTA = ta);
    SessionManager.instance.setLang(ta ? 'ta' : 'en');
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 200.ms,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: active ? C.gradPrimary : null,
        color: active ? null : C.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: active ? C.primary : C.border)),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: active ? Colors.white : C.textSub))));
}
