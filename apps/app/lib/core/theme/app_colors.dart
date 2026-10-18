import 'package:flutter/material.dart';

/// Paleta semântica de cores com alto contraste e acessibilidade para o Guia de Ensino.
abstract final class AppColors {
  // Cores Principais - Tema Claro
  static const Color primaryLight = Color(
    0xFF1E3A8A,
  ); // Azul Educacional Profundo
  static const Color onPrimaryLight = Colors.white;
  static const Color primaryContainerLight = Color(0xFFDBEAFE);
  static const Color onPrimaryContainerLight = Color(0xFF1E3A8A);

  static const Color secondaryLight = Color(0xFF0D9488); // Verde Azulado / Teal
  static const Color onSecondaryLight = Colors.white;
  static const Color secondaryContainerLight = Color(0xFFCCFBF1);
  static const Color onSecondaryContainerLight = Color(0xFF115E59);

  static const Color tertiaryLight = Color(
    0xFFD97706,
  ); // Âmbar / Replanejamento
  static const Color onTertiaryLight = Colors.white;
  static const Color tertiaryContainerLight = Color(0xFFFEF3C7);
  static const Color onTertiaryContainerLight = Color(0xFF92400E);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color surfaceVariantLight = Color(0xFFE2E8F0);
  static const Color onSurfaceVariantLight = Color(0xFF475569);

  // Cores Principais - Tema Escuro
  static const Color primaryDark = Color(0xFF93C5FD);
  static const Color onPrimaryDark = Color(0xFF1E3A8A);
  static const Color primaryContainerDark = Color(0xFF1E40AF);
  static const Color onPrimaryContainerDark = Color(0xFFDBEAFE);

  static const Color secondaryDark = Color(0xFF5EEAD4);
  static const Color onSecondaryDark = Color(0xFF115E59);
  static const Color secondaryContainerDark = Color(0xFF134E4A);
  static const Color onSecondaryContainerDark = Color(0xFFCCFBF1);

  static const Color tertiaryDark = Color(0xFFFCD34D);
  static const Color onTertiaryDark = Color(0xFF78350F);
  static const Color tertiaryContainerDark = Color(0xFF92400E);
  static const Color onTertiaryContainerDark = Color(0xFFFEF3C7);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color onSurfaceDark = Color(0xFFF8FAFC);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color onSurfaceVariantDark = Color(0xFFCBD5E1);

  // Estados Pedagógicos
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}
