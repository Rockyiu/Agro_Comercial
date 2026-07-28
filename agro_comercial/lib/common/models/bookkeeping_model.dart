class BookkeepingModel {
  final String? id;
  final int dia;
  final int mes;
  final int ano;
  final String conta;
  final String historico;
  final double valor;
  final String? pdfUrl;
  final String tipo; // "Entrada" ou "Saída"

  BookkeepingModel({
    this.id,
    required this.dia,
    required this.mes,
    required this.ano,
    required this.conta,
    required this.historico,
    required this.valor,
    this.pdfUrl,
    String? tipo,
  }) : tipo = tipo ?? _definirTipoPelaConta(conta);

  // Regra de negócio: Contas 100 são Entradas. O resto (200, 300, 400, 500) é Saída.
  static String _definirTipoPelaConta(String conta) {
    if (conta.startsWith('1')) return 'Entrada';
    return 'Saída';
  }

  Map<String, dynamic> toMap() {
    return {
      'dia': dia,
      'mes': mes,
      'ano': ano,
      'conta': conta,
      'historico': historico,
      'valor': valor,
      'pdfUrl': pdfUrl,
      'tipo': tipo,
      'timestamp': DateTime(ano, mes + 1, dia).millisecondsSinceEpoch,
    };
  }

  factory BookkeepingModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return BookkeepingModel(
      id: documentId,
      dia: map['dia']?.toInt() ?? 1,
      mes: map['mes']?.toInt() ?? 0,
      ano: map['ano']?.toInt() ?? 2026,
      conta: map['conta'] ?? '',
      historico: map['historico'] ?? '',
      valor: map['valor']?.toDouble() ?? 0.0,
      pdfUrl: map['pdfUrl'],
      tipo: map['tipo'] ?? 'Saída',
    );
  }
}
