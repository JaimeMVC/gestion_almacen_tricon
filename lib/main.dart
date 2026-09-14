import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'models/perfil_usuario.dart';
import 'screens/almacenes_screen.dart';
import 'screens/carga_masiva_screen.dart';
import 'screens/despacho_screen.dart';
import 'screens/equipos_screen.dart';
import 'screens/exportaciones_screen.dart';
import 'screens/ingreso_material_screen.dart';
import 'screens/login_screen.dart';
import 'screens/materiales_screen.dart';
import 'screens/movimientos_screen.dart';
import 'screens/proveedores_screen.dart';
import 'screens/proyectos_screen.dart';
import 'screens/regiones_screen.dart';
import 'screens/remitos_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/transferencias_screen.dart';
import 'screens/ubicaciones_screen.dart';
import 'screens/usuarios_screen.dart';
import 'state/app_state.dart';
import 'state/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
  await sessionState.inicializar();
  runApp(const TriconWmsApp());
}

class TriconWmsApp extends StatelessWidget {
  const TriconWmsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TRICON WMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1E3A8A),
          scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        ),
        home: const AuthGate(),
      );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _datosCargados = false;
  bool _cargandoDatos = false;
  String? _errorDatos;

  @override
  void initState() {
    super.initState();
    sessionState.addListener(_actualizar);
    _prepararDatos();
  }

  @override
  void dispose() {
    sessionState.removeListener(_actualizar);
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
    _prepararDatos();
  }

  Future<void> _prepararDatos() async {
    if (!sessionState.autenticado || _datosCargados || _cargandoDatos) return;
    _cargandoDatos = true;
    _errorDatos = null;
    if (mounted) setState(() {});
    try {
      await Future.wait([
        appState.cargarMaterialesDesdeSupabase(),
        appState.cargarProyectosDesdeSupabase(),
        appState.cargarAlmacenesDesdeSupabase(),
        appState.cargarUbicacionesDesdeSupabase(),
        appState.cargarStockDesdeSupabase(),
        appState.cargarDatosRecepcionDesdeSupabase(),
        appState.cargarEquiposDesdeSupabase(),
      ]);
      _datosCargados = true;
    } catch (e) {
      _errorDatos = e.toString();
    } finally {
      _cargandoDatos = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (sessionState.inicializando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!sessionState.autenticado) {
      return LoginScreen(errorExterno: sessionState.error);
    }
    if (_cargandoDatos || !_datosCargados) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_errorDatos == null) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_errorDatos == null ? 'Cargando datos del almacén...' : 'No se pudieron cargar los datos.\n$_errorDatos', textAlign: TextAlign.center),
            if (_errorDatos != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: _prepararDatos, child: const Text('Reintentar')),
            ],
          ]),
        ),
      );
    }
    return const MainLayout();
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;

  static const pages = <Widget>[
    HomePage(),
    IngresoMaterialScreen(),
    StockScreen(),
    TransferenciasScreen(),
    DespachoScreen(),
    MovimientosScreen(),
    ProyectosScreen(),
    AlmacenesScreen(),
    MaterialesScreen(),
    UbicacionesScreen(),
    ProveedoresScreen(),
    RegionesScreen(),
    EquiposScreen(),
    RemitosScreen(),
    CargaMasivaScreen(),
    ExportacionesScreen(),
    ReportesScreen(),
    UsuariosScreen(),
  ];

  List<_MenuEntry> get menuItems => [
        const _MenuEntry.section('OPERACIÓN'),
        const _MenuEntry.item('Inicio', Icons.home, 0, Permisos.verInicio),
        const _MenuEntry.item('Recepción', Icons.add_box, 1, Permisos.recepcionar),
        const _MenuEntry.item('Stock', Icons.inventory_2, 2, Permisos.verStock),
        const _MenuEntry.item('Transferencias', Icons.swap_horiz, 3, Permisos.transferir),
        const _MenuEntry.item('Despacho', Icons.local_shipping, 4, Permisos.despachar),
        const _MenuEntry.item('Movimientos', Icons.history, 5, Permisos.verMovimientos),
        const _MenuEntry.section('MAESTROS'),
        const _MenuEntry.item('Proyectos', Icons.business_center, 6, Permisos.verMaestros),
        const _MenuEntry.item('Almacenes', Icons.warehouse, 7, Permisos.verMaestros),
        const _MenuEntry.item('Materiales', Icons.category, 8, Permisos.verMaestros),
        const _MenuEntry.item('Ubicaciones', Icons.location_on, 9, Permisos.verMaestros),
        const _MenuEntry.item('Proveedores', Icons.business, 10, Permisos.verMaestros),
        const _MenuEntry.item('Regiones', Icons.public, 11, Permisos.verMaestros),
        const _MenuEntry.item('Equipos', Icons.precision_manufacturing, 12, Permisos.verMaestros),
        const _MenuEntry.section('DOCUMENTOS'),
        const _MenuEntry.item('Remitos', Icons.receipt_long, 13, Permisos.verDocumentos),
        const _MenuEntry.section('DATOS'),
        const _MenuEntry.item('Carga masiva', Icons.upload_file, 14, Permisos.cargaMasiva),
        const _MenuEntry.item('Exportaciones', Icons.file_download, 15, Permisos.exportarDatos),
        const _MenuEntry.section('ANÁLISIS'),
        const _MenuEntry.item('Reportes', Icons.analytics, 16, Permisos.verReportes),
        const _MenuEntry.section('SEGURIDAD'),
        const _MenuEntry.item('Usuarios', Icons.manage_accounts, 17, Permisos.gestionarUsuarios),
      ];

  List<_MenuEntry> get visibles {
    final result = <_MenuEntry>[];
    _MenuEntry? pendingSection;
    for (final entry in menuItems) {
      if (entry.isSection) {
        pendingSection = entry;
      } else if (sessionState.puede(entry.permiso!)) {
        if (pendingSection != null) result.add(pendingSection);
        pendingSection = null;
        result.add(entry);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    if (!sessionState.puede(_permisoDePagina(selectedIndex))) selectedIndex = 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TRICON WMS'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text('${sessionState.perfil?.nombre ?? ''} · ${sessionState.perfil?.rol.etiqueta ?? ''}')),
          ),
          IconButton(tooltip: 'Cerrar sesión', onPressed: sessionState.cerrarSesion, icon: const Icon(Icons.logout)),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(children: [if (isDesktop) _buildSideMenu(), Expanded(child: pages[selectedIndex])]),
    );
  }

  String _permisoDePagina(int index) => switch (index) {
        1 => Permisos.recepcionar,
        2 => Permisos.verStock,
        3 => Permisos.transferir,
        4 => Permisos.despachar,
        5 => Permisos.verMovimientos,
        >= 6 && <= 12 => Permisos.verMaestros,
        13 => Permisos.verDocumentos,
        14 => Permisos.cargaMasiva,
        15 => Permisos.exportarDatos,
        16 => Permisos.verReportes,
        17 => Permisos.gestionarUsuarios,
        _ => Permisos.verInicio,
      };

  Widget _buildSideMenu() => Container(
        width: 270,
        color: const Color(0xFF111827),
        child: Column(children: [
          const SizedBox(height: 24),
          const Icon(Icons.warehouse, size: 46, color: Colors.white),
          const SizedBox(height: 8),
          const Text('TRICON WMS', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
          const Text('Warehouse Management System', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 18),
          Expanded(child: ListView(children: visibles.map(_menuWidget).toList())),
        ]),
      );

  Widget _menuWidget(_MenuEntry entry) {
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
  }

  Widget _buildDrawer() => Drawer(
        child: ListView(
          children: visibles.map((entry) {
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
              onTap: () { setState(() => selectedIndex = entry.pageIndex!); Navigator.pop(context); },
            );
          }).toList(),
        ),
      );
}

class _MenuEntry {
  final String title;
  final IconData? icon;
  final int? pageIndex;
  final bool isSection;
  final String? permiso;
  const _MenuEntry.section(this.title) : icon = null, pageIndex = null, permiso = null, isSection = true;
  const _MenuEntry.item(this.title, this.icon, this.pageIndex, this.permiso) : isSection = false;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Inicio', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Sesión: ${sessionState.perfil?.nombre} · ${sessionState.perfil?.rol.etiqueta}'),
          const SizedBox(height: 18),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('TRICON WMS v0.8.0 incorpora autenticación, roles, invitaciones y preparación multiempresa.'))),
        ]),
      );
}
