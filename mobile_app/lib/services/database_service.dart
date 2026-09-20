import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/muestra.dart';

/// Base de datos local (SQLite via sqflite): mantiene la cola offline y el
/// historial de muestras capturadas en este dispositivo, independiente de
/// la base de datos del backend (Fase 3). Esto es lo que permite que la
/// app siga funcionando -- y el operario no pierda su trabajo -- cuando
/// no hay señal en la planta.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _dbName = 'app_pacora.db';
  static const _dbVersion = 1;
  static const table = 'muestras';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id INTEGER,
            image_path TEXT NOT NULL,
            creado_en TEXT NOT NULL,
            estado TEXT NOT NULL,
            dosis_predicha_mg_l REAL,
            modelo TEXT,
            dosis_real_mg_l REAL,
            turbiedad_real_unt REAL,
            error_msg TEXT
          )
        ''');
      },
    );
  }

  Future<Muestra> insert(Muestra muestra) async {
    final db = await database;
    final id = await db.insert(table, muestra.toMap()..remove('id'));
    return muestra.copyWith(id: id);
  }

  Future<void> update(Muestra muestra) async {
    final db = await database;
    await db.update(
      table,
      muestra.toMap(),
      where: 'id = ?',
      whereArgs: [muestra.id],
    );
  }

  Future<List<Muestra>> listAll({int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      table,
      orderBy: 'creado_en DESC',
      limit: limit,
    );
    return rows.map(Muestra.fromMap).toList();
  }

  /// Muestras que aun no se han enviado con exito al backend: en cola o
  /// que fallaron y deben reintentarse.
  Future<List<Muestra>> listPendientes() async {
    final db = await database;
    final rows = await db.query(
      table,
      where: 'estado IN (?, ?)',
      whereArgs: [EstadoMuestra.enCola.name, EstadoMuestra.error.name],
      orderBy: 'creado_en ASC',
    );
    return rows.map(Muestra.fromMap).toList();
  }
}
