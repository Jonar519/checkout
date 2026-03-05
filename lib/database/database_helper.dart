import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/payment_data.dart';
import '../models/saved_payment_method.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'checkout.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        totalPrice REAL,
        paymentMethod TEXT,
        cardNumber TEXT,
        validUntil TEXT,
        cvv TEXT,
        cardHolder TEXT,
        saveCardForFuture INTEGER,
        promoCode TEXT,
        paymentDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_payment_methods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paymentMethod TEXT,
        cardNumber TEXT,
        cardHolder TEXT,
        validUntil TEXT,
        email TEXT,
        balance REAL,
        isDefault INTEGER,
        savedDate TEXT
      )
    ''');

    await _insertSampleProducts(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE saved_payment_methods(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          paymentMethod TEXT,
          cardNumber TEXT,
          cardHolder TEXT,
          validUntil TEXT,
          email TEXT,
          balance REAL,
          isDefault INTEGER,
          savedDate TEXT
        )
      ''');
    }
  }

  Future _insertSampleProducts(Database db) async {
    final existingProducts = await db.query('products');
    if (existingProducts.isNotEmpty) return;

    List<Map<String, dynamic>> products = [
      {
        'name': 'iPhone 15 Pro',
        'price': 5799900.00, // $5.799.900 COP
        'description': '256GB, Titanio Natural',
      },
      {
        'name': 'MacBook Pro 14"',
        'price': 8999900.00, // $8.999.900 COP
        'description': 'Chip M3, 16GB RAM, 512GB SSD',
      },
      {
        'name': 'AirPods Pro 2',
        'price': 899900.00, // $899.900 COP
        'description': 'Cancelación de ruido, USB-C',
      },
      {
        'name': 'Apple Watch Series 9',
        'price': 2199900.00, // $2.199.900 COP
        'description': 'GPS + Cellular, 45mm',
      },
      {
        'name': 'iPad Pro 12.9"',
        'price': 4599900.00, // $4.599.900 COP
        'description': 'M2, 256GB, Wi-Fi',
      },
      {
        'name': 'Samsung Galaxy S24 Ultra',
        'price': 5299900.00, // $5.299.900 COP
        'description': '512GB, Titanium Black',
      },
      {
        'name': 'Xiaomi Redmi Note 13',
        'price': 899900.00, // $899.900 COP
        'description': '8GB RAM, 256GB',
      },
    ];

    for (var product in products) {
      try {
        await db.insert('products', product);
      } catch (e) {
        print('Error insertando producto: $e');
      }
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('products');
      return List.generate(maps.length, (i) {
        return Product.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error obteniendo productos: $e');
      return [];
    }
  }

  Future<int> insertPayment(PaymentData payment) async {
    try {
      Database db = await database;
      return await db.insert('payments', payment.toMap());
    } catch (e) {
      print('Error insertando pago: $e');
      return -1;
    }
  }

  Future<int> insertSavedPaymentMethod(SavedPaymentMethod method) async {
    try {
      Database db = await database;

      if (method.isDefault) {
        await db.rawUpdate('UPDATE saved_payment_methods SET isDefault = 0');
      }

      return await db.insert('saved_payment_methods', method.toMap());
    } catch (e) {
      print('Error insertando método guardado: $e');
      return -1;
    }
  }

  Future<List<SavedPaymentMethod>> getSavedPaymentMethods() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'saved_payment_methods',
        orderBy: 'isDefault DESC, savedDate DESC',
      );
      return List.generate(maps.length, (i) {
        return SavedPaymentMethod.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error obteniendo métodos guardados: $e');
      return [];
    }
  }
}
