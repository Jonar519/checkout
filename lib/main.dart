import 'package:flutter/material.dart';
import 'screens/products_screen.dart';
import 'utils/encryption_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar encriptación
  await EncryptionHelper().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkout App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const ProductsScreen(),
    );
  }
}
