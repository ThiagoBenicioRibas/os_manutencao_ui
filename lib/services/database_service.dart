
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Gerencia a abertura e a estrutura do banco SQLite local.
///
/// Utiliza SQLite FFI para execução no Windows.
class DatabaseService {
  DatabaseService._() : _databasePathOverride = null;

  /// Permite utilizar um banco separado durante os testes.
  DatabaseService.forTesting(String databasePath)
      : _databasePathOverride = databasePath;

  static final DatabaseService instance = DatabaseService._();

  static const String _databaseName = 'os_manutencao.db';
  static const int _databaseVersion = 1;

  final String? _databasePathOverride;

  Future<Database>? _databaseFuture;

  /// Abre o banco na primeira chamada e reutiliza a conexão.
  Future<Database> get database =>
      _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    sqfliteFfiInit();

    final String databasePath;

    if (_databasePathOverride != null) {
      databasePath = _databasePathOverride;
    } else {
      final directory = await getApplicationSupportDirectory();
      databasePath = p.join(directory.path, _databaseName);
    }

    await Directory(
      p.dirname(databasePath),
    ).create(recursive: true);

    return databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createTables,
      ),
    );
  }

  /// Fecha a conexão e libera os recursos utilizados.
  Future<void> close() async {
    final databaseFuture = _databaseFuture;

    if (databaseFuture == null) {
      return;
    }

    final db = await databaseFuture;
    await db.close();

    _databaseFuture = null;
  }

  /// Cria as sete tabelas na primeira abertura do banco.
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        documento TEXT NOT NULL,
        telefone TEXT NOT NULL,
        email TEXT,
        endereco TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tecnicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        contato TEXT NOT NULL,
        especialidade TEXT NOT NULL,
        situacao TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE equipamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        marca TEXT,
        modelo TEXT,
        numero_serie TEXT,
        patrimonio TEXT,
        observacoes TEXT,
        FOREIGN KEY (cliente_id)
          REFERENCES clientes (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE ordens_servico (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        cliente_id INTEGER NOT NULL,
        equipamento_id INTEGER NOT NULL,
        tecnico_id INTEGER,
        descricao_problema TEXT NOT NULL,
        prioridade TEXT NOT NULL,
        status TEXT NOT NULL,
        data_abertura TEXT NOT NULL,
        prazo_previsto TEXT,
        data_conclusao TEXT,
        diagnostico TEXT,
        solucao TEXT,
        observacoes_atendimento TEXT,
        valor_mao_obra_centavos INTEGER NOT NULL DEFAULT 0
          CHECK (valor_mao_obra_centavos >= 0),
        FOREIGN KEY (cliente_id)
          REFERENCES clientes (id)
          ON DELETE RESTRICT,
        FOREIGN KEY (equipamento_id)
          REFERENCES equipamentos (id)
          ON DELETE RESTRICT,
        FOREIGN KEY (tecnico_id)
          REFERENCES tecnicos (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE itens_utilizados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordem_id INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        quantidade INTEGER NOT NULL
          CHECK (quantidade > 0),
        valor_unitario_centavos INTEGER NOT NULL
          CHECK (valor_unitario_centavos >= 0),
        FOREIGN KEY (ordem_id)
          REFERENCES ordens_servico (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE historico_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordem_id INTEGER NOT NULL,
        status_anterior TEXT,
        status_novo TEXT NOT NULL,
        data_alteracao TEXT NOT NULL,
        observacao TEXT,
        FOREIGN KEY (ordem_id)
          REFERENCES ordens_servico (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE evidencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordem_id INTEGER NOT NULL,
        caminho_arquivo TEXT NOT NULL,
        descricao TEXT,
        tipo TEXT,
        data_registro TEXT NOT NULL,
        FOREIGN KEY (ordem_id)
          REFERENCES ordens_servico (id)
          ON DELETE CASCADE
      )
    ''');
  }
}
