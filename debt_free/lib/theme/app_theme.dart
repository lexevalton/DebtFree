import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales (basées sur ton icône)
  static const Color primary = Color(0xFF0E7C47);       // Vert Émeraude Icône
  static const Color primaryDark = Color(0xFF0A5C35);   // Vert Forêt (Boutons CTA)
  static const Color primaryPressed = Color(0xFF074226);// Vert Pin (État pressé)
  static const Color accent = Color(0xFF2ECC71);        // Vert Menthe (Progression / Badges)

  // Arrière-plans & Surfaces
  static const Color background = Color(0xFFF2F9F5);    // Vert Sauge Très Pâle
  static const Color surface = Color(0xFFFFFFFF);       // Blanc Pur (Cartes)
  static const Color menuSelected = Color(0xFFE3F2EA);  // Vert Eau (Item menu actif)
  static const Color border = Color(0xFFC5DFD1);        // Vert Grisé Doux

  // Textes
  static const Color textPrimary = Color(0xFF0D261A);   // Vert Nuit Charbon
  static const Color textSecondary = Color(0xFF4A6658); // Gris Vert Ardoise

  // États sémantiques (utiles pour les dettes)
  static const Color error = Color(0xFFD9383A);         // Alerte / Retard
  static const Color warning = Color(0xFFE67E22);       // Échéance proche
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        outline: AppColors.border,
      ),

      // Barre d'application (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Boutons principaux (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            return AppColors.primaryDark;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // Boutons secondaires (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Cartes (Card)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Champs de texte (InputDecoration)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),

      // Menu de navigation bas (NavigationBar)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.menuSelected,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          );
        }),
      ),

      // Barres de progression (remboursement de dettes)
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.menuSelected,
      ),

      // Typographie
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
