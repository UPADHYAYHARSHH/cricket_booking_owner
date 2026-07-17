import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // --- BRAND COLORS (Consistent in both themes) ---
  static const Color primaryDarkGreen = Color(0xFF0B8457); // Turf Green
  static const Color primaryLightGreen = Color(0xFF4CAF50); // Vibrant Green
  static const Color accentOrange = Color(0xFFFF9800); // CTA / Highlights
  static const Color goldenYellow = Color(0xFFFFD600); // Advance Paid / Ratings

  // --- LIGHT THEME COLORS ---
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF616161);
  static const Color borderLight = Color(0xFFEEEEEE);

  // --- DARK THEME COLORS ---
  static const Color bgDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFECEFF1);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);
  static const Color borderDark = Color(0xFF2C2C2C);

  // --- SLOT STATUS COLORS ---
  static const Color slotAvailable = Color(0xFF4CAF50);
  static const Color slotBooked = Color(0xFFE53935);
  static const Color slotSelected = Color(0xFFFF9800);
  static const Color slotBlocked = Color(0xFFBDBDBD);

  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF2E7D32);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color ratingAmber = Color(0xFFFFC107);

  // --- SEMANTIC TOKENS ---
  static const Color slotAvailableBorder = Color(0xFF00C897);
  static const Color slotAvailableBg = Color(0xFFE8F5E9);
  static const Color slotBookedBg = Color(0xFFFEEBEE);

  // --- BOOKING STATUS COLORS ---
  static const Color statusPending = Color(0xFFF57C00);
  static const Color statusPendingBg = Color(0xFFFFF8E1);
  static const Color statusPendingBorder = Color(0xFFFFCA28);
  static const Color statusConfirmed = Color(0xFF2E6A4F);
  static const Color statusConfirmedBg = Color(0xFFE8F5E9);
  static const Color statusCancelled = Color(0xFFD32F2F);
  static const Color statusCancelledBg = Color(0xFFFFEBEE);

  // --- FORM/INPUT COLORS ---
  static const Color inputFillLight = Color(0xFFF0F9F4);
  static const Color inputFillDark = Color(0xFF1A2E1F);
  static const Color readOnlyFill = Color(0xFFE2F3E9);
  static const Color divider = Color(0xFFE0ECE5);

  // --- CHART COLORS ---
  static const Color chartBlue = Color(0xFF2196F3);
  static const Color chartTeal = Color(0xFF009688);
  static const Color chartAmber = Color(0xFFFFC107);
  static const Color chartDeepOrange = Color(0xFFFF5722);
  static const Color chartIndigo = Color(0xFF3F51B5);

  static Color bookingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'confirmed':
      case 'completed':
        return statusConfirmed;
      case 'cancelled':
        return statusCancelled;
      default:
        return textSecondaryLight;
    }
  }

  static Color bookingStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPendingBg;
      case 'confirmed':
      case 'completed':
        return statusConfirmedBg;
      case 'cancelled':
        return statusCancelledBg;
      default:
        return borderLight;
    }
  }

  static Color bookingStatusBorderColor(String status) {
    if (status.toLowerCase() == 'pending') return statusPendingBorder;
    return borderLight;
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimaryLight,
        displayColor: textPrimaryLight,
      ),
      primaryColor: primaryDarkGreen,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryDarkGreen,
        secondary: accentOrange,
        surface: surfaceLight,
        error: error,
        onPrimary: white,
        onSurface: textPrimaryLight,
        onSecondary: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(color: textPrimaryLight, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDarkGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight),
        ),
      ),
      dividerColor: borderLight,
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimaryDark,
        displayColor: textPrimaryDark,
      ),
      primaryColor: primaryDarkGreen,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDarkGreen,
        secondary: accentOrange,
        surface: surfaceDark,
        error: error,
        onPrimary: white,
        onSurface: textPrimaryDark,
        onSecondary: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(color: textPrimaryDark, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        hintStyle: const TextStyle(color: Color(0xFF616161), fontSize: 13),
        labelStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDarkGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark),
        ),
      ),
      dividerColor: borderDark,
    );
  }
}
