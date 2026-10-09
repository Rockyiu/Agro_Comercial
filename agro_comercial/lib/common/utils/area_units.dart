// Unidades de área usadas no cadastro da fazenda e nos relatórios
class AreaUnits {
  AreaUnits._();

  static const String hectare = 'ha';
  static const String alqueire = 'alq';

  // Alqueire paulista
  static const double hectaresPerAlqueire = 2.42;

  static const Map<String, String> labels = {
    hectare: 'Hectare (ha)',
    alqueire: 'Alqueire (2,42 ha)',
  };

  static String shortLabel(String unit) => unit == alqueire ? 'alq' : 'ha';

  static double toHectares(double area, String unit) =>
      unit == alqueire ? area * hectaresPerAlqueire : area;

  static double fromHectares(double hectares, String unit) =>
      unit == alqueire ? hectares / hectaresPerAlqueire : hectares;
}
