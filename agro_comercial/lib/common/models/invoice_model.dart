class InvoiceModel {
  final int? id; // O SQLite usa int autoincrement para o ID
  final String accessKey; // Chave de acesso da nota (44 dígitos)
  final String cadPro; // O CAD/PRO da fazenda para não misturar as notas
  final String
  pdfFilePath; // O caminho físico onde o arquivo foi salvo no celular
  final int
  issueDate; // Data de emissão em timestamp (essencial para buscar apenas as novas)

  InvoiceModel({
    this.id,
    required this.accessKey,
    required this.cadPro,
    required this.pdfFilePath,
    required this.issueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accessKey': accessKey,
      'cadPro': cadPro,
      'pdfFilePath': pdfFilePath,
      'issueDate': issueDate,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      accessKey: map['accessKey'],
      cadPro: map['cadPro'],
      pdfFilePath: map['pdfFilePath'],
      issueDate: map['issueDate'],
    );
  }
}
