import 'dart:async';

import 'package:flutter/material.dart';
import '../repositories/movimiento_repository.dart';

import '../models/movimiento.dart';
import '../services/excel_service.dart';
import '../state/app_state.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final _buscarController = TextEditingController();
  String _almacen = '';
  String _proveedor = '';
  String _tipo = '';
  static const int _tamanoPagina = 50;
  int _pagina = 0;
  int _total = 0;
  bool _haySiguiente = false;
  List<Movimiento> _resultados = [];
  bool _cargando = false;
  String? _error;
  int _solicitud = 0;
  Timer? _debounce;
  final ScrollController _scrollVertical = ScrollController();
  final ScrollController _scrollHorizontal = ScrollController();
  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        if (appState.almacenes.isEmpty) appState.cargarAlmacenesDesdeSupabase(),
        if (appState.proveedores.isEmpty) appState.cargarProveedoresDesdeSupabase(),
      ]);
      if (mounted) _cargarPagina(0);
    });
  }

  @override
  void dispose() {
    _solicitud++;
    _debounce?.cancel();
    _scrollVertical.dispose();
    _scrollHorizontal.dispose();
    _buscarController.dispose();
    super.dispose();
  }

  String _fecha(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final a = fecha.year.toString();
    final h = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$d/$m/$a $h:$min';
  }

  String _fechaCorta(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year}';
  }

  Future<void> _cargarPagina(int pagina) async {
    if (pagina < 0) return;
    final solicitud = ++_solicitud;
    setState(() { _cargando = true; _error = null; });
    try {
      final respuesta = await movimientoRepository.obtenerPagina(
        pagina: pagina,
        tamanoPagina: _tamanoPagina,
        buscar: _buscarController.text,
        almacenId: _almacen,
        proveedorId: _proveedor,
        tipo: _tipo,
        desde: _desde,
        hasta: _hasta,
      );
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _pagina = pagina;
        _total = respuesta.total;
        _haySiguiente = respuesta.haySiguiente;
        _resultados = respuesta.movimientos;
        _cargando = false;
      });
      if (_scrollVertical.hasClients) _scrollVertical.jumpTo(0);
      if (_scrollHorizontal.hasClients) _scrollHorizontal.jumpTo(0);
    } catch (e) {
      if (!mounted || solicitud != _solicitud) return;
      setState(() { _cargando = false; _error = 'No se pudieron cargar los movimientos: $e'; });
    }
  }

  void _buscarConDemora(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _cargarPagina(0));
  }

  void _limpiarFiltros() {
    _debounce?.cancel();
    setState(() {
      _buscarController.clear();
      _almacen = '';
      _proveedor = '';
      _tipo = '';
      _desde = null;
      _hasta = null;
    });
    _cargarPagina(0);
  }

  Future<void> _elegirFecha({required bool desde}) async {
    final inicial = desde ? (_desde ?? DateTime.now()) : (_hasta ?? DateTime.now());
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null || !mounted) return;
    setState(() {
      if (desde) { _desde = seleccionada; } else { _hasta = seleccionada; }
    });
    _cargarPagina(0);
  }

  Color _colorTipo(String tipo, BuildContext context) {
    switch (tipo) {
      case 'INGRESO':
      case 'TRANSFERENCIA_INGRESO':
        return Colors.green.shade700;
      case 'SALIDA_CONSUMO':
      case 'TRANSFERENCIA_SALIDA':
        return Colors.orange.shade800;
      case 'AJUSTE_NEGATIVO':
        return Colors.red.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _mostrarDetalle(Movimiento m) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${m.tipo} · ${m.codigoMaterial}'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Wrap(
              runSpacing: 14,
              children: [
                _detalle('Fecha', _fecha(m.fecha)),
                _detalle('Material', '${m.codigoMaterial} - ${m.nombreMaterial}'),
                _detalle('Familia', m.familia),
                _detalle('Cantidad', m.cantidad.toString()),
                _detalle('Almacén origen', m.almacenOrigenNombre),
                _detalle('Ubicación origen', m.ubicacionOrigen),
                _detalle('Almacén destino', m.almacenDestinoNombre),
                _detalle('Ubicación destino', m.ubicacionDestino),
                _detalle('Destino / proyecto', m.destinoExterno),
                _detalle('Proveedor', m.proveedorNombre),
                _detalle('Región', [m.regionNombre, m.regionPais].where((e) => e.isNotEmpty).join(' - ')),
                _detalle('Costo unitario', '${m.moneda} ${m.costoUnitario}'),
                _detalle('Valor total', '${m.moneda} ${m.valorTotal}'),
                _detalle('Orden de compra', m.ordenCompra),
                _detalle('Factura', m.factura),
                _detalle('Fecha de compra', m.fechaCompra == null ? '' : _fechaCorta(m.fechaCompra!)),
                _detalle('Remito', m.remitoNumero),
                _detalle('Responsable', m.usuario),
                _detalle('Observaciones', m.observacion),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detalle(String titulo, String valor) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 285,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 3),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final filtrados = _resultados;
        final almacenes = appState.almacenes.toList()..sort((a,b) => a.nombre.compareTo(b.nombre));
        final proveedores = appState.proveedores.toList()..sort((a,b) => a.etiqueta.compareTo(b.etiqueta));
        const tipos = ['INGRESO','SALIDA_CONSUMO','TRANSFERENCIA_SALIDA','TRANSFERENCIA_INGRESO','AJUSTE_POSITIVO','AJUSTE_NEGATIVO'];

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const Text('Movimientos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _cargando ? null : () => _cargarPagina(_pagina),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar'),
                      ),
                      FilledButton.icon(
                        onPressed: filtrados.isEmpty
                            ? null
                            : () => ExcelService.exportarMovimientos(filtrados),
                        icon: const Icon(Icons.file_download),
                        label: const Text('Exportar página Excel'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 280,
                        child: TextField(
                          controller: _buscarController,
                          onChanged: _buscarConDemora,
                          decoration: const InputDecoration(
                            labelText: 'Buscar',
                            hintText: 'Material, factura, OC, remito...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      _dropdown('Almacén', _almacen, {'': 'Todos', for (final a in almacenes) a.id: a.nombre}, (v) { setState(() => _almacen = v!); _cargarPagina(0); }),
                      _dropdown('Proveedor', _proveedor, {'': 'Todos', for (final p in proveedores) p.id: p.etiqueta}, (v) { setState(() => _proveedor = v!); _cargarPagina(0); }),
                      _dropdown('Tipo', _tipo, {'': 'Todos', for (final t in tipos) t: t}, (v) { setState(() => _tipo = v!); _cargarPagina(0); }),
                      OutlinedButton.icon(
                        onPressed: () => _elegirFecha(desde: true),
                        icon: const Icon(Icons.date_range),
                        label: Text(_desde == null ? 'Desde' : _fechaCorta(_desde!)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _elegirFecha(desde: false),
                        icon: const Icon(Icons.event),
                        label: Text(_hasta == null ? 'Hasta' : _fechaCorta(_hasta!)),
                      ),
                      TextButton.icon(
                        onPressed: _limpiarFiltros,
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text(_resultados.isEmpty ? 'Sin movimientos · Página ${_pagina + 1}' : 'Mostrando ${_pagina * _tamanoPagina + 1}–${_pagina * _tamanoPagina + _resultados.length} · Página ${_pagina + 1}${_haySiguiente ? ' (hay más)' : ''}')),
                DropdownButton<int>(value: _tamanoPagina, items: const [DropdownMenuItem(value: 50, child: Text('50 por página'))], onChanged: null),
                IconButton(tooltip: 'Página anterior', onPressed: _cargando || _pagina == 0 ? null : () => _cargarPagina(_pagina - 1), icon: const Icon(Icons.chevron_left)),
                IconButton(tooltip: 'Página siguiente', onPressed: _cargando || !_haySiguiente ? null : () => _cargarPagina(_pagina + 1), icon: const Icon(Icons.chevron_right)),
              ]),
              const SizedBox(height: 8),
              if (_error != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!),
                  ),
                ),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : filtrados.isEmpty
                        ? const Center(child: Text('No hay movimientos para los filtros seleccionados.'))
                        : Card(
                            clipBehavior: Clip.antiAlias,
                            child: Scrollbar(
                              controller: _scrollVertical,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: Scrollbar(
                                controller: _scrollHorizontal,
                                thumbVisibility: true,
                                trackVisibility: true,
                                notificationPredicate: (notification) => notification.metrics.axis == Axis.horizontal,
                                child: SingleChildScrollView(
                                  controller: _scrollHorizontal,
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    controller: _scrollVertical,
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                    showCheckboxColumn: false,
                                    columns: const [
                                      DataColumn(label: Text('Fecha')),
                                      DataColumn(label: Text('Tipo')),
                                      DataColumn(label: Text('Material')),
                                      DataColumn(label: Text('Cantidad')),
                                      DataColumn(label: Text('Almacén')),
                                      DataColumn(label: Text('Ubicación')),
                                      DataColumn(label: Text('Proveedor')),
                                      DataColumn(label: Text('Costo')),
                                      DataColumn(label: Text('Destino / Proyecto')),
                                      DataColumn(label: Text('Responsable')),
                                      DataColumn(label: Text('Remito')),
                                    ],
                                    rows: filtrados.map((m) => DataRow(
                                      onSelectChanged: (_) => _mostrarDetalle(m),
                                      cells: [
                                        DataCell(Text(_fecha(m.fecha))),
                                        DataCell(Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _colorTipo(m.tipo, context).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(m.tipo, style: TextStyle(color: _colorTipo(m.tipo, context), fontWeight: FontWeight.w600)),
                                        )),
                                        DataCell(Text('${m.codigoMaterial}\n${m.nombreMaterial}')),
                                        DataCell(Text(m.cantidad.toString())),
                                        DataCell(Text(m.almacenPrincipal.isEmpty ? '-' : m.almacenPrincipal)),
                                        DataCell(Text(m.ubicacionPrincipal.isEmpty ? '-' : m.ubicacionPrincipal)),
                                        DataCell(Text(m.proveedorNombre.isEmpty ? '-' : m.proveedorNombre)),
                                        DataCell(Text('${m.moneda} ${m.costoUnitario}')),
                                        DataCell(Text(m.destinoExterno.isEmpty ? '-' : m.destinoExterno)),
                                        DataCell(Text(m.usuario.isEmpty ? '-' : m.usuario)),
                                        DataCell(Text(m.remitoNumero.isEmpty ? '-' : m.remitoNumero)),
                                      ],
                                    )).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: items.containsKey(value) ? value : items.keys.first,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.entries.map((item) => DropdownMenuItem(value: item.key, child: Text(item.value, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
