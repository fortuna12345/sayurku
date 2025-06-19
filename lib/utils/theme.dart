import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  primarySwatch: Colors.green,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  scaffoldBackgroundColor: const Color(0xFFF8F8F8),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    primary: const Color(0xFF388E3C), // Green 700
    secondary: const Color(0xFF81C784), // Green 300
    background: const Color(0xFFF1F8E9), // Light green 50
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF4CAF50), // Green 500
    centerTitle: true,
    elevation: 2,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4CAF50), // Green 500
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF2E7D32), // Green 800
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  ),
  cardTheme: CardTheme(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.all(8),
    color: Colors.white,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFE8F5E9), // Light green 50
    labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
    selectedColor: const Color(0xFF4CAF50),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE8F5E9),
    thickness: 1,
    space: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF4CAF50),
    foregroundColor: Colors.white,
  ),
);