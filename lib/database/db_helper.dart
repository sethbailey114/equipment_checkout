import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/borrower.dart';
import '../models/checkout.dart';
import '../models/equipment.dart';
import '../utils/helpers.dart';

/// A business-rule failure with a message that is safe to show to the user.
class DbException implements Exception {
  final String message;
  DbException(this.message);

  @override
  String toString() => message;
}

class DatabaseHelper {
  DatabaseHelper._();

  static const String _dbName = 'equipment_checkout.db';
  static const bool _seedSampleData = true;

  static Database? _database;

  /// Incremented after every write so any open screen can reload itself.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static void _notify() => changes.value++;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // SQLite ignores foreign keys unless this is switched on.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        condition TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE borrowers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        department TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE checkouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipment_id INTEGER NOT NULL,
        borrower_id INTEGER NOT NULL,
        checkout_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        return_date TEXT,
        status TEXT NOT NULL DEFAULT 'Active',
        FOREIGN KEY (equipment_id) REFERENCES equipment (id) ON DELETE RESTRICT,
        FOREIGN KEY (borrower_id) REFERENCES borrowers (id) ON DELETE RESTRICT
      )
    ''');

    // Database-level guarantee: at most one active checkout per equipment item.
    await db.execute('''
      CREATE UNIQUE INDEX idx_one_active_checkout
      ON checkouts (equipment_id)
      WHERE status = 'Active'
    ''');

    if (_seedSampleData) {
      final batch = db.batch();
      batch.insert('equipment',
          {'name': 'Dell XPS 15', 'category': 'Laptop', 'condition': 'Excellent'});
      batch.insert('equipment',
          {'name': 'Canon EOS R6', 'category': 'Camera', 'condition': 'Good'});
      batch.insert('equipment',
          {'name': 'iPad Air', 'category': 'Tablet', 'condition': 'Good'});
      batch.insert('equipment',
          {'name': 'Portable Projector', 'category': 'Other', 'condition': 'Fair'});
      batch.insert('borrowers', {
        'name': 'Jordan Lee',
        'email': 'jordan.lee@university.edu',
        'department': 'Computer Science',
      });
      batch.insert('borrowers', {
        'name': 'Priya Patel',
        'email': 'priya.patel@university.edu',
        'department': 'Physics',
      });
      await batch.commit(noResult: true);
    }
  }

  // ---------------------------------------------------------------- Equipment

  static const String _equipmentSelect = '''
    SELECT e.*,
      EXISTS(
        SELECT 1 FROM checkouts c
        WHERE c.equipment_id = e.id AND c.status = 'Active'
      ) AS is_checked_out,
      (SELECT COUNT(*) FROM checkouts c WHERE c.equipment_id = e.id)
        AS checkout_count
    FROM equipment e
  ''';

  static Future<List<Equipment>> getEquipment() async {
    final db = await database;
    final rows =
        await db.rawQuery('$_equipmentSelect ORDER BY e.name COLLATE NOCASE');
    return rows.map(Equipment.fromMap).toList();
  }

  static Future<List<Equipment>> getAvailableEquipment() async {
    final all = await getEquipment();
    return all.where((e) => !e.isCheckedOut).toList();
  }

  static Future<int> insertEquipment(Equipment equipment) async {
    final db = await database;
    final id = await db.insert('equipment', equipment.toMap());
    _notify();
    return id;
  }

  static Future<void> updateEquipment(Equipment equipment) async {
    final db = await database;
    await db.update(
      'equipment',
      equipment.toMap(),
      where: 'id = ?',
      whereArgs: [equipment.id],
    );
    _notify();
  }

  static Future<void> deleteEquipment(int id) async {
    final db = await database;
    final history = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM checkouts WHERE equipment_id = ?', [id])) ??
        0;
    if (history > 0) {
      throw DbException(
          'This equipment has checkout history and cannot be deleted.');
    }
    await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  // ---------------------------------------------------------------- Borrowers

  static const String _borrowerSelect = '''
    SELECT b.*,
      (SELECT COUNT(*) FROM checkouts c
        WHERE c.borrower_id = b.id AND c.status = 'Active') AS active_count,
      (SELECT COUNT(*) FROM checkouts c WHERE c.borrower_id = b.id)
        AS history_count
    FROM borrowers b
  ''';

  static Future<List<Borrower>> getBorrowers() async {
    final db = await database;
    final rows =
        await db.rawQuery('$_borrowerSelect ORDER BY b.name COLLATE NOCASE');
    return rows.map(Borrower.fromMap).toList();
  }

  static Future<Borrower?> getBorrower(int id) async {
    final db = await database;
    final rows = await db.rawQuery('$_borrowerSelect WHERE b.id = ?', [id]);
    return rows.isEmpty ? null : Borrower.fromMap(rows.first);
  }

  static Future<int> insertBorrower(Borrower borrower) async {
    final db = await database;
    final id = await db.insert('borrowers', borrower.toMap());
    _notify();
    return id;
  }

  static Future<void> updateBorrower(Borrower borrower) async {
    final db = await database;
    await db.update(
      'borrowers',
      borrower.toMap(),
      where: 'id = ?',
      whereArgs: [borrower.id],
    );
    _notify();
  }

  static Future<void> deleteBorrower(int id) async {
    final db = await database;
    final history = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM checkouts WHERE borrower_id = ?', [id])) ??
        0;
    if (history > 0) {
      throw DbException(
          'This borrower has checkout history and cannot be deleted.');
    }
    await db.delete('borrowers', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  // ---------------------------------------------------------------- Checkouts

  static const String _checkoutSelect = '''
    SELECT c.*, e.name AS equipment_name, b.name AS borrower_name
    FROM checkouts c
    JOIN equipment e ON e.id = c.equipment_id
    JOIN borrowers b ON b.id = c.borrower_id
  ''';

  /// All checkouts (newest first), or only active ones (soonest due first).
  static Future<List<Checkout>> getCheckouts({bool activeOnly = false}) async {
    final db = await database;
    final rows = activeOnly
        ? await db.rawQuery(
            "$_checkoutSelect WHERE c.status = 'Active' "
            'ORDER BY c.due_date ASC, c.id DESC',
          )
        : await db.rawQuery('$_checkoutSelect ORDER BY c.id DESC');
    return rows.map(Checkout.fromMap).toList();
  }

  static Future<List<Checkout>> getBorrowerCheckouts(int borrowerId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '$_checkoutSelect WHERE c.borrower_id = ? ORDER BY c.id DESC',
      [borrowerId],
    );
    return rows.map(Checkout.fromMap).toList();
  }

  static Future<void> createCheckout({
    required int equipmentId,
    required int borrowerId,
    required String checkoutDate,
    required String dueDate,
  }) async {
    if (dueDate.compareTo(checkoutDate) <= 0) {
      throw DbException('The due date must be later than the checkout date.');
    }

    final db = await database;
    // Everything runs in one transaction; any thrown error rolls it back.
    await db.transaction((txn) async {
      final borrower = await txn
          .query('borrowers', where: 'id = ?', whereArgs: [borrowerId]);
      if (borrower.isEmpty) {
        throw DbException('Please select a valid borrower.');
      }

      final equipment = await txn
          .query('equipment', where: 'id = ?', whereArgs: [equipmentId]);
      if (equipment.isEmpty) {
        throw DbException('Please select a valid equipment item.');
      }

      final active = Sqflite.firstIntValue(await txn.rawQuery(
            "SELECT COUNT(*) FROM checkouts "
            "WHERE equipment_id = ? AND status = 'Active'",
            [equipmentId],
          )) ??
          0;
      if (active > 0) {
        throw DbException('That equipment is already checked out.');
      }

      await txn.insert('checkouts', {
        'equipment_id': equipmentId,
        'borrower_id': borrowerId,
        'checkout_date': checkoutDate,
        'due_date': dueDate,
        'status': 'Active',
      });
    });
    _notify();
  }

  static Future<void> returnCheckout(int checkoutId) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn
          .query('checkouts', where: 'id = ?', whereArgs: [checkoutId]);
      if (rows.isEmpty) {
        throw DbException('Checkout record not found.');
      }
      if (rows.first['status'] == 'Returned') {
        throw DbException('This equipment has already been returned.');
      }

      // Only this one row is touched.
      await txn.update(
        'checkouts',
        {'status': 'Returned', 'return_date': todayString()},
        where: 'id = ? AND status = ?',
        whereArgs: [checkoutId, 'Active'],
      );
    });
    _notify();
  }
}