import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final ok = await SessionManager.instance.isLoggedIn();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, ok ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Logo box
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              gradient: C.gradPrimary,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(color: C.primary.withOpacity(.5),
                    blurRadius: 40, spreadRadius: 4)]),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 52),
          )
          .animate()
          .scale(begin: const Offset(.6,.6), duration: 600.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 400.ms),

          const SizedBox(height: 28),

          const Text('Sri Murugan Foods',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                color: C.text, letterSpacing: -.5))
          .animate().fadeIn(delay: 400.ms, duration: 400.ms)
          .slideY(begin: .3, duration: 400.ms),

          const SizedBox(height: 6),

          const Text('POS Billing System',
            style: TextStyle(fontSize: 14, color: C.textSub, letterSpacing: .3))
          .animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 52),

          SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              color: C.primary.withOpacity(.7), strokeWidth: 2.5))
          .animate().fadeIn(delay: 900.ms),
        ]),
      ),
    );
  }
}
