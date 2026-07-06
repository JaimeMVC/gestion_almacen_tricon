import 'package:flutter/material.dart';

import 'screens/carga_masiva_screen.dart';
import 'screens/despacho_screen.dart';
import 'screens/exportaciones_screen.dart';
import 'screens/ingreso_material_screen.dart';
import 'screens/materiales_screen.dart';
import 'screens/movimientos_screen.dart';
import 'screens/remitos_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/ubicaciones_screen.dart';

void main() {
  runApp(const TriconWmsApp());
}

class TriconWmsApp extends StatelessWidget {
  const TriconWmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRICON WMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;

  final pages = const [
    HomePage(),
    IngresoMaterialScreen(),
    StockScreen(),
    DespachoScreen(),
    MovimientosScreen(),
    MaterialesScreen(),
    UbicacionesScreen(),
    RemitosScreen(),
    CargaMasivaScreen(),
    ExportacionesScreen(),
  ];

  final menuItems = const [
    _MenuEntry.section('OPERACIÓN'),
    _MenuEntry.item('Inicio', Icons.home, 0),
    _MenuEntry.item('Recepción', Icons.add_box, 1),
    _MenuEntry.item('Stock', Icons.inventory_2, 2),
    _MenuEntry.item('Despacho', Icons.local_shipping, 3),
    _MenuEntry.item('Movimientos', Icons.swap_horiz, 4),
    _MenuEntry.section('MAESTROS'),
    _MenuEntry.item('Materiales', Icons.category, 5),
    _MenuEntry.item('Ubicaciones', Icons.location_on, 6),
    _MenuEntry.section('DOCUMENTOS'),
    _MenuEntry.item('Remitos', Icons.receipt_long, 7),
    _MenuEntry.section('DATOS'),
    _MenuEntry.item('Carga masiva', Icons.upload_file, 8),
    _MenuEntry.item('Exportaciones', Icons.file_download, 9),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRICON WMS'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildSideMenu(),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    return Container(
      width: 270,
      color: const Color(0xFF111827),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.warehouse, size: 46, color: Colors.white),
          const SizedBox(height: 8),
          const Text('TRICON WMS', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
          const Text('Warehouse Management System', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final entry = menuItems[index];
                if (entry.isSection) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                    child: Text(entry.title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  );
                }

                final selected = selectedIndex == entry.pageIndex;
                return Material(
                  color: selected ? const Color(0xFF1E3A8A) : Colors.transparent,
                  child: ListTile(
                    leading: Icon(entry.icon, color: Colors.white),
                    title: Text(entry.title, style: const TextStyle(color: Colors.white)),
                    onTap: () => setState(() => selectedIndex = entry.pageIndex!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final entry = menuItems[index];
          if (entry.isSection) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              child: Text(entry.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            );
          }
          return ListTile(
            leading: Icon(entry.icon),
            title: Text(entry.title),
            selected: selectedIndex == entry.pageIndex,
            onTap: () {
              setState(() => selectedIndex = entry.pageIndex!);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

class _MenuEntry {
  final String title;
  final IconData? icon;
  final int? pageIndex;
  final bool isSection;

  const _MenuEntry.section(this.title)
      : icon = null,
        pageIndex = null,
        isSection = true;

  const _MenuEntry.item(this.title, this.icon, this.pageIndex) : isSection = false;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inicio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('TRICON WMS v0.4 - Carga masiva, exportaciones Excel y flujo operativo web.'),
          SizedBox(height: 18),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nota: esta versión todavía trabaja con datos en memoria. Sirve para pruebas operativas y validación de formatos. Para uso web real y permanente, el siguiente paso es Supabase/PostgreSQL.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
