import 'dart:convert';
import 'dart:html' as html;

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/movimiento.dart';
import '../models/stock_item.dart';
import '../state/app_state.dart';

enum TipoReporte {
  inventario,
  movimientos,
  consumos,
  compras,
  consumosEquipos,
  gastoEquipos,
  rankingEquipos,
}

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _buscarController = TextEditingController();
  TipoReporte _tipo = TipoReporte.inventario;
  String _proyecto = '';
  String _almacen = '';
  String _proveedor = '';
  String _equipoId = '';
  DateTime? _desde;
  DateTime? _hasta;
  bool _cargando = false;
  List<_ReporteGuardado> _guardados = const [];

  @override
  void initState() {
    super.initState();
    _cargarGuardados();
    WidgetsBinding.instance.addPostFrameCallback((_) => _actualizar());
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<void> _actualizar() async {
    setState(() => _cargando = true);
    await Future.wait([
      appState.cargarStockDesdeSupabase(),
      appState.cargarMovimientosDesdeSupabase(),
      appState.cargarProyectosDesdeSupabase(),
      appState.cargarAlmacenesDesdeSupabase(),
      appState.cargarProveedoresDesdeSupabase(),
      appState.cargarEquiposDesdeSupabase(),
    ]);
    if (mounted) setState(() => _cargando = false);
  }

  List<String> get _proyectos {
    final valores = <String>{};
    for (final item in appState.stock) {
      if (item.proyecto.trim().isNotEmpty) valores.add(item.proyecto.trim());
    }
    for (final almacen in appState.almacenes) {
      if (almacen.proyecto.trim().isNotEmpty) valores.add(almacen.proyecto.trim());
    }
    final lista = valores.toList()..sort();
    return lista;
  }

  List<String> get _almacenes {
    final valores = appState.almacenes
        .map((a) => a.nombre.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return valores;
  }

  List<String> get _proveedores {
    final valores = appState.proveedores
        .map((p) => p.razonSocial.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return valores;
  }

  List<StockItem> get _stockFiltrado {
    final texto = _buscarController.text.trim().toLowerCase();
    return appState.stock.where((s) {
      if (_proyecto.isNotEmpty && s.proyecto != _proyecto) return false;
      if (_almacen.isNotEmpty && s.almacenNombre != _almacen) return false;
      if (texto.isNotEmpty &&
          !('${s.material.codigo} ${s.material.nombre} ${s.material.familia} ${s.ubicacion}')
              .toLowerCase()
              .contains(texto)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _reportePorEquipo =>
      _tipo == TipoReporte.consumosEquipos ||
      _tipo == TipoReporte.gastoEquipos ||
      _tipo == TipoReporte.rankingEquipos;

  List<Movimiento> get _movimientosFiltrados {
    final texto = _buscarController.text.trim().toLowerCase();
    return appState.movimientos.where((m) {
      if ((_tipo == TipoReporte.consumos || _reportePorEquipo) && !_esConsumo(m)) {
        return false;
      }
      if (_tipo == TipoReporte.compras && !_esRecepcion(m)) return false;
      if (_reportePorEquipo && m.equipoId.isEmpty) return false;
      if (_equipoId.isNotEmpty && m.equipoId != _equipoId) return false;

      if (_almacen.isNotEmpty &&
          m.almacenOrigenNombre != _almacen &&
          m.almacenDestinoNombre != _almacen) {
        return false;
      }
      if (_proveedor.isNotEmpty && m.proveedorNombre != _proveedor) return false;
      if (_proyecto.isNotEmpty &&
          !m.destinoExterno.toLowerCase().contains(_proyecto.toLowerCase())) {
        final almacenProyecto = appState.almacenes.any((a) =>
            a.proyecto == _proyecto &&
            (a.nombre == m.almacenOrigenNombre || a.nombre == m.almacenDestinoNombre));
        if (!almacenProyecto) return false;
      }

      final fecha = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      if (_desde != null &&
          fecha.isBefore(DateTime(_desde!.year, _desde!.month, _desde!.day))) {
        return false;
      }
      if (_hasta != null &&
          fecha.isAfter(DateTime(_hasta!.year, _hasta!.month, _hasta!.day))) {
        return false;
      }

      if (texto.isNotEmpty &&
          !('${m.codigoMaterial} ${m.nombreMaterial} ${m.tipo} ${m.usuario} '
                  '${m.proveedorNombre} ${m.remitoNumero} ${m.destinoExterno} '
                  '${m.equipoCodigo} ${m.equipoDescripcion}')
              .toLowerCase()
              .contains(texto)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<_GastoEquipoRow> get _gastoEquipoFiltrado {
    final agrupado = <String, _GastoEquipoRow>{};
    for (final m in _movimientosFiltrados) {
      final key = '${m.equipoId}|${m.materialId}|${m.moneda}';
      final existente = agrupado[key];
      if (existente == null) {
        agrupado[key] = _GastoEquipoRow(
          equipo: m.equipoEtiqueta,
          codigoMaterial: m.codigoMaterial,
          material: m.nombreMaterial,
          moneda: m.moneda,
          cantidad: m.cantidad,
          valor: m.valorTotal,
        );
      } else {
        agrupado[key] = existente.copyWith(
          cantidad: existente.cantidad + m.cantidad,
          valor: existente.valor + m.valorTotal,
        );
      }
    }
    final rows = agrupado.values.toList()
      ..sort((a, b) {
        final equipo = a.equipo.compareTo(b.equipo);
        return equipo != 0 ? equipo : a.codigoMaterial.compareTo(b.codigoMaterial);
      });
    return rows;
  }


  List<_RankingEquipoRow> get _rankingEquiposFiltrado {
    final agrupado = <String, _RankingEquipoRow>{};
    for (final m in _movimientosFiltrados) {
      if (m.equipoId.isEmpty) continue;
      final key = '${m.equipoId}|${m.moneda}';
      final existente = agrupado[key];
      if (existente == null) {
        agrupado[key] = _RankingEquipoRow(
          equipoId: m.equipoId,
          equipo: m.equipoEtiqueta,
          moneda: m.moneda,
          valor: m.valorTotal,
          operaciones: 1,
          materiales: {m.codigoMaterial},
          ultimaFecha: m.fecha,
        );
      } else {
        agrupado[key] = existente.copyWith(
          valor: existente.valor + m.valorTotal,
          operaciones: existente.operaciones + 1,
          materiales: {...existente.materiales, m.codigoMaterial},
          ultimaFecha: m.fecha.isAfter(existente.ultimaFecha)
              ? m.fecha
              : existente.ultimaFecha,
        );
      }
    }
    final rows = agrupado.values.toList()
      ..sort((a, b) {
        final moneda = a.moneda.compareTo(b.moneda);
        if (moneda != 0) return moneda;
        return b.valor.compareTo(a.valor);
      });
    return rows;
  }

  bool _esRecepcion(Movimiento m) {
    final tipo = m.tipo.toLowerCase();
    return tipo.contains('recep') || tipo.contains('ingreso');
  }

  bool _esConsumo(Movimiento m) {
    final tipo = m.tipo.toLowerCase();
    return tipo.contains('consumo') || tipo.contains('salida') || tipo.contains('despacho');
  }

  String _tituloTipo(TipoReporte tipo) {
    switch (tipo) {
      case TipoReporte.inventario:
        return 'Inventario valorizado';
      case TipoReporte.movimientos:
        return 'Movimientos por período';
      case TipoReporte.consumos:
        return 'Consumos por proyecto';
      case TipoReporte.compras:
        return 'Compras por proveedor';
      case TipoReporte.consumosEquipos:
        return 'Consumos por equipo';
      case TipoReporte.gastoEquipos:
        return 'Gasto por equipo / material';
      case TipoReporte.rankingEquipos:
        return 'Ranking de equipos por costo';
    }
  }

  Map<String, num> get _totalesPorMoneda {
    final resultado = <String, num>{};
    if (_tipo == TipoReporte.inventario) {
      for (final s in _stockFiltrado) {
        resultado[s.moneda] = (resultado[s.moneda] ?? 0) + s.valorTotal;
      }
    } else {
      for (final m in _movimientosFiltrados) {
        resultado[m.moneda] = (resultado[m.moneda] ?? 0) + m.valorTotal;
      }
    }
    return resultado;
  }

  Future<void> _seleccionarFecha(bool desde) async {
    final actual = desde ? _desde : _hasta;
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) setState(() => desde ? _desde = fecha : _hasta = fecha);
  }

  void _limpiarFiltros() {
    setState(() {
      _buscarController.clear();
      _proyecto = '';
      _almacen = '';
      _proveedor = '';
      _equipoId = '';
      _desde = null;
      _hasta = null;
    });
  }

  Future<void> _guardarConfiguracion() async {
    final controller = TextEditingController(text: _tituloTipo(_tipo));
    final nombre = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Guardar reporte'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre del reporte'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nombre == null || nombre.isEmpty) return;

    final nuevo = _ReporteGuardado(
      nombre: nombre,
      tipo: _tipo.name,
      proyecto: _proyecto,
      almacen: _almacen,
      proveedor: _proveedor,
      equipoId: _equipoId,
      buscar: _buscarController.text.trim(),
      desde: _desde?.toIso8601String(),
      hasta: _hasta?.toIso8601String(),
    );
    final lista = [..._guardados.where((g) => g.nombre != nombre), nuevo];
    html.window.localStorage['tricon_reportes_guardados'] =
        jsonEncode(lista.map((e) => e.toJson()).toList());
    setState(() => _guardados = lista);
  }

  void _cargarGuardados() {
    try {
      final raw = html.window.localStorage['tricon_reportes_guardados'];
      if (raw == null || raw.isEmpty) return;
      final data = jsonDecode(raw) as List<dynamic>;
      _guardados = data
          .map((e) => _ReporteGuardado.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _guardados = const [];
    }
  }

  void _aplicarGuardado(_ReporteGuardado guardado) {
    setState(() {
      _tipo = TipoReporte.values.firstWhere(
        (e) => e.name == guardado.tipo,
        orElse: () => TipoReporte.inventario,
      );
      _proyecto = guardado.proyecto;
      _almacen = guardado.almacen;
      _proveedor = guardado.proveedor;
      _equipoId = guardado.equipoId;
      _buscarController.text = guardado.buscar;
      _desde = guardado.desde == null ? null : DateTime.tryParse(guardado.desde!);
      _hasta = guardado.hasta == null ? null : DateTime.tryParse(guardado.hasta!);
    });
  }

  void _eliminarGuardado(_ReporteGuardado guardado) {
    final lista = _guardados.where((g) => g.nombre != guardado.nombre).toList();
    html.window.localStorage['tricon_reportes_guardados'] =
        jsonEncode(lista.map((e) => e.toJson()).toList());
    setState(() => _guardados = lista);
  }

  void _exportarExcel() {
    final excel = Excel.createExcel();
    final sheet = excel['Reporte'];
    excel.setDefaultSheet('Reporte');
    sheet.appendRow([_tituloTipo(_tipo)]);
    sheet.appendRow(['Generado', _fechaHora(DateTime.now())]);
    sheet.appendRow([]);

    if (_tipo == TipoReporte.inventario) {
      sheet.appendRow([
        'Código', 'Material', 'Familia', 'Proyecto', 'Almacén', 'Ubicación',
        'Cantidad', 'Costo promedio', 'Moneda', 'Valor total'
      ]);
      for (final s in _stockFiltrado) {
        sheet.appendRow([
          s.material.codigo, s.material.nombre, s.material.familia, s.proyecto,
          s.almacenNombre, s.ubicacion, s.cantidad, s.costoPromedio, s.moneda,
          s.valorTotal
        ]);
      }
    } else if (_tipo == TipoReporte.gastoEquipos) {
      sheet.appendRow(['Equipo', 'Código', 'Material', 'Cantidad', 'Moneda', 'Gasto total']);
      for (final r in _gastoEquipoFiltrado) {
        sheet.appendRow([r.equipo, r.codigoMaterial, r.material, r.cantidad, r.moneda, r.valor]);
      }
    } else if (_tipo == TipoReporte.rankingEquipos) {
      sheet.appendRow(['Posición', 'Equipo', 'Moneda', 'Gasto total', 'Operaciones', 'Materiales distintos', 'Último consumo']);
      final rows = _rankingEquiposFiltrado;
      final posiciones = <String, int>{};
      for (final r in rows) {
        final posicion = (posiciones[r.moneda] ?? 0) + 1;
        posiciones[r.moneda] = posicion;
        sheet.appendRow([posicion, r.equipo, r.moneda, r.valor, r.operaciones, r.materiales.length, _fecha(r.ultimaFecha)]);
      }
    } else {
      sheet.appendRow([
        'Fecha', 'Tipo', 'Código', 'Material', 'Cantidad', 'Almacén origen',
        'Almacén destino', 'Equipo', 'Proveedor', 'Costo unitario', 'Moneda',
        'Valor total', 'Proyecto/Destino', 'Responsable', 'Remito'
      ]);
      for (final m in _movimientosFiltrados) {
        sheet.appendRow([
          _fechaHora(m.fecha), m.tipo, m.codigoMaterial, m.nombreMaterial,
          m.cantidad, m.almacenOrigenNombre, m.almacenDestinoNombre,
          m.equipoEtiqueta, m.proveedorNombre, m.costoUnitario, m.moneda,
          m.valorTotal, m.destinoExterno, m.usuario, m.remitoNumero
        ]);
      }
    }

    final bytes = excel.save();
    if (bytes == null) return;
    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'reporte_${_tipo.name}_tricon.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportarPdf() async {
    final pdf = pw.Document();
    late final List<String> headers;
    late final List<List<String>> rows;

    if (_tipo == TipoReporte.inventario) {
      headers = ['Código', 'Material', 'Proyecto', 'Almacén', 'Cant.', 'Moneda', 'Valor'];
      rows = _stockFiltrado
          .map((s) => [
                s.material.codigo,
                s.material.nombre,
                s.proyecto,
                s.almacenNombre,
                _numero(s.cantidad),
                s.moneda,
                _numero(s.valorTotal),
              ])
          .toList();
    } else if (_tipo == TipoReporte.gastoEquipos) {
      headers = ['Equipo', 'Código', 'Material', 'Cantidad', 'Moneda', 'Gasto'];
      rows = _gastoEquipoFiltrado
          .map((r) => [
                r.equipo,
                r.codigoMaterial,
                r.material,
                _numero(r.cantidad),
                r.moneda,
                _numero(r.valor),
              ])
          .toList();
    } else if (_tipo == TipoReporte.rankingEquipos) {
      headers = ['#', 'Equipo', 'Moneda', 'Gasto', 'Operaciones', 'Materiales', 'Último consumo'];
      final ranking = _rankingEquiposFiltrado;
      final posiciones = <String, int>{};
      rows = ranking.map((r) {
        final posicion = (posiciones[r.moneda] ?? 0) + 1;
        posiciones[r.moneda] = posicion;
        return [
          '$posicion',
          r.equipo,
          r.moneda,
          _numero(r.valor),
          '${r.operaciones}',
          '${r.materiales.length}',
          _fecha(r.ultimaFecha),
        ];
      }).toList();
    } else {
      headers = ['Fecha', 'Material', 'Cant.', 'Equipo', 'Destino', 'Responsable', 'Valor'];
      rows = _movimientosFiltrados
          .map((m) => [
                _fecha(m.fecha),
                '${m.codigoMaterial} - ${m.nombreMaterial}',
                _numero(m.cantidad),
                m.equipoEtiqueta,
                _destinoMovimiento(m),
                m.usuario,
                '${m.moneda} ${_numero(m.valorTotal)}',
              ])
          .toList();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('TRICON WMS',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(_tituloTipo(_tipo), style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (_) => [
          pw.Wrap(
            spacing: 18,
            runSpacing: 6,
            children: _totalesPorMoneda.entries
                .map((e) => pw.Text(
                      '${e.key}: ${_numero(e.value)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ))
                .toList(),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'reporte_${_tipo.name}_tricon.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Centro de Reportes',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Analizá inventario, movimientos, consumos, compras y costos por equipo.'),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _cargando ? null : _actualizar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _guardarConfiguracion,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Guardar reporte'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildFiltros(),
            if (_guardados.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _guardados.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final guardado = _guardados[index];
                    return InputChip(
                      avatar: const Icon(Icons.bookmark_outline, size: 18),
                      label: Text(guardado.nombre),
                      onPressed: () => _aplicarGuardado(guardado),
                      onDeleted: () => _eliminarGuardado(guardado),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_cargando) const LinearProgressIndicator(),
            _buildKpis(),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(_tituloTipo(_tipo),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _exportarExcel,
                  icon: const Icon(Icons.table_view),
                  label: const Text('Excel'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _exportarPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildTabla()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 235,
              child: DropdownButtonFormField<TipoReporte>(
                value: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Reporte',
                  border: OutlineInputBorder(),
                ),
                items: TipoReporte.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_tituloTipo(t), overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _tipo = value ?? TipoReporte.inventario;
                  if (!_reportePorEquipo) _equipoId = '';
                }),
              ),
            ),
            SizedBox(
              width: 245,
              child: TextField(
                controller: _buscarController,
                decoration: const InputDecoration(
                  labelText: 'Buscar material, equipo o remito',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (!_reportePorEquipo)
              _dropdown('Proyecto', _proyecto, _proyectos,
                  (v) => setState(() => _proyecto = v ?? '')),
            _dropdown('Almacén', _almacen, _almacenes,
                (v) => setState(() => _almacen = v ?? '')),
            if (_tipo == TipoReporte.compras || _tipo == TipoReporte.movimientos)
              _dropdown('Proveedor', _proveedor, _proveedores,
                  (v) => setState(() => _proveedor = v ?? '')),
            if (_reportePorEquipo) _dropdownEquipo(),
            if (_tipo != TipoReporte.inventario) ...[
              OutlinedButton.icon(
                onPressed: () => _seleccionarFecha(true),
                icon: const Icon(Icons.date_range),
                label: Text(_desde == null ? 'Desde' : _fecha(_desde!)),
              ),
              OutlinedButton.icon(
                onPressed: () => _seleccionarFecha(false),
                icon: const Icon(Icons.event),
                label: Text(_hasta == null ? 'Hasta' : _fecha(_hasta!)),
              ),
            ],
            TextButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Limpiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    final validValue = options.contains(value) ? value : '';
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        value: validValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: [
          const DropdownMenuItem(value: '', child: Text('Todos')),
          ...options.map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdownEquipo() {
    final ids = appState.equipos.map((e) => e.id).toSet();
    final validValue = ids.contains(_equipoId) ? _equipoId : '';
    return SizedBox(
      width: 265,
      child: DropdownButtonFormField<String>(
        value: validValue,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Equipo',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.precision_manufacturing),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Todos los equipos')),
          ...appState.equipos.map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.etiqueta, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _equipoId = value ?? ''),
      ),
    );
  }

  Widget _buildKpis() {
    final totales = _totalesPorMoneda;
    final cards = <Widget>[];

    if (_tipo == TipoReporte.inventario) {
      cards.add(_kpi('Registros', _stockFiltrado.length.toString(), Icons.inventory_2));
      cards.add(_kpi(
        'Materiales',
        _stockFiltrado.map((e) => e.material.codigo).toSet().length.toString(),
        Icons.category,
      ));
      cards.add(_kpi(
        'Almacenes',
        _stockFiltrado.map((e) => e.almacenId).toSet().length.toString(),
        Icons.warehouse,
      ));
    } else if (_reportePorEquipo) {
      cards.add(_kpi(
        'Equipos',
        _movimientosFiltrados.map((e) => e.equipoId).where((e) => e.isNotEmpty).toSet().length.toString(),
        Icons.precision_manufacturing,
      ));
      cards.add(_kpi(
        'Materiales',
        _movimientosFiltrados.map((e) => e.codigoMaterial).toSet().length.toString(),
        Icons.category,
      ));
      cards.add(_kpi(
        'Cantidad total',
        _numero(_movimientosFiltrados.fold<num>(0, (a, b) => a + b.cantidad)),
        Icons.numbers,
      ));
    } else {
      cards.add(_kpi('Operaciones', _movimientosFiltrados.length.toString(), Icons.swap_horiz));
      cards.add(_kpi(
        'Cantidad total',
        _numero(_movimientosFiltrados.fold<num>(0, (a, b) => a + b.cantidad)),
        Icons.numbers,
      ));
      cards.add(_kpi(
        'Responsables',
        _movimientosFiltrados.map((e) => e.usuario).where((e) => e.isNotEmpty).toSet().length.toString(),
        Icons.people,
      ));
    }

    for (final entry in totales.entries.take(3)) {
      cards.add(_kpi('Valor ${entry.key}', _numero(entry.value), Icons.payments));
    }

    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => cards[index],
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabla() {
    if (_tipo == TipoReporte.inventario) return _tablaInventario();
    if (_tipo == TipoReporte.gastoEquipos) return _tablaGastoEquipos();
    if (_tipo == TipoReporte.rankingEquipos) return _tablaRankingEquipos();
    return _tablaMovimientos();
  }

  Widget _tablaInventario() {
    final items = _stockFiltrado;
    if (items.isEmpty) {
      return const Center(child: Text('No hay datos para los filtros seleccionados.'));
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Material')),
              DataColumn(label: Text('Familia')),
              DataColumn(label: Text('Proyecto')),
              DataColumn(label: Text('Almacén')),
              DataColumn(label: Text('Ubicación')),
              DataColumn(label: Text('Cantidad'), numeric: true),
              DataColumn(label: Text('Costo prom.'), numeric: true),
              DataColumn(label: Text('Moneda')),
              DataColumn(label: Text('Valor'), numeric: true),
            ],
            rows: items
                .map((s) => DataRow(cells: [
                      DataCell(Text(s.material.codigo)),
                      DataCell(SizedBox(width: 220, child: Text(s.material.nombre))),
                      DataCell(Text(s.material.familia)),
                      DataCell(Text(s.proyecto)),
                      DataCell(Text(s.almacenNombre)),
                      DataCell(Text(s.ubicacion)),
                      DataCell(Text(_numero(s.cantidad))),
                      DataCell(Text(_numero(s.costoPromedio))),
                      DataCell(Text(s.moneda)),
                      DataCell(Text(_numero(s.valorTotal))),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _tablaMovimientos() {
    final items = _movimientosFiltrados;
    if (items.isEmpty) {
      return const Center(child: Text('No hay datos para los filtros seleccionados.'));
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Material')),
              DataColumn(label: Text('Cantidad'), numeric: true),
              DataColumn(label: Text('Origen')),
              DataColumn(label: Text('Destino')),
              DataColumn(label: Text('Equipo')),
              DataColumn(label: Text('Proveedor')),
              DataColumn(label: Text('Responsable')),
              DataColumn(label: Text('Moneda')),
              DataColumn(label: Text('Valor'), numeric: true),
              DataColumn(label: Text('Remito')),
            ],
            rows: items
                .map((m) => DataRow(cells: [
                      DataCell(Text(_fecha(m.fecha))),
                      DataCell(Text(m.tipo)),
                      DataCell(Text(m.codigoMaterial)),
                      DataCell(SizedBox(width: 220, child: Text(m.nombreMaterial))),
                      DataCell(Text(_numero(m.cantidad))),
                      DataCell(Text(m.almacenOrigenNombre)),
                      DataCell(Text(_destinoMovimiento(m))),
                      DataCell(SizedBox(width: 220, child: Text(m.equipoEtiqueta))),
                      DataCell(Text(m.proveedorNombre)),
                      DataCell(Text(m.usuario)),
                      DataCell(Text(m.moneda)),
                      DataCell(Text(_numero(m.valorTotal))),
                      DataCell(Text(m.remitoNumero)),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _tablaGastoEquipos() {
    final items = _gastoEquipoFiltrado;
    if (items.isEmpty) {
      return const Center(child: Text('No hay consumos imputados a equipos para los filtros seleccionados.'));
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Equipo')),
              DataColumn(label: Text('Código material')),
              DataColumn(label: Text('Material')),
              DataColumn(label: Text('Cantidad'), numeric: true),
              DataColumn(label: Text('Moneda')),
              DataColumn(label: Text('Gasto total'), numeric: true),
            ],
            rows: items
                .map((r) => DataRow(cells: [
                      DataCell(SizedBox(width: 260, child: Text(r.equipo))),
                      DataCell(Text(r.codigoMaterial)),
                      DataCell(SizedBox(width: 250, child: Text(r.material))),
                      DataCell(Text(_numero(r.cantidad))),
                      DataCell(Text(r.moneda)),
                      DataCell(Text(_numero(r.valor))),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }


  Widget _tablaRankingEquipos() {
    final items = _rankingEquiposFiltrado;
    if (items.isEmpty) {
      return const Center(
        child: Text('No hay consumos imputados a equipos para los filtros seleccionados.'),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('#'), numeric: true),
              DataColumn(label: Text('Equipo')),
              DataColumn(label: Text('Moneda')),
              DataColumn(label: Text('Gasto total'), numeric: true),
              DataColumn(label: Text('Operaciones'), numeric: true),
              DataColumn(label: Text('Materiales distintos'), numeric: true),
              DataColumn(label: Text('Último consumo')),
            ],
            rows: (() {
              final posiciones = <String, int>{};
              return items.map((r) {
                final posicion = (posiciones[r.moneda] ?? 0) + 1;
                posiciones[r.moneda] = posicion;
                return DataRow(cells: [
                  DataCell(Text('$posicion')),
                  DataCell(SizedBox(width: 300, child: Text(r.equipo))),
                  DataCell(Text(r.moneda)),
                  DataCell(Text(_numero(r.valor))),
                  DataCell(Text('${r.operaciones}')),
                  DataCell(Text('${r.materiales.length}')),
                  DataCell(Text(_fecha(r.ultimaFecha))),
                ]);
              }).toList();
            })(),
          ),
        ),
      ),
    );
  }

  String _destinoMovimiento(Movimiento m) {
    if (m.almacenDestinoNombre.isNotEmpty) return m.almacenDestinoNombre;
    if (m.destinoExterno.isNotEmpty) return m.destinoExterno;
    if (m.equipoEtiqueta.isNotEmpty) return m.equipoEtiqueta;
    return '';
  }

  String _numero(num valor) {
    final entero = valor == valor.roundToDouble();
    final texto = entero ? valor.toStringAsFixed(0) : valor.toStringAsFixed(2);
    final partes = texto.split('.');
    final chars = partes[0].split('').reversed.toList();
    final grupos = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      grupos.add(chars.skip(i).take(3).toList().reversed.join());
    }
    final base = grupos.reversed.join('.');
    return partes.length == 1 ? base : '$base,${partes[1]}';
  }

  String _fecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  String _fechaHora(DateTime fecha) =>
      '${_fecha(fecha)} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
}

class _GastoEquipoRow {
  final String equipo;
  final String codigoMaterial;
  final String material;
  final String moneda;
  final num cantidad;
  final num valor;

  const _GastoEquipoRow({
    required this.equipo,
    required this.codigoMaterial,
    required this.material,
    required this.moneda,
    required this.cantidad,
    required this.valor,
  });

  _GastoEquipoRow copyWith({num? cantidad, num? valor}) => _GastoEquipoRow(
        equipo: equipo,
        codigoMaterial: codigoMaterial,
        material: material,
        moneda: moneda,
        cantidad: cantidad ?? this.cantidad,
        valor: valor ?? this.valor,
      );
}


class _RankingEquipoRow {
  final String equipoId;
  final String equipo;
  final String moneda;
  final num valor;
  final int operaciones;
  final Set<String> materiales;
  final DateTime ultimaFecha;

  const _RankingEquipoRow({
    required this.equipoId,
    required this.equipo,
    required this.moneda,
    required this.valor,
    required this.operaciones,
    required this.materiales,
    required this.ultimaFecha,
  });

  _RankingEquipoRow copyWith({
    num? valor,
    int? operaciones,
    Set<String>? materiales,
    DateTime? ultimaFecha,
  }) =>
      _RankingEquipoRow(
        equipoId: equipoId,
        equipo: equipo,
        moneda: moneda,
        valor: valor ?? this.valor,
        operaciones: operaciones ?? this.operaciones,
        materiales: materiales ?? this.materiales,
        ultimaFecha: ultimaFecha ?? this.ultimaFecha,
      );
}

class _ReporteGuardado {
  final String nombre;
  final String tipo;
  final String proyecto;
  final String almacen;
  final String proveedor;
  final String equipoId;
  final String buscar;
  final String? desde;
  final String? hasta;

  const _ReporteGuardado({
    required this.nombre,
    required this.tipo,
    required this.proyecto,
    required this.almacen,
    required this.proveedor,
    required this.equipoId,
    required this.buscar,
    this.desde,
    this.hasta,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'tipo': tipo,
        'proyecto': proyecto,
        'almacen': almacen,
        'proveedor': proveedor,
        'equipoId': equipoId,
        'buscar': buscar,
        'desde': desde,
        'hasta': hasta,
      };

  factory _ReporteGuardado.fromJson(Map<String, dynamic> json) => _ReporteGuardado(
        nombre: json['nombre']?.toString() ?? 'Reporte',
        tipo: json['tipo']?.toString() ?? 'inventario',
        proyecto: json['proyecto']?.toString() ?? '',
        almacen: json['almacen']?.toString() ?? '',
        proveedor: json['proveedor']?.toString() ?? '',
        equipoId: json['equipoId']?.toString() ?? '',
        buscar: json['buscar']?.toString() ?? '',
        desde: json['desde']?.toString(),
        hasta: json['hasta']?.toString(),
      );
}
