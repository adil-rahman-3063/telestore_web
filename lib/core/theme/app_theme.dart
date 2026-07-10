import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.grey50,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge:   AppTypography.display,
          headlineLarge:  AppTypography.h1,
          headlineMedium: AppTypography.h2,
          headlineSmall:  AppTypography.h3,
          titleLarge:     AppTypography.h4,
          bodyLarge:      AppTypography.bodyLarge,
          bodyMedium:     AppTypography.bodyMedium,
          bodySmall:      AppTypography.bodySmall,
          labelLarge:     AppTypography.labelLarge,
          labelMedium:    AppTypography.labelMedium,
          labelSmall:     AppTypography.labelSmall,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppTypography.h3.copyWith(
            color: AppColors.grey900,
          ),
          iconTheme: const IconThemeData(color: AppColors.grey900),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: AppTypography.buttonMedium,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.buttonMedium,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.buttonMedium,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.grey200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.grey200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          labelStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.grey500,
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.grey400,
          ),
          errorStyle: AppTypography.caption.copyWith(
            color: AppColors.error,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.grey200),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.grey100,
          selectedColor: AppColors.primarySurface,
          labelStyle: AppTypography.labelSmall,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.grey200),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.grey200,
          thickness: 0.5,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey400,
          selectedLabelStyle: AppTypography.captionMedium,
          unselectedLabelStyle: AppTypography.caption,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.grey900,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge:   AppTypography.display.copyWith(color: Colors.white),
          headlineLarge:  AppTypography.h1.copyWith(color: Colors.white),
          headlineMedium: AppTypography.h2.copyWith(color: Colors.white),
          headlineSmall:  AppTypography.h3.copyWith(color: Colors.white),
          titleLarge:     AppTypography.h4.copyWith(color: Colors.white),
          bodyLarge:      AppTypography.bodyLarge.copyWith(color: AppColors.grey300),
          bodyMedium:     AppTypography.bodyMedium.copyWith(color: AppColors.grey300),
          bodySmall:      AppTypography.bodySmall.copyWith(color: AppColors.grey400),
          labelLarge:     AppTypography.labelLarge.copyWith(color: AppColors.grey300),
          labelMedium:    AppTypography.labelMedium.copyWith(color: AppColors.grey400),
          labelSmall:     AppTypography.labelSmall.copyWith(color: AppColors.grey500),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.grey800,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: AppTypography.h3.copyWith(color: Colors.white),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: AppTypography.buttonMedium,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            textStyle: AppTypography.buttonMedium,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            side: const BorderSide(color: AppColors.primaryLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            textStyle: AppTypography.buttonMedium,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.grey800,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.grey700),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.grey700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle: AppTypography.labelMedium.copyWith(
            color: AppColors.grey500,
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.grey600,
          ),
          errorStyle: AppTypography.caption.copyWith(
            color: AppColors.error,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.grey800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.grey700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.grey700,
          selectedColor: AppColors.primaryDark,
          labelStyle: AppTypography.labelSmall.copyWith(
            color: AppColors.grey300,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.grey700),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.grey700,
          thickness: 0.5,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.grey800,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.grey500,
          selectedLabelStyle: AppTypography.captionMedium,
          unselectedLabelStyle: AppTypography.caption,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
