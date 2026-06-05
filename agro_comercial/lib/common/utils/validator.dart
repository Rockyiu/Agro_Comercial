class Validator {
  Validator._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Esse campo não pode ser vazio";
    }

    // Verifica se o usuário digitou pelo menos duas palavras (nome e sobrenome)
    if (value.trim().split(RegExp(r'\s+')).length < 2) {
      return "Digite seu nome e sobrenome";
    }

    // Aceita apenas letras (maiúsculas, minúsculas, acentos) e espaços
    final condition = RegExp(r"^[a-zA-ZÀ-ÿ\s]+$");
    if (!condition.hasMatch(value)) {
      return "Nome inválido. Digite um nome válido.";
    }

    return null;
  }

  static String? validateEmail(String? value) {
    final condition = RegExp(
      r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?",
    );
    if (value != null && value.isEmpty) {
      return "Esse campo não pode ser vazio.";
    }
    if (value != null && !condition.hasMatch(value)) {
      return "Email inválido. Digite um email válido.";
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final condition = RegExp(
      r"^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$",
    );
    if (value != null && value.isEmpty) {
      return "Esse campo não pode ser vazio.";
    }
    if (value != null && !condition.hasMatch(value)) {
      return "Senha inválida. Digite uma senha válida.";
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? passwordValue,
    String? confirmPasswordValue,
  ) {
    if (passwordValue != confirmPasswordValue) {
      return "As senhas são diferentes. Por favor, corrija para continuar";
    }
    return null;
  }

  static String? validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return "Esse campo não pode ser vazio";
    }

    // Remove caracteres não numéricos
    String numbers = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.length != 11) {
      return "CPF deve conter 11 dígitos";
    }

    // Verifica CPFs com números iguais (ex: 111.111.111-11)
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) {
      return "CPF inválido";
    }

    // Cálculo dos dígitos verificadores
    List<int> digits = numbers.split('').map(int.parse).toList();

    int calc1 = 0;
    for (int i = 0; i < 9; i++) {
      calc1 += digits[i] * (10 - i);
    }
    calc1 = (calc1 * 10) % 11;
    if (calc1 == 10) calc1 = 0;

    if (calc1 != digits[9]) {
      return "CPF inválido";
    }

    int calc2 = 0;
    for (int i = 0; i < 10; i++) {
      calc2 += digits[i] * (11 - i);
    }
    calc2 = (calc2 * 10) % 11;
    if (calc2 == 10) calc2 = 0;

    if (calc2 != digits[10]) {
      return "CPF inválido";
    }

    return null;
  }

  static String? validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Esse campo não pode ser vazio";
    }
    // Troca a vírgula por ponto para o Dart conseguir interpretar a casa decimal
    final sanitizedValue = value.replaceAll(',', '.');

    // Tenta converter para número. Se o resultado for nulo, é porque tem letras.
    if (double.tryParse(sanitizedValue) == null) {
      return "Digite apenas números válidos";
    }
    return null;
  }
}
