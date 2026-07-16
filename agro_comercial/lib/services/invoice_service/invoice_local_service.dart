import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:agro_comercial/common/models/invoice_model.dart';

class InvoiceLocalService {
  // Padrão Singleton para manter apenas uma conexão aberta com o banco
  static final InvoiceLocalService _instance = InvoiceLocalService._internal();
  static Database? _database;

  factory InvoiceLocalService() => _instance;

  InvoiceLocalService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Pega o diretório seguro do sistema (Android/iOS) para guardar o banco
    String path = join(await getDatabasesPath(), 'agro_comercial_invoices.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        accessKey TEXT,
        cadPro TEXT,
        pdfFilePath TEXT,
        issueDate INTEGER
      )
    ''');
  }

  // 1. Salvar uma nota baixada
  Future<int> insertInvoice(InvoiceModel invoice) async {
    final db = await database;
    return await db.insert(
      'invoices',
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 2. Buscar todas as notas de um CAD/PRO específico para listar na tela
  Future<List<InvoiceModel>> getInvoicesByCadPro(String cadPro) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'cadPro = ?',
      whereArgs: [cadPro],
      orderBy: 'issueDate DESC', // Traz as mais recentes primeiro
    );
    return maps.map((map) => InvoiceModel.fromMap(map)).toList();
  }

  // 3. A MÁGICA DO DOWNLOAD INCREMENTAL: Descobrir a data da última nota
  Future<int?> getLatestIssueDate(String cadPro) async {
    final db = await database;
    final result = await db.query(
      'invoices',
      columns: ['issueDate'],
      where: 'cadPro = ?',
      whereArgs: [cadPro],
      orderBy: 'issueDate DESC',
      limit: 1, // Pega apenas a mais nova
    );

    if (result.isNotEmpty) {
      return result.first['issueDate'] as int;
    }
    return null; // Retorna null se for a primeira vez que está baixando
  }
}
