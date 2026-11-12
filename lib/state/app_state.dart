import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../models/almacen.dart';
import '../models/equipo.dart';
import '../models/material_item.dart';
import '../models/movimiento.dart';
import '../models/remito.dart';
import '../models/proveedor.dart';
import '../models/proyecto.dart';
import '../models/region_compra.dart';
import '../models/stock_item.dart';
import '../models/ubicacion.dart';
import '../repositories/almacen_repository.dart';
import '../repositories/catalogo_compra_repository.dart';
import '../repositories/equipo_repository.dart';
import '../repositories/material_repository.dart';
import '../repositories/movimiento_repository.dart';
import '../repositories/operacion_repository.dart';
import '../repositories/proyecto_repository.dart';
import '../repositories/stock_repository.dart';
import '../repositories/ubicacion_repository.dart';

class AppState extends ChangeNotifier {
  final List<Proyecto> _proyectos = [];
  bool _cargandoProyectos = false;
  String? _errorProyectos;

  final List<Almacen> _almacenes = [];
  bool _cargandoAlmacenes = false;
  String? _errorAlmacenes;

  final List<MaterialItem> _materiales = List.from(materialesDemo);
  final List<StockItem> _stock = [];
  bool _cargandoStock = false;
  String? _errorStock;
  final List<Ubicacion> _ubicaciones = [];
  bool _cargandoUbicaciones = false;
  String? _errorUbicaciones;
  final List<Movimiento> _movimientos = [];
  bool _cargandoMovimientos = false;
  String? _errorMovimientos;
  final List<Remito> _remitos = [];
  final List<Proveedor> _proveedores = [];
  final List<Equipo> _equipos = [];
  final List<RegionCompra> _regiones = [];
  bool _cargandoProveedores = false;
  bool _cargandoEquipos = false;
  String? _errorEquipos;
  String? _errorProveedores;
  bool _cargandoRegiones = false;
  String? _errorRegiones;
  bool _registrandoRecepcion = false;
  String? _errorRecepcion;
  bool _registrandoTransferencia = false;
  String? _errorTransferencia;
  bool _registrandoDespacho = false;
  String? _errorDespacho;

  List<Proyecto> get proyectos => List.unmodifiable(_proyectos);
  List<Proyecto> get proyectosActivos => _proyectos.where((p) => p.activo).toList(growable: false);
  bool get cargandoProyectos => _cargandoProyectos;
  String? get errorProyectos => _errorProyectos;

  List<Almacen> get almacenes => List.unmodifiable(_almacenes);
  bool get cargandoAlmacenes => _cargandoAlmacenes;
  String? get errorAlmacenes => _errorAlmacenes;
  List<Almacen> get almacenesActivos =>
      _almacenes.where((almacen) => almacen.activo).toList(growable: false);

  List<MaterialItem> get materiales => List.unmodifiable(_materiales);
  List<StockItem> get stock => List.unmodifiable(_stock);
  bool get cargandoStock => _cargandoStock;
  String? get errorStock => _errorStock;
  List<Ubicacion> get ubicaciones => List.unmodifiable(_ubicaciones);
  bool get cargandoUbicaciones => _cargandoUbicaciones;
  String? get errorUbicaciones => _errorUbicaciones;
  List<Ubicacion> get ubicacionesActivas =>
      _ubicaciones.where((ubicacion) => ubicacion.activa).toList(growable: false);

  bool get cargandoMovimientos => _cargandoMovimientos;
  String? get errorMovimientos => _errorMovimientos;

  List<Movimiento> get movimientos {
    final lista = List<Movimiento>.from(_movimientos);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  List<Proveedor> get proveedores => List.unmodifiable(_proveedores);
  List<Equipo> get equipos => List.unmodifiable(_equipos);
  List<Equipo> get equiposActivos => _equipos.where((e) => e.activo).toList(growable: false);
  bool get cargandoEquipos => _cargandoEquipos;
  String? get errorEquipos => _errorEquipos;
  List<RegionCompra> get regiones => List.unmodifiable(_regiones);
  List<Proveedor> get proveedoresActivos =>
      _proveedores.where((p) => p.activo).toList(growable: false);
  List<RegionCompra> get regionesActivas =>
      _regiones.where((r) => r.activa).toList(growable: false);
  bool get cargandoProveedores => _cargandoProveedores;
  String? get errorProveedores => _errorProveedores;
  bool get cargandoRegiones => _cargandoRegiones;
  String? get errorRegiones => _errorRegiones;
  bool get registrandoRecepcion => _registrandoRecepcion;
  String? get errorRecepcion => _errorRecepcion;
  bool get registrandoTransferencia => _registrandoTransferencia;
  String? get errorTransferencia => _errorTransferencia;
  bool get registrandoDespacho => _registrandoDespacho;
  String? get errorDespacho => _errorDespacho;

  List<Remito> get remitos {
    final lista = List<Remito>.from(_remitos);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  List<String> get familias {
    final lista = _materiales.map((m) => m.familia).toSet().toList();
    lista.sort();
    return ['Todas', ...lista];
  }

  void guardarMaterialMaestro(MaterialItem material, {String? codigoOriginal}) {
    final codigoBuscado = codigoOriginal ?? material.codigo;
    final index = _materiales.indexWhere(
      (m) => m.codigo.toLowerCase() == codigoBuscado.toLowerCase(),
    );

    if (index >= 0) {
      _materiales[index] = material;
      for (final item in _stock) {
        if (item.material.codigo.toLowerCase() == codigoBuscado.toLowerCase()) {
          item.material = material;
        }
      }
    } else {
      final existe = _materiales.any(
        (m) => m.codigo.toLowerCase() == material.codigo.toLowerCase(),
      );
      if (!existe) _materiales.add(material);
    }

    notifyListeners();
  }

  bool existeMaterial(String codigo) {
    return _materiales.any((m) => m.codigo.toLowerCase() == codigo.toLowerCase());
  }

  void guardarUbicacion(Ubicacion ubicacion) {
    final index = _ubicaciones.indexWhere((u) {
      if (ubicacion.id.isNotEmpty && u.id == ubicacion.id) return true;
      return u.almacenId == ubicacion.almacenId &&
          u.codigo.toLowerCase() == ubicacion.codigo.toLowerCase();
    });

    if (index >= 0) {
      _ubicaciones[index] = ubicacion;
    } else {
      _ubicaciones.add(ubicacion);
    }

    notifyListeners();
  }

  bool existeUbicacion(String codigo, {String? almacenId}) {
    return _ubicaciones.any((u) {
      final coincideCodigo =
          u.codigo.toLowerCase() == codigo.toLowerCase();
      return coincideCodigo &&
          (almacenId == null || almacenId.isEmpty || u.almacenId == almacenId);
    });
  }

  void ingresarStock({
    required MaterialItem material,
    required String ubicacion,
    required num cantidad,
    String usuario = 'Operador',
    String observacion = '',
  }) {
    final materialFinal = _obtenerOCrearMaterial(material);
    _crearUbicacionSiNoExiste(ubicacion);

    final indexStock = _stock.indexWhere(
      (s) =>
          s.material.codigo.toLowerCase() == materialFinal.codigo.toLowerCase() &&
          s.ubicacion.toLowerCase() == ubicacion.toLowerCase(),
    );

    if (indexStock >= 0) {
      _stock[indexStock].cantidad += cantidad;
    } else {
      _stock.add(StockItem(material: materialFinal, ubicacion: ubicacion, cantidad: cantidad));
    }

    registrarMovimiento(
      Movimiento(
        fecha: DateTime.now(),
        tipo: 'INGRESO',
        codigoMaterial: materialFinal.codigo,
        nombreMaterial: materialFinal.nombre,
        cantidad: cantidad,
        ubicacionDestino: ubicacion,
        usuario: usuario,
        observacion: observacion,
      ),
    );

    notifyListeners();
  }

  bool despacharStock({
    required StockItem stockItem,
    required num cantidad,
    required String destino,
    required String usuario,
    String observacion = '',
  }) {
    final index = _stock.indexWhere(
      (s) =>
          s.material.codigo.toLowerCase() == stockItem.material.codigo.toLowerCase() &&
          s.ubicacion.toLowerCase() == stockItem.ubicacion.toLowerCase(),
    );

    if (index < 0) return false;
    if (_stock[index].cantidad < cantidad) return false;

    _stock[index].cantidad -= cantidad;

    registrarMovimiento(
      Movimiento(
        fecha: DateTime.now(),
        tipo: 'DESPACHO',
        codigoMaterial: stockItem.material.codigo,
        nombreMaterial: stockItem.material.nombre,
        cantidad: cantidad,
        ubicacionOrigen: stockItem.ubicacion,
        ubicacionDestino: destino,
        usuario: usuario,
        observacion: observacion,
      ),
    );

    _remitos.add(
      Remito(
        numero: _generarNumeroRemito(),
        fecha: DateTime.now(),
        codigoMaterial: stockItem.material.codigo,
        nombreMaterial: stockItem.material.nombre,
        cantidad: cantidad,
        ubicacionOrigen: stockItem.ubicacion,
        destino: destino,
        despachadoPor: usuario,
        observacion: observacion,
      ),
    );

    if (_stock[index].cantidad <= 0) {
      _stock.removeAt(index);
    }

    notifyListeners();
    return true;
  }

  void cargaMasivaMateriales(List<MaterialItem> materiales) {
    for (final material in materiales) {
      guardarMaterialMaestro(material);
    }
    notifyListeners();
  }

  void cargaMasivaUbicaciones(List<Ubicacion> ubicaciones) {
    for (final ubicacion in ubicaciones) {
      guardarUbicacion(ubicacion);
    }
    notifyListeners();
  }

  void cargaMasivaStock(List<StockItem> items) {
    for (final item in items) {
      ingresarStock(
        material: item.material,
        ubicacion: item.ubicacion,
        cantidad: item.cantidad,
        usuario: 'Carga masiva',
        observacion: 'Carga masiva desde Excel',
      );
    }
    notifyListeners();
  }

  void registrarMovimiento(Movimiento movimiento) {
    _movimientos.add(movimiento);
  }

  MaterialItem _obtenerOCrearMaterial(MaterialItem material) {
    final index = _materiales.indexWhere(
      (m) => m.codigo.toLowerCase() == material.codigo.toLowerCase(),
    );
    if (index >= 0) return _materiales[index];
    _materiales.add(material);
    return material;
  }

  void _crearUbicacionSiNoExiste(String codigo) {
    if (!existeUbicacion(codigo)) {
      _ubicaciones.add(Ubicacion(codigo: codigo, descripcion: 'Creada automáticamente'));
    }
  }

  String _generarNumeroRemito() {
    final numero = _remitos.length + 1;
    return 'REM-${numero.toString().padLeft(6, '0')}';
  }


  Future<void> cargarProyectosDesdeSupabase() async {
    _cargandoProyectos = true;
    _errorProyectos = null;
    notifyListeners();
    try {
      final proyectos = await proyectoRepository.obtenerTodos();
      _proyectos
        ..clear()
        ..addAll(proyectos);
    } catch (error) {
      _errorProyectos = 'No se pudieron cargar los proyectos: $error';
    } finally {
      _cargandoProyectos = false;
      notifyListeners();
    }
  }

  Future<void> guardarProyectoEnSupabase(Proyecto proyecto) async {
    _errorProyectos = null;
    try {
      await proyectoRepository.guardar(proyecto);
      await cargarProyectosDesdeSupabase();
      await cargarAlmacenesDesdeSupabase();
    } catch (error) {
      _errorProyectos = 'No se pudo guardar el proyecto: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cambiarEstadoProyecto({required Proyecto proyecto, required bool activo}) async {
    _errorProyectos = null;
    try {
      await proyectoRepository.cambiarEstado(id: proyecto.id, activo: activo);
      await cargarProyectosDesdeSupabase();
    } catch (error) {
      _errorProyectos = 'No se pudo cambiar el estado del proyecto: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cargarAlmacenesDesdeSupabase() async {
    _cargandoAlmacenes = true;
    _errorAlmacenes = null;
    notifyListeners();

    try {
      final almacenes = await almacenRepository.obtenerTodos();
      _almacenes
        ..clear()
        ..addAll(almacenes);
    } catch (error) {
      _errorAlmacenes = 'No se pudieron cargar los almacenes: $error';
    } finally {
      _cargandoAlmacenes = false;
      notifyListeners();
    }
  }

  Future<void> guardarAlmacenEnSupabase(Almacen almacen) async {
    _errorAlmacenes = null;
    try {
      await almacenRepository.guardar(almacen);
      await cargarAlmacenesDesdeSupabase();
    } catch (error) {
      _errorAlmacenes = 'No se pudo guardar el almacén: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cambiarEstadoAlmacen({
    required Almacen almacen,
    required String estado,
  }) async {
    _errorAlmacenes = null;
    try {
      await almacenRepository.cambiarEstado(
        id: almacen.id,
        estado: estado,
      );
      await cargarAlmacenesDesdeSupabase();
    } catch (error) {
      _errorAlmacenes = 'No se pudo cambiar el estado del almacén: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cargarUbicacionesDesdeSupabase() async {
    _cargandoUbicaciones = true;
    _errorUbicaciones = null;
    notifyListeners();

    try {
      final ubicaciones = await ubicacionRepository.obtenerTodas();
      _ubicaciones
        ..clear()
        ..addAll(ubicaciones);
    } catch (error) {
      _errorUbicaciones = 'No se pudieron cargar las ubicaciones: $error';
    } finally {
      _cargandoUbicaciones = false;
      notifyListeners();
    }
  }

  Future<void> guardarUbicacionEnSupabase(Ubicacion ubicacion) async {
    _errorUbicaciones = null;
    try {
      await ubicacionRepository.guardar(ubicacion);
      await cargarUbicacionesDesdeSupabase();
    } catch (error) {
      _errorUbicaciones = 'No se pudo guardar la ubicación: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cambiarEstadoUbicacion({
    required Ubicacion ubicacion,
    required bool activa,
  }) async {
    _errorUbicaciones = null;
    try {
      await ubicacionRepository.cambiarEstado(
        id: ubicacion.id,
        activa: activa,
      );
      await cargarUbicacionesDesdeSupabase();
    } catch (error) {
      _errorUbicaciones = 'No se pudo cambiar el estado de la ubicación: $error';
      notifyListeners();
      rethrow;
    }
  }


  Future<void> cargarEquiposDesdeSupabase() async {
    _cargandoEquipos = true;
    _errorEquipos = null;
    notifyListeners();
    try {
      final equipos = await equipoRepository.obtenerEquipos(soloActivos: false);
      _equipos
        ..clear()
        ..addAll(equipos);
    } catch (error) {
      _errorEquipos = 'No se pudieron cargar los equipos: $error';
    } finally {
      _cargandoEquipos = false;
      notifyListeners();
    }
  }

  Future<void> guardarEquipoEnSupabase(Equipo equipo) async {
    _errorEquipos = null;
    try {
      await equipoRepository.guardarEquipo(equipo);
      await cargarEquiposDesdeSupabase();
    } catch (error) {
      _errorEquipos = 'No se pudo guardar el equipo: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<int> cargaMasivaEquipos(List<Equipo> equipos) async {
    _errorEquipos = null;
    var importados = 0;
    try {
      final existentes = _equipos.map((e) => e.codigo.trim().toLowerCase()).toSet();
      for (final equipo in equipos) {
        final key = equipo.codigo.trim().toLowerCase();
        if (existentes.contains(key)) continue;
        await equipoRepository.guardarEquipo(equipo);
        existentes.add(key);
        importados++;
      }
      await cargarEquiposDesdeSupabase();
      return importados;
    } catch (error) {
      _errorEquipos = 'No se pudo completar la carga masiva de equipos: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cambiarEstadoEquipo({required Equipo equipo, required bool activo}) async {
    _errorEquipos = null;
    try {
      await equipoRepository.cambiarEstado(id: equipo.id, activo: activo);
      await cargarEquiposDesdeSupabase();
    } catch (error) {
      _errorEquipos = 'No se pudo cambiar el estado del equipo: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cargarProveedoresDesdeSupabase() async {
    _cargandoProveedores = true;
    _errorProveedores = null;
    notifyListeners();
    try {
      final proveedores =
          await catalogoCompraRepository.obtenerProveedores(soloActivos: false);
      _proveedores
        ..clear()
        ..addAll(proveedores);
    } catch (error) {
      _errorProveedores = 'No se pudieron cargar los proveedores: $error';
    } finally {
      _cargandoProveedores = false;
      notifyListeners();
    }
  }

  Future<void> guardarProveedorEnSupabase(Proveedor proveedor) async {
    _errorProveedores = null;
    try {
      await catalogoCompraRepository.guardarProveedor(proveedor);
      await cargarProveedoresDesdeSupabase();
    } catch (error) {
      _errorProveedores = 'No se pudo guardar el proveedor: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cambiarEstadoProveedor({
    required Proveedor proveedor,
    required bool activo,
  }) async {
    try {
      await catalogoCompraRepository.cambiarEstadoProveedor(
        id: proveedor.id,
        activo: activo,
      );
      await cargarProveedoresDesdeSupabase();
    } catch (error) {
      _errorProveedores = 'No se pudo cambiar el estado del proveedor: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cargarRegionesDesdeSupabase() async {
    _cargandoRegiones = true;
    _errorRegiones = null;
    notifyListeners();
    try {
      final regiones =
          await catalogoCompraRepository.obtenerRegiones(soloActivas: false);
      _regiones
        ..clear()
        ..addAll(regiones);
    } catch (error) {
      _errorRegiones = 'No se pudieron cargar las regiones: $error';
    } finally {
      _cargandoRegiones = false;
      notifyListeners();
    }
  }

  Future<void> guardarRegionEnSupabase(RegionCompra region) async {
    _errorRegiones = null;
    try {
      await catalogoCompraRepository.guardarRegion(region);
      await cargarRegionesDesdeSupabase();
    } catch (error) {
      _errorRegiones = 'No se pudo guardar la región: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cambiarEstadoRegion({
    required RegionCompra region,
    required bool activa,
  }) async {
    try {
      await catalogoCompraRepository.cambiarEstadoRegion(
        id: region.id,
        activa: activa,
      );
      await cargarRegionesDesdeSupabase();
    } catch (error) {
      _errorRegiones = 'No se pudo cambiar el estado de la región: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cargarDatosRecepcionDesdeSupabase() async {
    await Future.wait([
      cargarProveedoresDesdeSupabase(),
      cargarRegionesDesdeSupabase(),
    ]);
  }

  Future<void> registrarRecepcionEnSupabase({
    required MaterialItem material,
    required Almacen almacen,
    required Ubicacion ubicacion,
    required num cantidad,
    required num costoUnitario,
    required String moneda,
    Proveedor? proveedor,
    RegionCompra? region,
    String ordenCompra = '',
    String factura = '',
    DateTime? fechaCompra,
    String usuario = '',
    String observacion = '',
  }) async {
    if (material.id.isEmpty) {
      throw StateError('El material no tiene un ID válido de Supabase.');
    }
    if (almacen.id.isEmpty || ubicacion.id.isEmpty) {
      throw StateError('El almacén o la ubicación no tienen un ID válido.');
    }

    _registrandoRecepcion = true;
    _errorRecepcion = null;
    notifyListeners();

    try {
      await operacionRepository.registrarRecepcion(
        materialId: material.id,
        almacenId: almacen.id,
        ubicacionId: ubicacion.id,
        cantidad: cantidad,
        costoUnitario: costoUnitario,
        moneda: moneda,
        proveedorId: proveedor?.id,
        regionId: region?.id,
        ordenCompra: ordenCompra,
        factura: factura,
        fechaCompra: fechaCompra,
        usuario: usuario,
        observacion: observacion,
      );
      await cargarStockDesdeSupabase();
    } catch (error) {
      _errorRecepcion = 'No se pudo registrar la recepción: $error';
      rethrow;
    } finally {
      _registrandoRecepcion = false;
      notifyListeners();
    }
  }


  Future<String> registrarTransferenciaEnSupabase({
    required StockItem stockOrigen,
    required Almacen almacenDestino,
    required Ubicacion ubicacionDestino,
    required num cantidad,
    String usuario = '',
    String observacion = '',
  }) async {
    if (stockOrigen.materialId.isEmpty ||
        stockOrigen.almacenId.isEmpty ||
        stockOrigen.ubicacionId.isEmpty) {
      throw StateError('La posición de stock de origen no tiene IDs válidos.');
    }
    if (almacenDestino.id.isEmpty || ubicacionDestino.id.isEmpty) {
      throw StateError('El almacén o la ubicación destino no tienen IDs válidos.');
    }
    if (cantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que cero.');
    }
    if (cantidad > stockOrigen.cantidad) {
      throw StateError('La cantidad supera el stock disponible.');
    }

    _registrandoTransferencia = true;
    _errorTransferencia = null;
    notifyListeners();

    try {
      final remitoId = await operacionRepository.registrarTransferencia(
        materialId: stockOrigen.materialId,
        almacenOrigenId: stockOrigen.almacenId,
        ubicacionOrigenId: stockOrigen.ubicacionId,
        almacenDestinoId: almacenDestino.id,
        ubicacionDestinoId: ubicacionDestino.id,
        cantidad: cantidad,
        usuario: usuario,
        observacion: observacion,
      );
      await cargarStockDesdeSupabase();
      return remitoId;
    } catch (error) {
      _errorTransferencia = 'No se pudo registrar la transferencia: $error';
      rethrow;
    } finally {
      _registrandoTransferencia = false;
      notifyListeners();
    }
  }


  Future<String> registrarSalidaConsumoMultipleEnSupabase({
    required List<Map<String, dynamic>> items,
    required String almacenOrigenId,
    required String destinoExterno,
    String? equipoId,
    String usuario = '',
    String observacion = '',
  }) async {
    if (_registrandoDespacho) throw StateError('Ya hay un despacho en curso.');
    if (items.isEmpty) throw ArgumentError('Agregue al menos un material.');
    if (almacenOrigenId.isEmpty) throw ArgumentError('Seleccione un almacén.');
    if (equipoId == null && destinoExterno.trim().isEmpty) {
      throw ArgumentError('Seleccione un equipo o indique el destino.');
    }
    _registrandoDespacho = true;
    _errorDespacho = null;
    notifyListeners();
    try {
      final remitoId = await operacionRepository.registrarSalidaConsumoMultiple(
        almacenOrigenId: almacenOrigenId,
        items: items,
        destinoExterno: destinoExterno,
        equipoId: equipoId,
        usuario: usuario,
        observacion: observacion,
      );
      await cargarStockDesdeSupabase();
      // El historial se consulta por páginas al entrar en Movimientos.
      return remitoId;
    } catch (error) {
      _errorDespacho = 'No se pudo registrar el despacho: $error';
      rethrow;
    } finally {
      _registrandoDespacho = false;
      notifyListeners();
    }
  }

  Future<String> registrarSalidaConsumoEnSupabase({
    required StockItem stockOrigen,
    required num cantidad,
    required String destinoExterno,
    String? equipoId,
    String usuario = '',
    String observacion = '',
  }) async {
    if (stockOrigen.materialId.isEmpty ||
        stockOrigen.almacenId.isEmpty ||
        stockOrigen.ubicacionId.isEmpty) {
      throw StateError('La posición de stock no tiene IDs válidos.');
    }
    if (cantidad <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que cero.');
    }
    if (cantidad > stockOrigen.cantidad) {
      throw StateError('La cantidad supera el stock disponible.');
    }
    if (destinoExterno.trim().isEmpty) {
      throw ArgumentError('Debe indicar el destino o proyecto de consumo.');
    }

    _registrandoDespacho = true;
    _errorDespacho = null;
    notifyListeners();

    try {
      final remitoId = await operacionRepository.registrarSalidaConsumo(
        materialId: stockOrigen.materialId,
        almacenOrigenId: stockOrigen.almacenId,
        ubicacionOrigenId: stockOrigen.ubicacionId,
        cantidad: cantidad,
        destinoExterno: destinoExterno,
        equipoId: equipoId,
        usuario: usuario,
        observacion: observacion,
      );
      await cargarStockDesdeSupabase();
      return remitoId;
    } catch (error) {
      _errorDespacho = 'No se pudo registrar el despacho: $error';
      rethrow;
    } finally {
      _registrandoDespacho = false;
      notifyListeners();
    }
  }

  Future<void> cargarStockDesdeSupabase() async {
    _cargandoStock = true;
    _errorStock = null;
    notifyListeners();

    try {
      final stock = await stockRepository.obtenerActual();
      _stock
        ..clear()
        ..addAll(stock);
    } catch (error) {
      _errorStock = 'No se pudo cargar el stock: $error';
    } finally {
      _cargandoStock = false;
      notifyListeners();
    }
  }

  Future<void> cargarMaterialesDesdeSupabase() async {
    final materiales = await materialRepository.obtenerTodos();

    _materiales
      ..clear()
      ..addAll(materiales);

    notifyListeners();
  }

  Future<void> guardarMaterialEnSupabase(MaterialItem material) async {
    await materialRepository.guardar(material);
    await cargarMaterialesDesdeSupabase();
  }
  Future<void> cargarMovimientosDesdeSupabase() async {
    _cargandoMovimientos = true;
    _errorMovimientos = null;
    notifyListeners();

    try {
      final movimientos = await movimientoRepository.obtenerTodos();
      _movimientos
        ..clear()
        ..addAll(movimientos);
    } catch (error) {
      _errorMovimientos = 'No se pudieron cargar los movimientos: $error';
    } finally {
      _cargandoMovimientos = false;
      notifyListeners();
    }
  }


}

final appState = AppState();
