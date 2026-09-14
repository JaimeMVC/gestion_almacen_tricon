import 'package:flutter/material.dart';

import '../models/almacen.dart';
import '../models/stock_item.dart';
import '../models/ubicacion.dart';
import '../state/app_state.dart';

class TransferenciasScreen extends StatefulWidget {
  const TransferenciasScreen({super.key});

  @override
  State<TransferenciasScreen> createState() => _TransferenciasScreenState();
}

class _TransferenciasScreenState extends State<TransferenciasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _observacionController = TextEditingController();

  StockItem? _stockOrigen;
  Almacen? _almacenDestino;
  Ubicacion? _ubicacionDestino;

  @override
  void dispose() {
    _cantidadController.dispose();
    _usuarioController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  List<Almacen> _almacenesDestino(List<Almacen> almacenes) {
    return almacenes
        .where((a) => a.activo && a.id != _stockOrigen?.almacenId)
        .toList(growable: false);
  }

  List<Ubicacion> _ubicacionesDestino(List<Ubicacion> ubicaciones) {
    if (_almacenDestino == null) return const [];
    return ubicaciones
        .where((u) => u.activa && u.almacenId == _almacenDestino!.id)
        .toList(growable: false);
  }

  num? _parseNumero(String value) {
    return num.tryParse(value.trim().replaceAll(',', '.'));
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stockOrigen == null ||
        _almacenDestino == null ||
        _ubicacionDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá origen y destino.')),
      );
      return;
    }

    final cantidad = _parseNumero(_cantidadController.text)!;

    try {
      final remitoId = await appState.registrarTransferenciaEnSupabase(
        stockOrigen: _stockOrigen!,
        almacenDestino: _almacenDestino!,
        ubicacionDestino: _ubicacionDestino!,
        cantidad: cantidad,
        usuario: _usuarioController.text,
        observacion: _observacionController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remitoId.isEmpty
                ? 'Transferencia registrada correctamente.'
                : 'Transferencia registrada correctamente. Remito generado.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _limpiar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar la transferencia: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limpiar() {
    setState(() {
      _stockOrigen = null;
      _almacenDestino = null;
      _ubicacionDestino = null;
      _cantidadController.clear();
      _observacionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final stockDisponible = appState.stock
            .where((s) => s.cantidad > 0 && s.almacenActivo)
            .toList(growable: false);
        final almacenesDestino = _almacenesDestino(appState.almacenesActivos);
        final ubicacionesDestino = _ubicacionesDestino(appState.ubicacionesActivas);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transferencia entre almacenes',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Descuenta stock del origen, ingresa en destino y genera el remito de transferencia automáticamente.',
                ),
                const SizedBox(height: 20),
                if (appState.errorTransferencia != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appState.errorTransferencia!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Origen',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<StockItem>(
                            value: stockDisponible.contains(_stockOrigen)
                                ? _stockOrigen
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Material / posición de stock',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory_2),
                            ),
                            items: stockDisponible.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(
                                  '${item.material.codigo} - ${item.material.nombre} | '
                                  '${item.almacenEtiqueta} | ${item.ubicacion} | Disp.: ${item.cantidad}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: appState.registrandoTransferencia
                                ? null
                                : (value) {
                                    setState(() {
                                      _stockOrigen = value;
                                      _almacenDestino = null;
                                      _ubicacionDestino = null;
                                    });
                                  },
                            validator: (value) => value == null
                                ? 'Seleccioná una posición de stock de origen.'
                                : null,
                          ),
                          if (_stockOrigen != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Origen: ${_stockOrigen!.almacenEtiqueta} / ${_stockOrigen!.ubicacion} · '
                                'Disponible: ${_stockOrigen!.cantidad}',
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Text(
                            'Destino',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 720;
                              final fields = [
                                Expanded(
                                  child: DropdownButtonFormField<Almacen>(
                                    value: almacenesDestino.contains(_almacenDestino)
                                        ? _almacenDestino
                                        : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Almacén destino',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: almacenesDestino.map((almacen) {
                                      return DropdownMenuItem(
                                        value: almacen,
                                        child: Text(
                                          '${almacen.codigo} - ${almacen.nombre}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _stockOrigen == null ||
                                            appState.registrandoTransferencia
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _almacenDestino = value;
                                              _ubicacionDestino = null;
                                            });
                                          },
                                    validator: (value) => value == null
                                        ? 'Seleccioná el almacén destino.'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12, height: 12),
                                Expanded(
                                  child: DropdownButtonFormField<Ubicacion>(
                                    value: ubicacionesDestino.contains(_ubicacionDestino)
                                        ? _ubicacionDestino
                                        : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Ubicación destino',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: ubicacionesDestino.map((ubicacion) {
                                      return DropdownMenuItem(
                                        value: ubicacion,
                                        child: Text(
                                          ubicacion.codigo,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _almacenDestino == null ||
                                            appState.registrandoTransferencia
                                        ? null
                                        : (value) => setState(
                                            () => _ubicacionDestino = value),
                                    validator: (value) => value == null
                                        ? 'Seleccioná la ubicación destino.'
                                        : null,
                                  ),
                                ),
                              ];
                              return narrow
                                  ? Column(
                                      children: fields
                                          .map((w) => w is Expanded ? w.child : w)
                                          .toList(),
                                    )
                                  : Row(children: fields);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cantidadController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad a transferir',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            validator: (value) {
                              final cantidad = _parseNumero(value ?? '');
                              if (cantidad == null || cantidad <= 0) {
                                return 'Ingresá una cantidad mayor que cero.';
                              }
                              if (_stockOrigen != null &&
                                  cantidad > _stockOrigen!.cantidad) {
                                return 'La cantidad supera el stock disponible.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usuarioController,
                            decoration: const InputDecoration(
                              labelText: 'Responsable',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _observacionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Observación',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: appState.registrandoTransferencia
                                    ? null
                                    : _limpiar,
                                child: const Text('Limpiar'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: appState.registrandoTransferencia
                                    ? null
                                    : _registrar,
                                icon: appState.registrandoTransferencia
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.swap_horiz),
                                label: Text(
                                  appState.registrandoTransferencia
                                      ? 'Registrando...'
                                      : 'Registrar transferencia',
                                ),
                              ),
                            ],
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
