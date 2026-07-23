import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Dark palette ────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceElevated = Color(0xFF1A1A26);
  static const Color border = Color(0xFF252535);
  static const Color borderLight = Color(0xFF2E2E45);

  static const Color textPrimary = Color(0xFFEEEEFF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF55556A);

  // ── Light palette ───────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F5FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F0F8);
  static const Color lightBorder = Color(0xFFE0E0EE);
  static const Color lightBorderLight = Color(0xFFD0D0E8);

  static const Color lightTextPrimary = Color(0xFF12121A);
  static const Color lightTextSecondary = Color(0xFF55557A);
  static const Color lightTextMuted = Color(0xFF9090AA);

  // ── Provider accent colors (shared) ─────────────────────────────────────
  static const Color accentClaude = Color(0xFFD97757);
  static const Color accentOpenAI = Color(0xFF10A37F);
  static const Color accentGemini = Color(0xFF4285F4);
  static const Color accentCopilot = Color(0xFF6E40C9);
  static const Color accentCursor = Color(0xFF1C8BF4);
  static const Color accentElevenLabs = Color(0xFFFF6B35);
  static const Color accentRunway = Color(0xFF00D4AA);
  static const Color accentStability = Color(0xFF7C3AED);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);

  // ── Dark theme ──────────────────────────────────────────────────────────
  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: background,
        surf: surface,
        surfEl: surfaceElevated,
        bord: border,
        textPri: textPrimary,
        textSec: textSecondary,
        textMut: textMuted,
      );

  // ── Light theme ─────────────────────────────────────────────────────────
  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: lightBackground,
        surf: lightSurface,
        surfEl: lightSurfaceElevated,
        bord: lightBorder,
        textPri: lightTextPrimary,
        textSec: lightTextSecondary,
        textMut: lightTextMuted,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surf,
    required Color surfEl,
    required Color bord,
    required Color textPri,
    required Color textSec,
    required Color textMut,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        surface: surf,
        primary: accentClaude,
        secondary: accentOpenAI,
        error: error,
        onSurface: textPri,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        outline: bord,
        primaryContainer: accentClaude.withOpacity(0.12),
        onPrimaryContainer: accentClaude,
        surfaceContainerHighest: surfEl,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.inter(
          color: textPri,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          color: textPri,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPri,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSec,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: GoogleFonts.inter(
          color: textMut,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      dividerTheme: DividerThemeData(color: bord, thickness: 1),
      cardTheme: CardThemeData(
        color: surfEl,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: bord, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surf,
        hintStyle: GoogleFonts.inter(color: textMut, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bord),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bord),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentClaude, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: textPri,
        unselectedItemColor: textMut,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: textPri,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textSec),
      ),
    );
  }
}
