import 'package:flutter/material.dart';

import '../models/documento.dart';
import '../pdf/documento_pdf.dart';
import '../repositories/documento_repository.dart';
import '../models/perfil_usuario.dart';
import '../state/auth_state.dart';

class RemitosScreen extends StatefulWidget {
  const RemitosScreen({super.key});

  @override
  State<RemitosScreen> createState() => _RemitosScreenState();
}

class _RemitosScreenState extends State<RemitosScreen> {
  final _buscarController = TextEditingController();
  List<Documento> _documentos = [];
  bool _cargando = true;
  String? _error;
  String _tipo = 'TODOS';
  String _estado = 'TODOS';
  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();
    _buscarController.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final datos = await documentoRepository.obtenerTodos();
      if (!mounted) return;
      setState(() => _documentos = datos);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Documento> get _filtrados {
    final texto = _buscarController.text.trim().toLowerCase();
    return _documentos.where((d) {
      final coincideTexto = texto.isEmpty || [d.numero, d.tipoLegible, d.proyecto, d.almacenOrigen, d.almacenDestino, d.destinoExterno, d.responsable, d.proveedor, ...d.items.expand((i) => [i.materialCodigo, i.materialNombre, i.equipoCodigo, i.equipoDescripcion])].any((v) => v.toLowerCase().contains(texto));
      final coincideTipo = _tipo == 'TODOS' || d.tipo == _tipo;
      final coincideEstado = _estado == 'TODOS' || d.estado == _estado;
      final fecha = DateTime(d.fecha.year, d.fecha.month, d.fecha.day);
      final coincideDesde = _desde == null || !fecha.isBefore(DateTime(_desde!.year, _desde!.month, _desde!.day));
      final coincideHasta = _hasta == null || !fecha.isAfter(DateTime(_hasta!.year, _hasta!.month, _hasta!.day));
      return coincideTexto && coincideTipo && coincideEstado && coincideDesde && coincideHasta;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Documentos / Remitos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Consulta, emisión y control documental de transferencias y consumos.')])),
            FilledButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
          ]),
          const SizedBox(height: 18),
          _filtros(),
          const SizedBox(height: 14),
          Expanded(child: _contenido()),
        ],
      ),
    );
  }

  Widget _filtros() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: 290, child: TextField(controller: _buscarController, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Número, proyecto, material, responsable...', border: OutlineInputBorder()))),
        SizedBox(width: 190, child: DropdownButtonFormField<String>(value: _tipo, decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'TODOS', child: Text('Todos')), DropdownMenuItem(value: 'TRANSFERENCIA_INTERNA', child: Text('Transferencias')), DropdownMenuItem(value: 'SALIDA_CONSUMO', child: Text('Consumos')), DropdownMenuItem(value: 'RECEPCION', child: Text('Recepciones'))], onChanged: (v) => setState(() => _tipo = v ?? 'TODOS'))),
        SizedBox(width: 165, child: DropdownButtonFormField<String>(value: _estado, decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 'TODOS', child: Text('Todos')), DropdownMenuItem(value: 'BORRADOR', child: Text('Borrador')), DropdownMenuItem(value: 'EMITIDO', child: Text('Emitido')), DropdownMenuItem(value: 'FIRMADO', child: Text('Firmado')), DropdownMenuItem(value: 'ANULADO', child: Text('Anulado'))], onChanged: (v) => setState(() => _estado = v ?? 'TODOS'))),
        OutlinedButton.icon(onPressed: () => _elegirFecha(true), icon: const Icon(Icons.calendar_today), label: Text(_desde == null ? 'Desde' : _fechaCorta(_desde!))),
        OutlinedButton.icon(onPressed: () => _elegirFecha(false), icon: const Icon(Icons.event), label: Text(_hasta == null ? 'Hasta' : _fechaCorta(_hasta!))),
        TextButton.icon(onPressed: () { _buscarController.clear(); setState(() { _tipo = 'TODOS'; _estado = 'TODOS'; _desde = null; _hasta = null; }); }, icon: const Icon(Icons.filter_alt_off), label: const Text('Limpiar')),
      ]),
    ),
  );

  Widget _contenido() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48), const SizedBox(height: 10), Text('No se pudieron cargar los documentos.\n$_error', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _cargar, child: const Text('Reintentar'))]));
    final datos = _filtrados;
    if (datos.isEmpty) return const Center(child: Text('No hay documentos que coincidan con los filtros.'));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [DataColumn(label: Text('Número')), DataColumn(label: Text('Acciones')), DataColumn(label: Text('Tipo')), DataColumn(label: Text('Fecha')), DataColumn(label: Text('Proyecto')), DataColumn(label: Text('Origen / Destino')), DataColumn(label: Text('Responsable')), DataColumn(label: Text('Estado')), DataColumn(label: Text('Ítems'))],
            rows: datos.map((d) => DataRow(onSelectChanged: (_) => _mostrarDetalle(d), cells: [
              DataCell(Text(d.numero, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(_accionesDocumento(d)),
              DataCell(Text(d.tipoLegible)),
              DataCell(Text(_fechaHora(d.fecha))),
              DataCell(Text(d.proyecto.isEmpty ? '-' : d.proyecto)),
              DataCell(SizedBox(width: 250, child: Text('${d.almacenOrigen}${d.almacenOrigen.isNotEmpty ? ' → ' : ''}${d.almacenDestino.isNotEmpty ? d.almacenDestino : d.destinoExterno}'))),
              DataCell(Text(d.responsable.isEmpty ? '-' : d.responsable)),
              DataCell(_estadoChip(d.estado)),
              DataCell(Text('${d.items.length}')),
            ])).toList(),
          ),
        ),
      ),
    );
  }

  Widget _accionesDocumento(Documento d) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Ver detalle',
          onPressed: () => _mostrarDetalle(d),
          icon: const Icon(Icons.visibility),
        ),
        PopupMenuButton<String>(
          tooltip: 'Acciones del documento',
          icon: const Icon(Icons.more_vert),
          onSelected: (accion) {
            switch (accion) {
              case 'DETALLE':
                _mostrarDetalle(d);
                break;
              case 'PDF':
                DocumentoPdf.imprimir(d);
                break;
              default:
                _cambiarEstado(d, accion);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'DETALLE', child: ListTile(leading: Icon(Icons.visibility), title: Text('Ver detalle'))),
            const PopupMenuItem(value: 'PDF', child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Generar PDF'))),
            if (sessionState.puede(Permisos.firmarRemitos)) ...[
              const PopupMenuDivider(),
              if (d.estado != 'FIRMADO' && d.estado != 'ANULADO')
                const PopupMenuItem(value: 'FIRMADO', child: ListTile(leading: Icon(Icons.verified), title: Text('Marcar como firmado'))),
              if (d.estado != 'EMITIDO' && d.estado != 'ANULADO')
                const PopupMenuItem(value: 'EMITIDO', child: ListTile(leading: Icon(Icons.send), title: Text('Marcar como emitido'))),
              if (d.estado != 'BORRADOR' && d.estado != 'ANULADO')
                const PopupMenuItem(value: 'BORRADOR', child: ListTile(leading: Icon(Icons.edit_note), title: Text('Marcar como borrador'))),
            ],
            if (sessionState.puede(Permisos.anularRemitos) && d.estado != 'ANULADO') ...[
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'ANULADO', child: ListTile(leading: Icon(Icons.cancel), title: Text('Anular documento'))),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _elegirFecha(bool desde) async {
    final seleccion = await showDatePicker(context: context, initialDate: (desde ? _desde : _hasta) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (seleccion != null) setState(() { if (desde) _desde = seleccion; else _hasta = seleccion; });
  }

  Future<void> _cambiarEstado(Documento d, String estado) async {
    if (estado == 'ANULADO') {
      final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Anular documento'), content: Text('¿Confirmás la anulación de ${d.numero}? Esta acción no revierte el movimiento de stock.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Anular'))]));
      if (ok != true) return;
    }
    try {
      await documentoRepository.cambiarEstado(d.id, estado);
      await _cargar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${d.numero} actualizado a $estado.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo cambiar el estado: $e')));
    }
  }

  void _mostrarDetalle(Documento d) {
    showDialog<void>(context: context, builder: (context) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760), child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.numero, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), Text('${d.tipoLegible} · ${_fechaHora(d.fecha)}')])), _estadoChip(d.estado), const SizedBox(width: 8), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
      const Divider(),
      Wrap(spacing: 28, runSpacing: 12, children: [_dato('Proyecto', d.proyecto), _dato('Responsable', d.responsable), _dato('Proveedor', d.proveedor), _dato('Almacén origen', d.almacenOrigen), _dato('Destino', d.almacenDestino.isNotEmpty ? d.almacenDestino : d.destinoExterno)]),
      const SizedBox(height: 18),
      const Text('Materiales', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SingleChildScrollView(child: DataTable(columns: const [DataColumn(label: Text('Código')), DataColumn(label: Text('Descripción')), DataColumn(label: Text('Cantidad')), DataColumn(label: Text('Unidad')), DataColumn(label: Text('Ubicación')), DataColumn(label: Text('Equipo')), DataColumn(label: Text('Costo')), DataColumn(label: Text('Total'))], rows: d.items.map((i) => DataRow(cells: [DataCell(Text(i.materialCodigo)), DataCell(Text(i.materialNombre)), DataCell(Text(_numero(i.cantidad))), DataCell(Text(i.unidad)), DataCell(Text(i.ubicacionDestino.isNotEmpty ? '${i.ubicacionOrigen} → ${i.ubicacionDestino}' : i.ubicacionOrigen)), DataCell(Text(i.equipoEtiqueta.isEmpty ? '-' : i.equipoEtiqueta)), DataCell(Text('${i.moneda} ${_numero(i.costoUnitario)}')), DataCell(Text('${i.moneda} ${_numero(i.total)}'))])).toList())))),
      const SizedBox(height: 8),
      Align(alignment: Alignment.centerRight, child: Text('Valor total: ${d.items.isEmpty ? '' : d.items.first.moneda} ${_numero(d.total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      if (d.observacion.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('Observaciones: ${d.observacion}')),
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => DocumentoPdf.imprimir(d),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generar PDF'),
            ),
            if (d.estado != 'FIRMADO' && d.estado != 'ANULADO')
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _cambiarEstado(d, 'FIRMADO');
                },
                icon: const Icon(Icons.verified),
                label: const Text('Marcar firmado'),
              ),
            if (d.estado != 'ANULADO')
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _cambiarEstado(d, 'ANULADO');
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Anular'),
              ),
          ],
        ),
      ),
    ])))));
  }

  Widget _dato(String titulo, String valor) => SizedBox(width: 210, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.black54)), Text(valor.isEmpty ? '-' : valor, style: const TextStyle(fontWeight: FontWeight.w600))]));
  Widget _estadoChip(String estado) { final color = switch (estado) { 'BORRADOR' => Colors.amber, 'FIRMADO' => Colors.blue, 'ANULADO' => Colors.red, _ => Colors.green }; return Chip(label: Text(estado), side: BorderSide.none, backgroundColor: color.withOpacity(.15), labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold)); }
  String _fechaCorta(DateTime f) => '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  String _fechaHora(DateTime f) => '${_fechaCorta(f)} ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  String _numero(num n) => n.toStringAsFixed(n % 1 == 0 ? 0 : 2);
}
