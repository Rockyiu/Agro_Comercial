import 'dart:ui';

// Paleta do Gestão Rural, inspirada no agro brasileiro:
// verde da lavoura, amarelo do ouro da safra, terra roxa, céu do cerrado e o
// branco do algodão.
class AppColors {
  AppColors._();

  // --- Marca ---
  static const Color primary = Color(0xFF0E5E3A); // Verde lavoura
  static const Color primaryDark = Color(0xFF073A24); // Verde mata
  static const Color primaryLight = Color(0xFF1F8A55); // Verde broto
  static const Color primarySoft = Color(0xFFE2F1E7); // Fundo de destaques

  static const Color harvest = Color(0xFFF2B705); // Amarelo safra (ouro)
  static const Color harvestDark = Color(0xFFC98A00);
  static const Color harvestSoft = Color(0xFFFFF4CF);
  static const Color onHarvest = Color(0xFF3A2A00);

  static const Color earth = Color(0xFF8A4B26); // Terra roxa
  static const Color earthSoft = Color(0xFFF5E8DD);
  static const Color sky = Color(0xFF1F6FB2); // Céu do cerrado
  static const Color skySoft = Color(0xFFE1EEF8);
  static const Color water = Color(0xFF0F8B8D); // Irrigação / aplicação
  static const Color waterSoft = Color(0xFFDDF3F2);

  // --- Neutros ---
  static const Color background = Color(0xFFF5F6F0); // Branco algodão
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1EA);
  static const Color border = Color(0xFFDDE3DA);
  static const Color ink = Color(0xFF14231A); // Texto principal
  static const Color inkMuted = Color(0xFF5B6B61); // Texto secundário

  // --- Estados ---
  static const Color success = primaryLight;
  static const Color warning = Color(0xFFD97F00);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerSoft = Color(0xFFFDE7E7);

  // --- Gradientes ---
  static const List<Color> brandGradient = [primaryDark, primary, primaryLight];
  static const List<Color> harvestGradient = [Color(0xFFF7C736), harvest];

  // Nomes antigos, usados nas telas desde a primeira versão do app
  static const Color greenlightOne = primary;
  static const Color titleColor = surface;
  static const Color iceWhite = background;
  static const Color grey = ink;
  static const Color lightkGrey = inkMuted;
  static const List<Color> greenGradient = brandGradient;
}
