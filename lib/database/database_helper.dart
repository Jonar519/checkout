import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/payment_data.dart';
import '../models/saved_payment_method.dart';
import '../utils/encryption_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  final EncryptionHelper _encryptor = EncryptionHelper();

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _encryptor.initialize(); // Inicializar encriptación
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'checkout_encrypted.db');
    return await openDatabase(
      path,
      version: 3, // Versión actualizada
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Tabla de productos (sin encriptar, no son sensibles)
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL,
        description TEXT
      )
    ''');

    // Tabla de pagos realizados (con campos encriptados)
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
        paymentDate TEXT,
        transactionHash TEXT
      )
    ''');

    // Tabla de métodos guardados (todo encriptado)
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
        savedDate TEXT,
        cardHash TEXT
      )
    ''');

    await _insertSampleProducts(db);

    print('✅ Base de datos creada con encriptación');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Migrar a versión encriptada
      await db.execute('ALTER TABLE payments ADD COLUMN transactionHash TEXT');
      await db.execute(
          'ALTER TABLE saved_payment_methods ADD COLUMN cardHash TEXT');
    }
  }

  Future _insertSampleProducts(Database db) async {
    final existingProducts = await db.query('products');
    if (existingProducts.isNotEmpty) return;

    List<Map<String, dynamic>> products = [
      {
        'name': 'iPhone 15 Pro',
        'price': 5799900.00,
        'description': '256GB, Titanio Natural',
      },
      {
        'name': 'MacBook Pro 14"',
        'price': 8999900.00,
        'description': 'Chip M3, 16GB RAM, 512GB SSD',
      },
      {
        'name': 'AirPods Pro 2',
        'price': 899900.00,
        'description': 'Cancelación de ruido, USB-C',
      },
      {
        'name': 'Apple Watch Series 9',
        'price': 2199900.00,
        'description': 'GPS + Cellular, 45mm',
      },
      {
        'name': 'iPad Pro 12.9"',
        'price': 4599900.00,
        'description': 'M2, 256GB, Wi-Fi',
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

  // Product CRUD (sin cambios)
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

  // Payment CRUD con encriptación
  Future<int> insertPayment(PaymentData payment) async {
    try {
      Database db = await database;

      // Crear hash de transacción
      final String dataToHash =
          '${payment.totalPrice}${payment.paymentMethod}${DateTime.now().millisecondsSinceEpoch}';
      final transactionHash = _encryptor.hashData(dataToHash);

      // Preparar datos (ya vienen encriptados del modelo)
      final Map<String, dynamic> paymentMap = payment.toMap();
      paymentMap['transactionHash'] = transactionHash;

      print('💰 Guardando pago encriptado: $transactionHash');
      return await db.insert('payments', paymentMap);
    } catch (e) {
      print('Error insertando pago: $e');
      return -1;
    }
  }

  Future<List<PaymentData>> getPayments() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('payments');
      return List.generate(maps.length, (i) {
        return PaymentData.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error obteniendo pagos: $e');
      return [];
    }
  }

  // Saved Payment Methods CRUD con encriptación
  Future<int> insertSavedPaymentMethod(SavedPaymentMethod method) async {
    try {
      Database db = await database;

      if (method.isDefault) {
        await db.rawUpdate('UPDATE saved_payment_methods SET isDefault = 0');
      }

      final Map<String, dynamic> methodMap = method.toMap();
      print('💾 Guardando método de pago encriptado');

      return await db.insert('saved_payment_methods', methodMap);
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

      print('🔍 Métodos guardados encontrados: ${maps.length}');
      return List.generate(maps.length, (i) {
        return SavedPaymentMethod.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error obteniendo métodos guardados: $e');
      return [];
    }
  }

  // Verificar integridad de datos
  Future<bool> verifyDataIntegrity() async {
    try {
      Database db = await database;
      final methods = await db.query('saved_payment_methods');

      for (var method in methods) {
        final savedMethod = SavedPaymentMethod.fromMap(method);
        if (savedMethod.cardNumber != null && savedMethod.cardHash != null) {
          final calculatedHash = _encryptor.hashData(savedMethod.cardNumber!);
          if (calculatedHash != savedMethod.cardHash) {
            print(
                '⚠️ ALERTA: Integridad comprometida para ID ${savedMethod.id}');
            return false;
          }
        }
      }
      print('✅ Verificación de integridad completada');
      return true;
    } catch (e) {
      print('Error verificando integridad: $e');
      return false;
    }
  }
}
