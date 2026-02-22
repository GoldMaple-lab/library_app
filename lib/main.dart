import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart'; 
import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  
  runApp(LibraryApp());
}

class LibraryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Library',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.indigo,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo, width: 2)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      home: LoginScreen(),
    );
  }
}

// ==========================================
// 1. หน้าเข้าสู่ระบบ (Login Screen)
// ==========================================
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [_userCtrl.text, _passCtrl.text]);

    setState(() => _isLoading = false);

    if (result.isNotEmpty) {
      final role = result.first['role'];
      final userId = result.first['id'] as int;
      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserHomeScreen(userId: userId)));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง!'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_library_rounded, size: 100, color: Colors.indigo),
              SizedBox(height: 16),
              Text('Smart Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
              Text('ระบบจัดการยืม-คืนหนังสือ', style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 40),
              TextField(
                controller: _userCtrl,
                decoration: InputDecoration(labelText: 'ชื่อผู้ใช้ (Username)', prefixIcon: Icon(Icons.person_outline)),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: 'รหัสผ่าน (Password)', prefixIcon: Icon(Icons.lock_outline)),
              ),
              SizedBox(height: 24),
              _isLoading 
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login, 
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                    child: Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                  ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())), 
                child: Text('ยังไม่มีบัญชี? สมัครสมาชิกที่นี่', style: TextStyle(fontSize: 16, color: Colors.indigo, fontWeight: FontWeight.bold))
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. หน้าสมัครสมาชิก (Register Screen)
// ==========================================
class RegisterScreen extends StatelessWidget {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('สมัครสมาชิก')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.indigo),
            SizedBox(height: 24),
            TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'ชื่อ-นามสกุล', prefixIcon: Icon(Icons.badge_outlined))),
            SizedBox(height: 16),
            TextField(controller: _userCtrl, decoration: InputDecoration(labelText: 'ชื่อผู้ใช้ (Username)', prefixIcon: Icon(Icons.person_outline))),
            SizedBox(height: 16),
            TextField(controller: _passCtrl, obscureText: true, decoration: InputDecoration(labelText: 'รหัสผ่าน (Password)', prefixIcon: Icon(Icons.lock_outline))),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (_nameCtrl.text.isEmpty || _userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'), backgroundColor: Colors.red));
                  return;
                }
                final db = await DatabaseHelper.instance.database;
                await db.insert('users', {'name': _nameCtrl.text, 'username': _userCtrl.text, 'password': _passCtrl.text, 'role': 'user'});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ'), backgroundColor: Colors.green));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              child: Text('ยืนยันการสมัคร', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. ฝั่งผู้ใช้งานทั่วไป (User Home Screen)
// ==========================================
class UserHomeScreen extends StatefulWidget {
  final int userId;
  UserHomeScreen({required this.userId});
  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final books = await DatabaseHelper.instance.getBooks();
    final history = await DatabaseHelper.instance.getUserHistory(widget.userId);
    setState(() { _books = books; _history = history; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'หาหนังสือ' : 'ประวัติของฉัน'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded), 
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())),
            tooltip: 'ออกจากระบบ',
          )
        ],
      ),
      body: _currentIndex == 0 ? _buildBookList() : _buildHistoryList(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'หาหนังสือ'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'ยืม-คืน'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 20),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        final available = book['available'] as int;
        final total = book['quantity'] as int;
        final isAvail = available > 0;

        return Card(
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: isAvail ? Colors.green.shade50 : Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.book, color: isAvail ? Colors.green : Colors.red),
            ),
            title: Text(book['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(isAvail ? '🟢 ว่าง ($available / $total เล่ม)' : '🔴 หมดชั่วคราว (0 / $total เล่ม)', 
                style: TextStyle(color: isAvail ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w500)),
            ),
            trailing: isAvail 
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade50, foregroundColor: Colors.indigo, elevation: 0),
                  child: Text('ยืม'),
                  onPressed: () async {
                    await DatabaseHelper.instance.borrowBook(book['id'], widget.userId);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ทำรายการยืมสำเร็จ!'), backgroundColor: Colors.green));
                  },
                ) 
              : null,
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) return Center(child: Text('ไม่มีประวัติการยืม', style: TextStyle(color: Colors.grey, fontSize: 16)));
    
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 20),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final isActive = item['status'] == 'Active';
        return Card(
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📅 วันที่ยืม: ${item['borrow_date']}'),
                  SizedBox(height: 4),
                  Text(isActive ? '⚠️ สถานะ: กำลังยืม' : '✅ คืนแล้วเมื่อ: ${item['return_date']}', 
                    style: TextStyle(color: isActive ? Colors.orange.shade700 : Colors.green.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            trailing: isActive ? ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade100, foregroundColor: Colors.deepOrange),
              child: Text('คืนหนังสือ', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                await DatabaseHelper.instance.returnBook(item['trans_id'], item['book_id']);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ทำรายการคืนหนังสือสำเร็จ!'), backgroundColor: Colors.green));
              },
            ) : Icon(Icons.check_circle_rounded, color: Colors.green, size: 32),
          ),
        );
      },
    );
  }
}

// ==========================================
// 4. ฝั่งผู้ดูแลระบบ (Admin Home Screen)
// ==========================================
class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 1; // เริ่มที่แท็บ 1 (คลังหนังสือ)
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _borrowedBooks = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() async {
    final m = await DatabaseHelper.instance.getMembers();
    final bk = await DatabaseHelper.instance.getBooks();
    final br = await DatabaseHelper.instance.getBorrowedBooks();
    setState(() { _members = m; _books = bk; _borrowedBooks = br; });
  }

  // --- ฟังก์ชันเพิ่มหนังสือ ---
  void _showAddBookModal() {
    final _titleCtrl = TextEditingController();
    final _qtyCtrl = TextEditingController(text: "1");
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เพิ่มหนังสือเข้าคลัง', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 20),
            TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: 'ชื่อหนังสือ', prefixIcon: Icon(Icons.menu_book))),
            SizedBox(height: 16),
            TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'จำนวนเล่ม', prefixIcon: Icon(Icons.numbers))),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              onPressed: () async {
                if (_titleCtrl.text.isEmpty || _qtyCtrl.text.isEmpty) return;
                int qty = int.tryParse(_qtyCtrl.text) ?? 1;
                await DatabaseHelper.instance.addBook(_titleCtrl.text, qty);
                _loadAdminData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เพิ่มหนังสือเรียบร้อย!'), backgroundColor: Colors.green));
              }, 
              child: Text('บันทึกข้อมูล', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ),
            SizedBox(height: 24),
          ],
        ),
      )
    );
  }

  // --- ฟังก์ชันแก้ไขหนังสือ ---
  void _showEditBookModal(Map<String, dynamic> book) {
    final _titleCtrl = TextEditingController(text: book['title']);
    final _qtyCtrl = TextEditingController(text: book['quantity'].toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('แก้ไขข้อมูลหนังสือ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 20),
            TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: 'ชื่อหนังสือ', prefixIcon: Icon(Icons.menu_book))),
            SizedBox(height: 16),
            TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'จำนวนเล่มทั้งหมด', prefixIcon: Icon(Icons.numbers))),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              onPressed: () async {
                if (_titleCtrl.text.isEmpty || _qtyCtrl.text.isEmpty) return;
                int newQty = int.tryParse(_qtyCtrl.text) ?? book['quantity'];
                
                await DatabaseHelper.instance.updateBook(
                  book['id'], _titleCtrl.text, newQty, book['quantity'], book['available']
                );
                
                _loadAdminData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ!'), backgroundColor: Colors.blue));
              }, 
              child: Text('บันทึกการเปลี่ยนแปลง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
            ),
            SizedBox(height: 24),
          ],
        ),
      )
    );
  }

  // --- ฟังก์ชันลบหนังสือ ---
  void _confirmDeleteBook(int bookId, String bookTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการลบหนังสือ'),
        content: Text('คุณต้องการลบหนังสือ "$bookTitle" ออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteBook(bookId);
              _loadAdminData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบหนังสือเรียบร้อยแล้ว'), backgroundColor: Colors.green));
            },
            child: Text('ยืนยันลบ'),
          ),
        ],
      ),
    );
  }

  // --- ฟังก์ชันลบ User ---
  void _confirmDeleteUser(int userId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยันการลบสมาชิก'),
        content: Text('คุณต้องการลบผู้ใช้ "$userName" ออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.deleteUser(userId);
              _loadAdminData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบสมาชิกเรียบร้อยแล้ว'), backgroundColor: Colors.green));
            },
            child: Text('ยืนยันลบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'จัดการสมาชิก' : _currentIndex == 1 ? 'คลังหนังสือทั้งหมด' : 'หนังสือที่ถูกยืม'),
        actions: [
          IconButton(icon: Icon(Icons.logout_rounded), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen())))
        ],
      ),
      body: _currentIndex == 0 ? _buildMembers() : _currentIndex == 1 ? _buildAllBooks() : _buildBorrowed(),
      
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton.extended(
        onPressed: _showAddBookModal,
        icon: Icon(Icons.add),
        label: Text('เพิ่มหนังสือ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
      ) : null,
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'สมาชิก'),
            BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'คลังหนังสือ'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'ถูกยืม'),
          ],
        ),
      ),
    );
  }

  Widget _buildMembers() {
    if (_members.isEmpty) return Center(child: Text('ไม่มีสมาชิกในระบบ'));
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return Card(
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(backgroundColor: Colors.indigo.shade100, child: Icon(Icons.person, color: Colors.indigo)),
            title: Text(member['name'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Username: ${member['username']}'),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDeleteUser(member['id'], member['name']),
              tooltip: 'ลบสมาชิก',
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllBooks() {
    if (_books.isEmpty) return Center(child: Text('คลังหนังสือว่างเปล่า'));
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final b = _books[index];
        return Card(
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(backgroundColor: Colors.indigo.shade50, child: Text('${b['id']}', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
            title: Text(b['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('คงเหลือ ${b['available']} เล่ม (จากทั้งหมด ${b['quantity']} เล่ม)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // ให้ Row หดตัวพอดีกับ Icon
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _showEditBookModal(b),
                  tooltip: 'แก้ไขหนังสือ',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteBook(b['id'], b['title']),
                  tooltip: 'ลบหนังสือ',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBorrowed() {
    if (_borrowedBooks.isEmpty) return Center(child: Text('ไม่มีหนังสือที่กำลังถูกยืม'));
    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _borrowedBooks.length,
      itemBuilder: (context, index) => Card(
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: Icon(Icons.book, color: Colors.orange)),
          title: Text(_borrowedBooks[index]['title'], style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text('👤 ผู้ยืม: ${_borrowedBooks[index]['name']}\n📅 วันที่ยืม: ${_borrowedBooks[index]['borrow_date']}'),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}