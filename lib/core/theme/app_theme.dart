import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ══════════════════════════════════════════════════════════════════
/// 🎨 LIFELY APP — MODERN MEDICAL PREMIUM v2.0
/// ══════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ── Brand / Primary Colours ──
  static const Color primaryDark = Color(0xFF0D2E8A);
  static const Color primaryMid = Color(0xFF1A56DB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryGlow = Color(0xFF60A5FA);
  
  // ── Accent / CTA ──
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentTealMid = Color(0xFF14B8A6);
  static const Color accentTealGlow = Color(0xFF2DD4BF);

  // ── Surface Colours ──
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFEEF2FF);

  // ── Text Colours ──
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Semantic Colours ──
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color pending = Color(0xFFF59E0B);
  static const Color pendingBg = Color(0xFFFFFBEB);
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color purpleHealth = Color(0xFF8B5CF6);
  static const Color purpleSoft = Color(0xFFFAF5FF);

  // ── Layout Constants ──
  static const double borderRadiusScreen = 24.0;
  static const double borderRadiusCard = 20.0;
  static const double borderRadiusInput = 14.0;
  static const double borderRadiusPill = 50.0;

  // ── Typography Scale ──
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w900, // Black
        color: textPrimary,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700, // Bold
        color: textPrimary,
        height: 1.20,
        letterSpacing: -0.3,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600, // SemiBold
        color: textPrimary,
        height: 1.30,
      );

  static TextStyle get bodyL => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500, // Medium
        color: textPrimary,
        height: 1.50,
      );

  static TextStyle get bodyM => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Regular
        color: textPrimary,
        height: 1.55,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        height: 1.40,
        letterSpacing: 0.3,
      );

  static TextStyle get badge => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.0,
        letterSpacing: 0.8,
      );

  // ── Gradients ──
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryMid, primaryLight],
    stops: [0.0, 0.5, 1.0],
    transform: GradientRotation(2.35619), // approx 135 deg
  );

  static const LinearGradient tealCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentTeal, accentTealMid, accentTealGlow],
    stops: [0.0, 0.5, 1.0],
    transform: GradientRotation(2.35619),
  );

  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMid, accentTeal],
    transform: GradientRotation(2.35619),
  );

  static const LinearGradient cardShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pureWhite, Color(0xFFF0F4FF), pureWhite],
    transform: GradientRotation(2.35619),
  );

  // ── Elevation / Shadows ──
  static List<BoxShadow> get shadowLevel1 => [
        BoxShadow(
          color: const Color(0xFF0F1722).withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLevel2 => [
        BoxShadow(
          color: const Color(0xFF0F1722).withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLevel3 => [
        BoxShadow(
          color: const Color(0xFF1A56DB).withValues(alpha: 0.18),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get shadowLevel4 => [
        BoxShadow(
          color: const Color(0xFF1A56DB).withValues(alpha: 0.28),
          blurRadius: 48,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get shadowTealGlow => [
        BoxShadow(
          color: const Color(0xFF0D9488).withValues(alpha: 0.40),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get shadowBlueGlow => [
        BoxShadow(
          color: const Color(0xFF1A56DB).withValues(alpha: 0.35),
          blurRadius: 28,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Card Decoration Defaults ──
  static BoxDecoration get cardDecorationL1 => BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(borderRadiusCard),
        boxShadow: shadowLevel1,
      );

  static BoxDecoration get cardDecorationL2 => BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(borderRadiusScreen),
        boxShadow: shadowLevel2,
      );

  // ══════════════════════════════════════════════════════════════════
  // 🏷️ STATUS BADGE WIDGET BUILDER
  // ══════════════════════════════════════════════════════════════════

  static Widget statusBadge(String status, {double fontSize = 11}) {
    final normalized = status.toLowerCase().trim();

    Color textColor;
    Color bgColor;
    Color borderColor;

    if (normalized == 'accepted' || normalized == 'low risk' || normalized == 'completed') {
      textColor = const Color(0xFF059669); // Slightly darker green for text
      bgColor = successBg;
      borderColor = const Color(0xFF059669);
    } else if (normalized == 'pending' || normalized == 'in progress') {
      textColor = pending;
      bgColor = pendingBg;
      borderColor = pending;
    } else if (normalized == 'rejected' || normalized == 'declined' || normalized == 'high risk' || normalized == 'cancelled') {
      textColor = danger;
      bgColor = dangerBg;
      borderColor = danger;
    } else {
      textColor = primaryMid;
      bgColor = const Color(0xFFEFF6FF);
      borderColor = primaryMid;
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadiusPill),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: badge.copyWith(fontSize: fontSize, color: textColor),
      ),
    );
  }

  // ── Light Theme ThemeData ──
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.light(
          primary: primaryMid,
          secondary: accentTeal,
          surface: pureWhite,
          error: danger,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
          onError: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: display,
          displayMedium: h1,
          displaySmall: h2,
          headlineMedium: h3,
          bodyLarge: bodyL,
          bodyMedium: bodyM,
          bodySmall: caption,
          labelSmall: badge,
        ),
      );
}
