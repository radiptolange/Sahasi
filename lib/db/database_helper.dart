import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// --- DATABASE HELPER ---
// This class manages the SQLite database for storing contacts.
class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sahasi.db');
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  // Create database tables
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      number TEXT NOT NULL,
      relation TEXT,
      is_selected INTEGER DEFAULT 1
    )
    ''');
  }

  // Handle database upgrades
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE contacts ADD COLUMN is_selected INTEGER DEFAULT 1");
    }
  }

  // Create a new contact
  Future<int> createContact(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('contacts', row);
  }

  // Read all contacts
  Future<List<Map<String, dynamic>>> readAllContacts() async {
    final db = await instance.database;
    return await db.query('contacts');
  }

  // Toggle contact selection
  Future<int> toggleSelection(int id, bool isSelected) async {
    final db = await instance.database;
    return await db.update('contacts', {'is_selected': isSelected ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  // Delete a contact
  Future<int> deleteContact(int id) async {
    final db = await instance.database;
    return await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}
