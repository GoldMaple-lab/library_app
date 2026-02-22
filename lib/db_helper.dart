import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('library_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. ตาราง Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, username TEXT, password TEXT, role TEXT
      )
    ''');
    
    // 2. ตาราง Books
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT, 
        quantity INTEGER, 
        available INTEGER
      )
    ''');
    
    // 3. ตาราง Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER, book_id INTEGER, 
        borrow_date TEXT, return_date TEXT, status TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (book_id) REFERENCES books (id)
      )
    ''');

    // ข้อมูลจำลอง (Mock Data)
    await db.rawInsert("INSERT INTO users (name, username, password, role) VALUES ('Admin Master', 'admin', '1234', 'admin')");
    await db.rawInsert("INSERT INTO users (name, username, password, role) VALUES ('สมชาย เรียนดี', 'user1', '1234', 'user')");
    
    // ใส่หนังสือพร้อมจำนวนเล่ม
    await db.rawInsert("INSERT INTO books (title, quantity, available) VALUES ('เขียนโปรแกรม Flutter', 5, 5)");
    await db.rawInsert("INSERT INTO books (title, quantity, available) VALUES ('ระบบเครือข่าย Cisco', 3, 3)");
    await db.rawInsert("INSERT INTO books (title, quantity, available) VALUES ('การวิเคราะห์ข้อมูล', 1, 1)");
  }

  // ---- ฟังก์ชันการทำงานฝั่งผู้ใช้ (User) ----
  Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await instance.database;
    return await db.query('books');
  }

  Future<void> borrowBook(int bookId, int userId) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE books SET available = available - 1 WHERE id = ?', [bookId]);
    await db.insert('transactions', {
      'user_id': userId, 'book_id': bookId,
      'borrow_date': DateTime.now().toString().split(' ')[0],
      'status': 'Active'
    });
  }

  Future<void> returnBook(int transactionId, int bookId) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE books SET available = available + 1 WHERE id = ?', [bookId]);
    await db.update('transactions', {
      'return_date': DateTime.now().toString().split(' ')[0],
      'status': 'Returned'
    }, where: 'id = ?', whereArgs: [transactionId]);
  }

  Future<List<Map<String, dynamic>>> getUserHistory(int userId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT t.id as trans_id, b.id as book_id, b.title, t.borrow_date, t.return_date, t.status 
      FROM transactions t JOIN books b ON t.book_id = b.id 
      WHERE t.user_id = ? ORDER BY t.id DESC
    ''', [userId]);
  }

  // ---- ฟังก์ชันการทำงานฝั่งผู้ดูแลระบบ (Admin) ----
  Future<List<Map<String, dynamic>>> getMembers() async {
    final db = await instance.database;
    return await db.query('users', where: 'role = ?', whereArgs: ['user']);
  }

  Future<void> deleteUser(int id) async {
    final db = await instance.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addBook(String title, int quantity) async {
    final db = await instance.database;
    await db.insert('books', {
      'title': title, 
      'quantity': quantity, 
      'available': quantity
    });
  }

  // ฟังก์ชันอัปเดตหนังสือ (ใหม่)
  Future<void> updateBook(int id, String title, int newQuantity, int oldQuantity, int oldAvailable) async {
    final db = await instance.database;
    int difference = newQuantity - oldQuantity;
    int newAvailable = oldAvailable + difference;
    
    // ป้องกันไม่ให้จำนวนที่ว่างติดลบ ในกรณีที่แอดมินลดยอดรวมลงมากกว่าจำนวนที่ถูกยืมไป
    if (newAvailable < 0) newAvailable = 0;

    await db.update('books', {
      'title': title,
      'quantity': newQuantity,
      'available': newAvailable
    }, where: 'id = ?', whereArgs: [id]);
  }

  // ฟังก์ชันลบหนังสือ (ใหม่)
  Future<void> deleteBook(int id) async {
    final db = await instance.database;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getBorrowedBooks() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT u.name, b.title, t.borrow_date 
      FROM transactions t 
      JOIN users u ON t.user_id = u.id 
      JOIN books b ON t.book_id = b.id 
      WHERE t.status = 'Active'
    ''');
  }
}