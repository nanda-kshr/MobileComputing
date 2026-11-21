import 'package:flutter/material.dart';
import 'screens/catalog_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  final ApiService? apiService;

  const PosApp({super.key, this.apiService});

  @override
  Widget build(BuildContext context) {
    final service = apiService ?? ApiService();

    return MaterialApp(
      title: 'POS & Inventory System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: CatalogScreen(apiService: service),
    );
  }
}
