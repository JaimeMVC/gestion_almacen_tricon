import 'package:flutter/material.dart';

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
  String _almacen = 'Todos';
  String _proveedor = 'Todos';
  String _tipo = 'Todos';
  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();
    Future.microtask(appState.cargarMovimientosDesdeSupabase);
  }

  @override
  void dispose() {
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

  List<Movimiento> _filtrar(List<Movimiento> origen) {
    final texto = _buscarController.text.trim().toLowerCase();
    return origen.where((m) {
      final coincideTexto = texto.isEmpty || [
        m.codigoMaterial,
        m.nombreMaterial,
        m.familia,
        m.factura,
        m.ordenCompra,
        m.usuario,
        m.destinoExterno,
        m.remitoNumero,
        m.observacion,
        m.almacenOrigenNombre,
        m.almacenDestinoNombre,
        m.proveedorNombre,
      ].any((v) => v.toLowerCase().contains(texto));

      final coincideAlmacen = _almacen == 'Todos' ||
          m.almacenOrigenNombre == _almacen ||
          m.almacenDestinoNombre == _almacen;
      final coincideProveedor =
          _proveedor == 'Todos' || m.proveedorNombre == _proveedor;
      final coincideTipo = _tipo == 'Todos' || m.tipo == _tipo;

      final fechaSolo = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      final coincideDesde = _desde == null || !fechaSolo.isBefore(_desde!);
      final coincideHasta = _hasta == null || !fechaSolo.isAfter(_hasta!);

      return coincideTexto &&
          coincideAlmacen &&
          coincideProveedor &&
          coincideTipo &&
          coincideDesde &&
          coincideHasta;
    }).toList(growable: false);
  }

  void _limpiarFiltros() {
    setState(() {
      _buscarController.clear();
      _almacen = 'Todos';
      _proveedor = 'Todos';
      _tipo = 'Todos';
      _desde = null;
      _hasta = null;
    });
  }

  Future<void> _elegirFecha({required bool desde}) async {
    final inicial = desde ? (_desde ?? DateTime.now()) : (_hasta ?? DateTime.now());
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (seleccionada == null) return;
    setState(() {
      if (desde) {
        _desde = seleccionada;
      } else {
        _hasta = seleccionada;
      }
    });
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
        final movimientos = appState.movimientos;
        final filtrados = _filtrar(movimientos);
        final almacenes = <String>{
          for (final m in movimientos)
            if (m.almacenOrigenNombre.isNotEmpty) m.almacenOrigenNombre,
          for (final m in movimientos)
            if (m.almacenDestinoNombre.isNotEmpty) m.almacenDestinoNombre,
        }.toList()..sort();
        final proveedores = <String>{
          for (final m in movimientos)
            if (m.proveedorNombre.isNotEmpty) m.proveedorNombre,
        }.toList()..sort();
        final tipos = movimientos.map((m) => m.tipo).toSet().toList()..sort();

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
                        onPressed: appState.cargandoMovimientos
                            ? null
                            : appState.cargarMovimientosDesdeSupabase,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar'),
                      ),
                      FilledButton.icon(
                        onPressed: filtrados.isEmpty
                            ? null
                            : () => ExcelService.exportarMovimientos(filtrados),
                        icon: const Icon(Icons.file_download),
                        label: const Text('Exportar Excel'),
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
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Buscar',
                            hintText: 'Material, factura, OC, remito...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      _dropdown('Almacén', _almacen, ['Todos', ...almacenes], (v) => setState(() => _almacen = v!)),
                      _dropdown('Proveedor', _proveedor, ['Todos', ...proveedores], (v) => setState(() => _proveedor = v!)),
                      _dropdown('Tipo', _tipo, ['Todos', ...tipos], (v) => setState(() => _tipo = v!)),
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
              Text('${filtrados.length} movimientos encontrados'),
              const SizedBox(height: 8),
              if (appState.errorMovimientos != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(appState.errorMovimientos!),
                  ),
                ),
              Expanded(
                child: appState.cargandoMovimientos
                    ? const Center(child: CircularProgressIndicator())
                    : filtrados.isEmpty
                        ? const Center(child: Text('No hay movimientos para los filtros seleccionados.'))
                        : Card(
                            clipBehavior: Clip.antiAlias,
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
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
            ],
          ),
        );
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: items.contains(value) ? value : items.first,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
