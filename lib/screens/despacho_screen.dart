import 'package:flutter/material.dart';

import '../models/almacen.dart';
import '../models/equipo.dart';
import '../models/stock_item.dart';
import '../models/ubicacion.dart';
import '../state/app_state.dart';

class DespachoScreen extends StatefulWidget {
  const DespachoScreen({super.key});

  @override
  State<DespachoScreen> createState() => _DespachoScreenState();
}

class _DespachoScreenState extends State<DespachoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _destinoController = TextEditingController();
  final _usuarioController = TextEditingController(text: 'Operador');
  final _observacionController = TextEditingController();

  Almacen? _almacen;
  Ubicacion? _ubicacion;
  StockItem? _stockSeleccionado;
  Equipo? _equipo;

  @override
  void dispose() {
    _cantidadController.dispose();
    _destinoController.dispose();
    _usuarioController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  List<Ubicacion> _ubicacionesDisponibles() {
    if (_almacen == null) return const [];
    final idsConStock = appState.stock
        .where((s) => s.almacenId == _almacen!.id && s.cantidad > 0)
        .map((s) => s.ubicacionId)
        .toSet();

    return appState.ubicacionesActivas
        .where((u) => u.almacenId == _almacen!.id && idsConStock.contains(u.id))
        .toList(growable: false);
  }

  List<StockItem> _stockDisponible() {
    if (_almacen == null || _ubicacion == null) return const [];
    return appState.stock
        .where(
          (s) =>
              s.almacenId == _almacen!.id &&
              s.ubicacionId == _ubicacion!.id &&
              s.cantidad > 0,
        )
        .toList(growable: false);
  }

  num? _parseNumero(String value) {
    return num.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stockSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná una posición de stock.')),
      );
      return;
    }

    final cantidad = _parseNumero(_cantidadController.text)!;

    try {
      final remitoId = await appState.registrarSalidaConsumoEnSupabase(
        stockOrigen: _stockSeleccionado!,
        cantidad: cantidad,
        destinoExterno: _destinoController.text,
        equipoId: _equipo?.id,
        usuario: _usuarioController.text,
        observacion: _observacionController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remitoId.isEmpty
                ? 'Despacho registrado correctamente.'
                : 'Despacho registrado correctamente. Remito generado.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _limpiar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar el despacho: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limpiar() {
    setState(() {
      _almacen = null;
      _ubicacion = null;
      _stockSeleccionado = null;
      _equipo = null;
      _cantidadController.clear();
      _destinoController.clear();
      _observacionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final ubicaciones = _ubicacionesDisponibles();
        final stock = _stockDisponible();
        final disponible = _stockSeleccionado?.cantidad ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Despacho para consumo',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Descuenta stock del almacén seleccionado y genera automáticamente el movimiento y el remito de salida.',
                ),
                const SizedBox(height: 20),
                if (appState.errorDespacho != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      appState.errorDespacho!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          SizedBox(
                            width: 430,
                            child: DropdownButtonFormField<Almacen>(
                              value: _almacen,
                              decoration: const InputDecoration(
                                labelText: 'Almacén origen',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.warehouse),
                              ),
                              items: appState.almacenesActivos
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a,
                                      child: Text('${a.codigo} - ${a.nombre}'),
                                    ),
                                  )
                                  .toList(),
                              validator: (value) => value == null
                                  ? 'Seleccioná un almacén'
                                  : null,
                              onChanged: appState.registrandoDespacho
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _almacen = value;
                                        _ubicacion = null;
                                        _stockSeleccionado = null;
                                      });
                                    },
                            ),
                          ),
                          SizedBox(
                            width: 430,
                            child: DropdownButtonFormField<Ubicacion>(
                              value: _ubicacion,
                              decoration: const InputDecoration(
                                labelText: 'Ubicación origen',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              items: ubicaciones
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u.descripcion.isEmpty ? u.codigo : '${u.codigo} - ${u.descripcion}'),
                                    ),
                                  )
                                  .toList(),
                              validator: (value) => value == null
                                  ? 'Seleccioná una ubicación'
                                  : null,
                              onChanged: _almacen == null ||
                                      appState.registrandoDespacho
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _ubicacion = value;
                                        _stockSeleccionado = null;
                                      });
                                    },
                            ),
                          ),
                          SizedBox(
                            width: 878,
                            child: DropdownButtonFormField<StockItem>(
                              value: _stockSeleccionado,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Material disponible',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory_2),
                              ),
                              items: stock
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        '${s.material.codigo} - ${s.material.nombre} | Disponible: ${s.cantidad}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              validator: (value) => value == null
                                  ? 'Seleccioná un material'
                                  : null,
                              onChanged: _ubicacion == null ||
                                      appState.registrandoDespacho
                                  ? null
                                  : (value) => setState(
                                        () => _stockSeleccionado = value,
                                      ),
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: TextFormField(
                              controller: _cantidadController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Cantidad',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.numbers),
                                helperText: _stockSeleccionado == null
                                    ? null
                                    : 'Disponible: $disponible',
                              ),
                              validator: (value) {
                                final cantidad = _parseNumero(value ?? '');
                                if (cantidad == null || cantidad <= 0) {
                                  return 'Ingresá una cantidad válida';
                                }
                                if (_stockSeleccionado != null &&
                                    cantidad > _stockSeleccionado!.cantidad) {
                                  return 'Supera el stock disponible';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            width: 580,
                            child: DropdownButtonFormField<Equipo?>(
                              value: _equipo,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Equipo / activo destino',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.precision_manufacturing),
                                helperText: 'Opcional. Permite imputar el consumo a un equipo.',
                              ),
                              items: [
                                const DropdownMenuItem<Equipo?>(
                                  value: null,
                                  child: Text('Sin equipo específico'),
                                ),
                                ...appState.equiposActivos.map(
                                  (e) => DropdownMenuItem<Equipo?>(
                                    value: e,
                                    child: Text(
                                      '${e.codigo} - ${e.descripcion}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: appState.registrandoDespacho
                                  ? null
                                  : (value) => setState(() => _equipo = value),
                            ),
                          ),
                          SizedBox(
                            width: 580,
                            child: TextFormField(
                              controller: _destinoController,
                              decoration: const InputDecoration(
                                labelText: 'Destino / proyecto de consumo',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business_center),
                              ),
                              validator: (value) => value == null ||
                                      value.trim().isEmpty
                                  ? 'Indicá el destino o proyecto'
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: 430,
                            child: TextFormField(
                              controller: _usuarioController,
                              decoration: const InputDecoration(
                                labelText: 'Responsable',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) => value == null ||
                                      value.trim().isEmpty
                                  ? 'Indicá el responsable'
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: 878,
                            child: TextFormField(
                              controller: _observacionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Observación',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.notes),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 878,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: appState.registrandoDespacho
                                    ? null
                                    : _registrar,
                                icon: appState.registrandoDespacho
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.local_shipping),
                                label: Text(
                                  appState.registrandoDespacho
                                      ? 'Registrando...'
                                      : 'Confirmar despacho',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
