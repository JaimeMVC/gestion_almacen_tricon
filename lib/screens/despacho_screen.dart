import 'package:flutter/material.dart';
import '../models/stock_item.dart';
import '../models/equipo.dart';
import '../state/app_state.dart';

class DespachoScreen extends StatefulWidget {
  const DespachoScreen({super.key});
  @override
  State<DespachoScreen> createState() => _DespachoScreenState();
}

class _LineaDespacho {
  _LineaDespacho(this.stock);
  final StockItem stock;
  final TextEditingController cantidad = TextEditingController();
  void dispose() => cantidad.dispose();
}

class _DespachoScreenState extends State<DespachoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lineas = <_LineaDespacho>[];
  String? _almacenId;
  Equipo? _equipo;
  bool _guardando = false;
  final _destino = TextEditingController();
  final _responsable = TextEditingController(text: 'Ivan');
  final _observacion = TextEditingController();

  @override
  void dispose() {
    for (final linea in _lineas) { linea.dispose(); }
    _destino.dispose();
    _responsable.dispose();
    _observacion.dispose();
    super.dispose();
  }

  void _agregar(StockItem stock) {
    if (_lineas.any((l) => l.stock.id == stock.id)) return;
    setState(() => _lineas.add(_LineaDespacho(stock)));
  }

  Future<void> _confirmar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    if (_almacenId == null || _lineas.isEmpty) {
      _mensaje('Seleccione un almacén y agregue al menos un material.');
      return;
    }
    if (_equipo == null && _destino.text.trim().isEmpty) {
      _mensaje('Seleccione un equipo o escriba el destino/proyecto.');
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final linea in _lineas) {
      final cantidad = num.tryParse(linea.cantidad.text.trim().replaceAll(',', '.'));
      if (cantidad == null || cantidad <= 0 || cantidad > linea.stock.cantidad) {
        _mensaje('Revise la cantidad de ${linea.stock.material.codigo}.');
        return;
      }
      items.add({
        'material_id': linea.stock.materialId,
        'ubicacion_origen_id': linea.stock.ubicacionId,
        'cantidad': cantidad,
      });
    }
    setState(() => _guardando = true);
    try {
      final remitoId = await appState.registrarSalidaConsumoMultipleEnSupabase(
        almacenOrigenId: _almacenId!,
        items: items,
        destinoExterno: _destino.text,
        equipoId: _equipo?.id,
        usuario: _responsable.text,
        observacion: _observacion.text,
      );
      if (!mounted) return;
      _mensaje('Despacho registrado: ${items.length} materiales, un remito ($remitoId).');
      setState(() {
        for (final linea in _lineas) { linea.dispose(); }
        _lineas.clear();
        _equipo = null;
        _destino.clear();
        _observacion.clear();
      });
    } catch (e) {
      if (mounted) _mensaje('No se registró el despacho: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String mensaje) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(mensaje)));

  @override
  Widget build(BuildContext context) {
    final stock = appState.stock.where((s) => s.cantidad > 0 &&
        s.materialId.isNotEmpty && s.ubicacionId.isNotEmpty &&
        s.almacenId.isNotEmpty && s.almacenActivo).toList();
    final almacenes = <String, String>{};
    for (final s in stock) { almacenes[s.almacenId] = s.almacenEtiqueta; }
    final almacen = almacenes.containsKey(_almacenId) ? _almacenId : null;
    final disponibles = stock.where((s) => s.almacenId == almacen &&
        !_lineas.any((l) => l.stock.id == s.id)).toList();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(children: [
          const Text('Despacho de materiales', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('almacen-$almacen'),
            initialValue: almacen,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Almacén de origen', border: OutlineInputBorder()),
            items: almacenes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
            validator: (v) => v == null ? 'Seleccione un almacén' : null,
            onChanged: _guardando ? null : (v) => setState(() {
              _almacenId = v;
              for (final linea in _lineas) { linea.dispose(); }
              _lineas.clear();
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('equipo-${_equipo?.id}'),
            initialValue: _equipo?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Equipo (opcional si se indica destino)', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<String>(value: '', child: Text('Sin equipo - destino/proyecto')),
              ...appState.equiposActivos.map((e) => DropdownMenuItem(value: e.id, child: Text(e.etiqueta, overflow: TextOverflow.ellipsis))),
            ],
            onChanged: _guardando ? null : (id) => setState(() {
              _equipo = id == null || id.isEmpty ? null : appState.equiposActivos.firstWhere((e) => e.id == id);
            }),
          ),
          const SizedBox(height: 12),
          if (_equipo == null) ...[
            TextFormField(controller: _destino, decoration: const InputDecoration(labelText: 'Destino / proyecto', border: OutlineInputBorder()),
              validator: (v) => _equipo == null && (v == null || v.trim().isEmpty) ? 'Indique el destino' : null),
            const SizedBox(height: 12),
          ],
          TextFormField(controller: _responsable, decoration: const InputDecoration(labelText: 'Despachado por', border: OutlineInputBorder()),
            validator: (v) => v == null || v.trim().isEmpty ? 'Indique el responsable' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _observacion, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const Text('Materiales del despacho', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          for (final linea in _lineas) Card(
            key: ValueKey(linea.stock.id),
            child: Padding(padding: const EdgeInsets.all(12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${linea.stock.material.codigo} - ${linea.stock.material.nombre}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Ubicación: ${linea.stock.ubicacion} · Disponible: ${linea.stock.cantidad}'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: linea.cantidad,
                    enabled: !_guardando,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
                    validator: (v) {
                      final n = num.tryParse((v ?? '').replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Cantidad inválida';
                      if (n > linea.stock.cantidad) return 'Stock insuficiente';
                      return null;
                    },
                  )),
                  IconButton(tooltip: 'Quitar material', onPressed: _guardando ? null : () => setState(() {
                    _lineas.remove(linea);
                    WidgetsBinding.instance.addPostFrameCallback((_) => linea.dispose());
                  }), icon: const Icon(Icons.delete_outline)),
                ]),
              ],
            )),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey('agregar-${_lineas.length}-$almacen'),
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Agregar material / ubicación', border: OutlineInputBorder(), prefixIcon: Icon(Icons.add)),
            items: disponibles.map((s) => DropdownMenuItem(value: s.id,
              child: Text('${s.material.codigo} - ${s.material.nombre} | ${s.ubicacion} | Stock: ${s.cantidad}', overflow: TextOverflow.ellipsis))).toList(),
            onChanged: _guardando || almacen == null ? null : (id) {
              if (id == null) return;
              _agregar(disponibles.firstWhere((s) => s.id == id));
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _guardando || _lineas.isEmpty ? null : _confirmar,
            icon: const Icon(Icons.local_shipping),
            label: Text(_guardando ? 'Registrando...' : 'Confirmar despacho (${_lineas.length} materiales / 1 remito)'),
          ),
        ]),
      ),
    );
  }
}
