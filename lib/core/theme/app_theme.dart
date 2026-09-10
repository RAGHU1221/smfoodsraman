import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  // Brand
  static const primary   = Color(0xFF6366F1);
  static const accent    = Color(0xFF8B5CF6);
  static const green     = Color(0xFF10B981);
  static const red       = Color(0xFFEF4444);
  static const orange    = Color(0xFFF59E0B);
  static const blue      = Color(0xFF3B82F6);

  // Backgrounds
  static const bg        = Color(0xFF0A0A0F);
  static const surface   = Color(0xFF12121A);
  static const card      = Color(0xFF1A1A28);
  static const cardHover = Color(0xFF1E1E30);
  static const elevated  = Color(0xFF242436);

  // Text
  static const text      = Color(0xFFF1F1F5);
  static const textSub   = Color(0xFF9494B0);
  static const textMuted = Color(0xFF5A5A78);

  // Border
  static const border    = Color(0xFF2A2A3E);
  static const borderFoc = Color(0xFF6366F1);

  // Gradients
  static const gradPrimary = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradGreen = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradSurface = LinearGradient(
    colors: [Color(0xFF1A1A28), Color(0xFF12121A)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: C.bg,
      colorScheme: const ColorScheme.dark(
        primary: C.primary, secondary: C.green,
        surface: C.surface, error: C.red,
        onPrimary: Colors.white, onSurface: C.text,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: C.text, displayColor: C.text),
      appBarTheme: const AppBarTheme(
        backgroundColor: C.bg, foregroundColor: C.text,
        elevation: 0, surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
            color: C.text, letterSpacing: -0.3)),
      cardTheme: const CardTheme(
        color: C.card, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: C.border))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: C.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.primary, width: 2)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.red)),
        labelStyle: const TextStyle(color: C.textSub),
        hintStyle: const TextStyle(color: C.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0, backgroundColor: C.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              letterSpacing: 0.2))),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: C.surface, selectedItemColor: C.primary,
        unselectedItemColor: C.textMuted, elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11)),
      dividerTheme: const DividerThemeData(color: C.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: C.elevated, contentTextStyle: const TextStyle(color: C.text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating),
    );
  }
}

// ─── Reusable UI helpers ──────────────────────────────────────────
class AppGradientBox extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry padding;
  final BorderRadius? radius;
  final Border? border;

  const AppGradientBox({
    super.key, required this.child,
    this.gradient, this.padding = const EdgeInsets.all(16),
    this.radius, this.border,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: gradient ?? C.gradSurface,
      borderRadius: radius ?? BorderRadius.circular(16),
      border: border ?? Border.all(color: C.border)),
    child: child);
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({super.key, required this.child,
      this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onTap != null ? (color ?? C.card) : (color ?? C.card),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border)),
      child: child));
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final LinearGradient? gradient;
  final double height;

  const PrimaryButton({super.key, required this.label,
      this.onTap, this.loading = false, this.icon,
      this.gradient, this.height = 54});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      decoration: BoxDecoration(
        gradient: loading ? null : (gradient ?? C.gradPrimary),
        color: loading ? C.elevated : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: loading ? [] : [
          BoxShadow(color: C.primary.withOpacity(.35),
              blurRadius: 16, offset: const Offset(0, 6))]),
      child: Center(child: loading
        ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8)],
            Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ]))));
}

class AppChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? activeColor;

  const AppChip({super.key, required this.label,
      required this.active, required this.onTap, this.activeColor});

  @override
  Widget build(BuildContext context) {
    final col = activeColor ?? C.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? LinearGradient(colors: [col, col.withOpacity(.8)]) : null,
          color: active ? null : C.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: active ? col : C.border)),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? Colors.white : C.textSub))));
  }
}
