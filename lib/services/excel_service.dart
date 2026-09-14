// TRICON WMS v0.4.1
// Import/export utilities for Flutter Web using excel ^2.1.0.
// Required pubspec dependencies:
// excel: ^2.1.0
// file_picker: ^8.1.2

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/equipo.dart';
import '../models/material_item.dart';
import '../models/movimiento.dart';
import '../models/stock_item.dart';
import '../models/ubicacion.dart';

class ImportPreview<T> {
  final String archivo;
  final List<T> registrosValidos;
  final List<String> errores;

  const ImportPreview({
    required this.archivo,
    required this.registrosValidos,
    required this.errores,
  });

  bool get tieneErrores => errores.isNotEmpty;
  int get cantidadValida => registrosValidos.length;
}

class ExcelService {
  static Future<ImportPreview<Equipo>?> previsualizarEquipos() async {
    final picked = await _seleccionarExcel();
    if (picked == null) return null;

    final excel = Excel.decodeBytes(picked.bytes);
    final sheet = excel.tables['Equipos'] ?? _primeraHoja(excel);
    if (sheet == null || sheet.rows.isEmpty) {
      return ImportPreview(
        archivo: picked.name,
        registrosValidos: const [],
        errores: const ['El archivo no tiene una hoja con datos.'],
      );
    }

    // Busca los encabezados por nombre para admitir tanto la plantilla TRICON
    // como el archivo maestro de flota existente.
    final headers = <String, int>{};
    for (var i = 0; i < sheet.rows.first.length; i++) {
      final key = _normalizarEncabezado(_cell(sheet.rows.first, i));
      if (key.isNotEmpty) headers[key] = i;
    }

    int? col(List<String> aliases) {
      for (final alias in aliases) {
        final index = headers[_normalizarEncabezado(alias)];
        if (index != null) return index;
      }
      return null;
    }

    final codigoCol = col(['codigo', 'código']);
    final descripcionCol = col(['descripcion del activo', 'descripción del activo', 'descripcion', 'descripción']);
    final marcaCol = col(['marca']);
    final categoriaCol = col(['categoria', 'categoría']);
    final capacidadCol = col(['capacidad']);

    if (codigoCol == null || descripcionCol == null) {
      return ImportPreview(
        archivo: picked.name,
        registrosValidos: const [],
        errores: const [
          'No se encontraron las columnas obligatorias Código y Descripción del activo.',
        ],
      );
    }

    final equipos = <Equipo>[];
    final errores = <String>[];
    final codigos = <String>{};

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final fila = i + 1;
      final codigo = _cell(row, codigoCol);
      final descripcion = _cell(row, descripcionCol);
      final marca = marcaCol == null ? '' : _cell(row, marcaCol);
      final categoria = categoriaCol == null ? '' : _cell(row, categoriaCol);
      final capacidad = capacidadCol == null ? '' : _cell(row, capacidadCol);

      if (codigo.isEmpty && descripcion.isEmpty && marca.isEmpty && categoria.isEmpty && capacidad.isEmpty) continue;
      if (codigo.isEmpty || descripcion.isEmpty) {
        errores.add('Fila $fila: código y descripción del activo son obligatorios.');
        continue;
      }

      final key = codigo.toLowerCase();
      if (!codigos.add(key)) {
        errores.add('Fila $fila: código duplicado dentro del archivo, omitido: $codigo.');
        continue;
      }

      equipos.add(Equipo(
        codigo: codigo,
        descripcion: descripcion,
        marca: marca,
        categoria: categoria,
        capacidad: capacidad,
      ));
    }

    return ImportPreview(
      archivo: picked.name,
      registrosValidos: equipos,
      errores: errores,
    );
  }

  static Future<ImportPreview<MaterialItem>?> previsualizarMateriales() async {
    final picked = await _seleccionarExcel();
    if (picked == null) return null;

    final sheet = _primeraHoja(Excel.decodeBytes(picked.bytes));
    if (sheet == null) {
      return ImportPreview(archivo: picked.name, registrosValidos: const [], errores: const ['El archivo no tiene hojas.']);
    }

    final materiales = <MaterialItem>[];
    final errores = <String>[];
    final codigos = <String>{};

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final fila = i + 1;
      final codigo = _cell(row, 0);
      final nombre = _cell(row, 1);
      final familia = _cell(row, 2);
      final observacion = _cell(row, 3);

      if (codigo.isEmpty && nombre.isEmpty && familia.isEmpty) continue;

      if (codigo.isEmpty || nombre.isEmpty || familia.isEmpty) {
        errores.add('Fila $fila: código, descripción y familia son obligatorios.');
        continue;
      }

      final codigoKey = codigo.toLowerCase();
      if (codigos.contains(codigoKey)) {
        errores.add('Fila $fila: código duplicado dentro del archivo: $codigo.');
        continue;
      }
      codigos.add(codigoKey);

      materiales.add(
        MaterialItem(
          codigo: codigo,
          nombre: nombre,
          familia: familia,
          observacion: observacion,
        ),
      );
    }

    return ImportPreview(archivo: picked.name, registrosValidos: materiales, errores: errores);
  }

  static Future<ImportPreview<Ubicacion>?> previsualizarUbicaciones() async {
    final picked = await _seleccionarExcel();
    if (picked == null) return null;

    final sheet = _primeraHoja(Excel.decodeBytes(picked.bytes));
    if (sheet == null) {
      return ImportPreview(archivo: picked.name, registrosValidos: const [], errores: const ['El archivo no tiene hojas.']);
    }

    final ubicaciones = <Ubicacion>[];
    final errores = <String>[];
    final codigos = <String>{};

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final fila = i + 1;
      final codigo = _cell(row, 0);
      final descripcion = _cell(row, 1);

      if (codigo.isEmpty && descripcion.isEmpty) continue;

      if (codigo.isEmpty) {
        errores.add('Fila $fila: el código de ubicación es obligatorio.');
        continue;
      }

      final codigoKey = codigo.toLowerCase();
      if (codigos.contains(codigoKey)) {
        errores.add('Fila $fila: ubicación duplicada dentro del archivo: $codigo.');
        continue;
      }
      codigos.add(codigoKey);

      ubicaciones.add(Ubicacion(codigo: codigo, descripcion: descripcion));
    }

    return ImportPreview(archivo: picked.name, registrosValidos: ubicaciones, errores: errores);
  }

  static Future<ImportPreview<StockItem>?> previsualizarStock() async {
    final picked = await _seleccionarExcel();
    if (picked == null) return null;

    final sheet = _primeraHoja(Excel.decodeBytes(picked.bytes));
    if (sheet == null) {
      return ImportPreview(archivo: picked.name, registrosValidos: const [], errores: const ['El archivo no tiene hojas.']);
    }

    final stock = <StockItem>[];
    final errores = <String>[];

    for (var i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      final fila = i + 1;
      final codigo = _cell(row, 0);
      final nombre = _cell(row, 1);
      final familia = _cell(row, 2);
      final ubicacion = _cell(row, 3);
      final cantidadTexto = _cell(row, 4);
      final observacion = _cell(row, 5);

      if (codigo.isEmpty && nombre.isEmpty && familia.isEmpty && ubicacion.isEmpty && cantidadTexto.isEmpty) continue;

      if (codigo.isEmpty || nombre.isEmpty || familia.isEmpty || ubicacion.isEmpty || cantidadTexto.isEmpty) {
        errores.add('Fila $fila: código, descripción, familia, ubicación y cantidad son obligatorios.');
        continue;
      }

      final cantidad = _parseCantidad(cantidadTexto);
      if (cantidad == null || cantidad <= 0) {
        errores.add('Fila $fila: cantidad inválida: $cantidadTexto.');
        continue;
      }

      final material = MaterialItem(
        codigo: codigo,
        nombre: nombre,
        familia: familia,
        observacion: observacion,
      );

      stock.add(StockItem(material: material, ubicacion: ubicacion, cantidad: cantidad));
    }

    return ImportPreview(archivo: picked.name, registrosValidos: stock, errores: errores);
  }

  static void descargarPlantillaEquipos() {
    final excel = Excel.createExcel();
    final sheet = excel['Equipos'];
    excel.setDefaultSheet('Equipos');
    sheet.appendRow(['Codigo', 'Descripcion del activo', 'MARCA', 'Categoria', 'Capacidad']);
    sheet.appendRow(['01-EX', 'Excavadora 336 DL', 'Caterpillar', 'Equipo Pesado', '']);
    _descargarExcel(excel, 'plantilla_equipos_tricon_wms.xlsx');
  }

  static void descargarPlantillaMateriales() {
    final excel = Excel.createExcel();
    final sheet = excel['Materiales'];
    excel.setDefaultSheet('Materiales');
    sheet.appendRow(['codigo', 'descripcion', 'familia', 'observacion']);
    sheet.appendRow(['FIL-001', 'Filtro de aceite', 'Filtros', 'Opcional']);
    _descargarExcel(excel, 'plantilla_materiales_tricon_wms.xlsx');
  }

  static void descargarPlantillaUbicaciones() {
    final excel = Excel.createExcel();
    final sheet = excel['Ubicaciones'];
    excel.setDefaultSheet('Ubicaciones');
    sheet.appendRow(['codigo', 'descripcion']);
    sheet.appendRow(['A.01.01', 'Estantería A - Nivel 1']);
    _descargarExcel(excel, 'plantilla_ubicaciones_tricon_wms.xlsx');
  }

  static void descargarPlantillaStock() {
    final excel = Excel.createExcel();
    final sheet = excel['StockInicial'];
    excel.setDefaultSheet('StockInicial');
    sheet.appendRow(['codigo', 'descripcion', 'familia', 'ubicacion', 'cantidad', 'observacion']);
    sheet.appendRow(['FIL-001', 'Filtro de aceite', 'Filtros', 'A.01.01', 10, 'Carga inicial']);
    _descargarExcel(excel, 'plantilla_stock_inicial_tricon_wms.xlsx');
  }

  static void exportarStock(List<StockItem> stock) {
    final excel = Excel.createExcel();
    final sheet = excel['Stock'];
    excel.setDefaultSheet('Stock');
    sheet.appendRow([
      'codigo',
      'descripcion',
      'familia',
      'almacen_codigo',
      'almacen_nombre',
      'proyecto',
      'ubicacion',
      'cantidad',
      'costo_promedio',
      'moneda',
      'valor_total',
    ]);

    for (final s in stock) {
      sheet.appendRow([
        s.material.codigo,
        s.material.nombre,
        s.material.familia,
        s.almacenCodigo,
        s.almacenNombre,
        s.proyecto,
        s.ubicacion,
        s.cantidad,
        s.costoPromedio,
        s.moneda,
        s.valorTotal,
      ]);
    }

    _descargarExcel(excel, 'stock_tricon_wms.xlsx');
  }

  static void exportarMovimientos(List<Movimiento> movimientos) {
    final excel = Excel.createExcel();
    final sheet = excel['Movimientos'];
    excel.setDefaultSheet('Movimientos');
    sheet.appendRow([
      'fecha', 'tipo', 'material_codigo', 'material_descripcion', 'familia',
      'cantidad', 'almacen_origen', 'ubicacion_origen', 'almacen_destino',
      'ubicacion_destino', 'proveedor', 'region', 'pais', 'costo_unitario',
      'moneda', 'valor_total', 'orden_compra', 'factura', 'fecha_compra',
      'destino_proyecto', 'responsable', 'remito', 'observacion'
    ]);

    for (final m in movimientos) {
      sheet.appendRow([
        _fecha(m.fecha), m.tipo, m.codigoMaterial, m.nombreMaterial, m.familia,
        m.cantidad, m.almacenOrigenNombre, m.ubicacionOrigen,
        m.almacenDestinoNombre, m.ubicacionDestino, m.proveedorNombre,
        m.regionNombre, m.regionPais, m.costoUnitario, m.moneda, m.valorTotal,
        m.ordenCompra, m.factura,
        m.fechaCompra == null ? '' : _fecha(m.fechaCompra!),
        m.destinoExterno, m.usuario, m.remitoNumero, m.observacion
      ]);
    }

    _descargarExcel(excel, 'movimientos_tricon_wms.xlsx');
  }

  static void exportarMateriales(List<MaterialItem> materiales) {
    final excel = Excel.createExcel();
    final sheet = excel['Materiales'];
    excel.setDefaultSheet('Materiales');
    sheet.appendRow(['codigo', 'descripcion', 'familia', 'observacion']);

    for (final m in materiales) {
      sheet.appendRow([m.codigo, m.nombre, m.familia, m.observacion]);
    }

    _descargarExcel(excel, 'materiales_tricon_wms.xlsx');
  }

  static void exportarUbicaciones(List<Ubicacion> ubicaciones) {
    final excel = Excel.createExcel();
    final sheet = excel['Ubicaciones'];
    excel.setDefaultSheet('Ubicaciones');
    sheet.appendRow(['codigo', 'descripcion', 'activa']);

    for (final u in ubicaciones) {
      sheet.appendRow([u.codigo, u.descripcion, u.activa ? 'SI' : 'NO']);
    }

    _descargarExcel(excel, 'ubicaciones_tricon_wms.xlsx');
  }

  static Future<_PickedExcel?> _seleccionarExcel() async {
    // En Flutter Web usamos directamente el selector nativo del navegador.
    // FilePicker puede devolver null en algunos navegadores aunque el usuario
    // haya intentado seleccionar un archivo, lo que se mostraba como
    // "Operación cancelada".
    final input = html.FileUploadInputElement()
      ..accept = '.xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      ..multiple = false;

    final completer = Completer<_PickedExcel?>();

    input.onChange.first.then((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final file = files.first;
      final reader = html.FileReader();

      reader.onError.first.then((_) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('No se pudo leer el archivo seleccionado.'));
        }
      });

      reader.onLoadEnd.first.then((_) {
        if (completer.isCompleted) return;
        final result = reader.result;
        if (result is ByteBuffer) {
          completer.complete(_PickedExcel(name: file.name, bytes: Uint8List.view(result)));
        } else if (result is Uint8List) {
          completer.complete(_PickedExcel(name: file.name, bytes: result));
        } else {
          completer.completeError(StateError('El navegador no devolvió datos válidos del archivo.'));
        }
      });

      reader.readAsArrayBuffer(file);
    });

    input.click();
    return completer.future;
  }

  static Sheet? _primeraHoja(Excel excel) {
    if (excel.tables.isEmpty) return null;
    return excel.tables[excel.tables.keys.first];
  }

  static String _normalizarEncabezado(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _cell(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final value = row[index]?.value;
    if (value == null) return '';
    return value.toString().trim();
  }

  static int? _parseCantidad(String texto) {
    final normalizado = texto.replaceAll(',', '.').trim();
    final doubleValue = double.tryParse(normalizado);
    if (doubleValue == null) return null;
    return doubleValue.round();
  }

  static void _descargarExcel(Excel excel, String filename) {
    final bytes = excel.save();
    if (bytes == null) return;

    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static String _fecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }
}

class _PickedExcel {
  final String name;
  final Uint8List bytes;

  const _PickedExcel({required this.name, required this.bytes});
}
