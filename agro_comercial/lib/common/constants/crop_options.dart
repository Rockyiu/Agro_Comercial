// Culturas oferecidas no cadastro dos talhões
class CropOptions {
  CropOptions._();

  static const List<String> all = [
    'Soja',
    'Milho',
    'Trigo',
    'Café',
    'Olericultura',
    'Cana-de-açúcar',
    'Feijão',
    'Cenoura',
    'Tomate',
    'Algodão',
    'Laranja',
    'Pastagem',
    'Outro',
  ];

  // Lista para o Dropdown, incluindo a cultura já salva caso ela não exista
  // mais nas opções (ex: talhões antigos com a cultura digitada à mão)
  static List<String> withCurrent(String? current) {
    final value = current?.trim() ?? '';
    if (value.isEmpty || all.contains(value)) return all;
    return [value, ...all];
  }
}
