import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../models/material_item.dart';
import '../models/movimiento.dart';
import '../models/remito.dart';
import '../models/stock_item.dart';
import '../models/ubicacion.dart';

class AppState extends ChangeNotifier {
  final List<MaterialItem> _materiales = List.from(materialesDemo);
  final List<StockItem> _stock = List.from(stockDemo);
  final List<Ubicacion> _ubicaciones = List.from(ubicacionesDemo);
  final List<Movimiento> _movimientos = [];
  final List<Remito> _remitos = [];

  List<MaterialItem> get materiales => List.unmodifiable(_materiales);
  List<StockItem> get stock => List.unmodifiable(_stock);
  List<Ubicacion> get ubicaciones => List.unmodifiable(_ubicaciones);

  List<Movimiento> get movimientos {
    final lista = List<Movimiento>.from(_movimientos);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

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
    final index = _ubicaciones.indexWhere(
      (u) => u.codigo.toLowerCase() == ubicacion.codigo.toLowerCase(),
    );

    if (index >= 0) {
      _ubicaciones[index] = ubicacion;
    } else {
      _ubicaciones.add(ubicacion);
    }

    notifyListeners();
  }

  bool existeUbicacion(String codigo) {
    return _ubicaciones.any((u) => u.codigo.toLowerCase() == codigo.toLowerCase());
  }

  void ingresarStock({
    required MaterialItem material,
    required String ubicacion,
    required int cantidad,
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
    required int cantidad,
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
}

final appState = AppState();
