import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static Color background(bool isDark) => isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FB);
  static Color cardBg(bool isDark) => isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color cardBgDarker(bool isDark) => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color cardBgLighter(bool isDark) => isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
  
  // Texts
  static Color textPrimary(bool isDark) => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
  static Color textSecondary(bool isDark) => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color textMuted(bool isDark) => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  static Color textHint(bool isDark) => isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

  // Borders & Dividers
  static Color border(bool isDark) => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color divider(bool isDark) => isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  
  // Shadows
  static Color shadow(bool isDark) => isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05);
  static Color shadowHeavy(bool isDark) => isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.15);

  // Primary Colors (Emerald/Green)
  static const Color primary = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF047857);
  static Color primaryBg(bool isDark) => isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
  static Color primaryBgLight(bool isDark) => isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5);
}
