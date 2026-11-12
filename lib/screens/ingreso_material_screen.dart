import 'package:flutter/material.dart';

import '../models/almacen.dart';
import '../models/material_item.dart';
import '../models/proveedor.dart';
import '../models/region_compra.dart';
import '../models/ubicacion.dart';
import '../state/app_state.dart';

class IngresoMaterialScreen extends StatefulWidget {
  const IngresoMaterialScreen({super.key});

  @override
  State<IngresoMaterialScreen> createState() => _IngresoMaterialScreenState();
}

class _IngresoMaterialScreenState extends State<IngresoMaterialScreen> {
  final _formKey = GlobalKey<FormState>();

  Almacen? _almacen;
  Ubicacion? _ubicacion;
  MaterialItem? _material;
  Proveedor? _proveedor;
  RegionCompra? _region;
  DateTime? _fechaCompra;

  final _cantidad = TextEditingController();
  final _costo = TextEditingController(text: '0');
  final _ordenCompra = TextEditingController();
  final _factura = TextEditingController();
  final _usuario = TextEditingController(text: 'Ivan');
  final _observacion = TextEditingController();

  String _moneda = 'ARS';
  static const _monedas = ['ARS', 'BRL', 'USD', 'BOB', 'EUR'];

  @override
  void initState() {
    super.initState();
    Future.microtask(appState.cargarDatosRecepcionDesdeSupabase);
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _costo.dispose();
    _ordenCompra.dispose();
    _factura.dispose();
    _usuario.dispose();
    _observacion.dispose();
    super.dispose();
  }

  num? _parseNumero(String value) {
    return num.tryParse(value.trim().replaceAll(',', '.'));
  }

  List<Ubicacion> _ubicacionesDisponibles() {
    if (_almacen == null) return const [];
    return appState.ubicaciones
        .where((u) => u.activa && u.almacenId == _almacen!.id)
        .toList(growable: false);
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaCompra ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _fechaCompra = fecha);
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin especificar';
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_almacen == null || _ubicacion == null || _material == null) return;

    final cantidad = _parseNumero(_cantidad.text)!;
    final costo = _parseNumero(_costo.text)!;

    try {
      await appState.registrarRecepcionEnSupabase(
        material: _material!,
        almacen: _almacen!,
        ubicacion: _ubicacion!,
        cantidad: cantidad,
        costoUnitario: costo,
        moneda: _moneda,
        proveedor: _proveedor,
        region: _region,
        ordenCompra: _ordenCompra.text,
        factura: _factura.text,
        fechaCompra: _fechaCompra,
        usuario: _usuario.text,
        observacion: _observacion.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recepción registrada: ${_material!.codigo} · $cantidad $_moneda',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      setState(() {
        _material = null;
        _proveedor = null;
        _region = null;
        _fechaCompra = null;
      });
      _cantidad.clear();
      _costo.text = '0';
      _ordenCompra.clear();
      _factura.clear();
      _observacion.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar la recepción: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final almacenes = appState.almacenesActivos;
        final ubicaciones = _ubicacionesDisponibles();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Text(
                'Recepción de material',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'El ingreso actualiza stock, costo promedio e historial directamente en Supabase.',
              ),
              const SizedBox(height: 20),
              if (almacenes.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No hay almacenes activos. Creá o reactivá un almacén antes de registrar una recepción.',
                    ),
                  ),
                )
              else
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destino del ingreso',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _campo(
                                width: 390,
                                child: DropdownButtonFormField<Almacen>(
                                  isExpanded: true,
                                  value: _almacen,
                                  decoration: const InputDecoration(
                                    labelText: 'Almacén *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.warehouse),
                                  ),
                                  items: almacenes
                                      .map(
                                        (a) => DropdownMenuItem(
                                          value: a,
                                          child: Text(
                                            '${a.codigo} - ${a.nombre}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  validator: (value) => value == null
                                      ? 'Seleccione un almacén'
                                      : null,
                                  onChanged: (value) {
                                    setState(() {
                                      _almacen = value;
                                      _ubicacion = null;
                                    });
                                  },
                                ),
                              ),
                              _campo(
                                width: 390,
                                child: DropdownButtonFormField<Ubicacion>(
                                  isExpanded: true,
                                  value: _ubicacion,
                                  decoration: const InputDecoration(
                                    labelText: 'Ubicación destino *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_on),
                                  ),
                                  items: ubicaciones
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(
                                            u.descripcion.isEmpty
                                                ? u.codigo
                                                : '${u.codigo} - ${u.descripcion}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  validator: (value) {
                                    if (_almacen == null) {
                                      return 'Seleccione primero el almacén';
                                    }
                                    return value == null
                                        ? 'Seleccione una ubicación'
                                        : null;
                                  },
                                  onChanged: _almacen == null
                                      ? null
                                      : (value) =>
                                          setState(() => _ubicacion = value),
                                ),
                              ),
                            ],
                          ),
                          if (_almacen != null && ubicaciones.isEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'El almacén seleccionado no tiene ubicaciones activas.',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ],
                          const Divider(height: 36),
                          const Text(
                            'Material y cantidad',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _campo(
                                width: 560,
                                child: DropdownButtonFormField<MaterialItem>(
                                  isExpanded: true,
                                  value: _material,

                                  decoration: const InputDecoration(
                                    labelText: 'Material *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.inventory_2),
                                  ),
                                  items: appState.materiales
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(
                                            '${m.codigo} - ${m.nombre} | ${m.familia}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  validator: (value) => value == null
                                      ? 'Seleccione un material'
                                      : null,
                                  onChanged: (value) =>
                                      setState(() => _material = value),
                                ),
                              ),
                              _campo(
                                width: 220,
                                child: TextFormField(
                                  controller: _cantidad,
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.numbers),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    final numero = _parseNumero(value ?? '');
                                    if (numero == null || numero <= 0) {
                                      return 'Ingrese una cantidad mayor a 0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 36),
                          const Text(
                            'Datos de compra e historial',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _campo(
                                width: 390,
                                child: DropdownButtonFormField<Proveedor>(
                                  isExpanded: true,
                                  value: _proveedor,

                                  decoration: const InputDecoration(
                                    labelText: 'Proveedor *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.business),
                                  ),
                                  items: appState.proveedoresActivos
                                      .map(
                                        (p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(
                                            p.etiqueta,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  validator: (value) => value == null
                                      ? 'Seleccione un proveedor'
                                      : null,
                                  onChanged: (value) {
                                    setState(() {
                                      _proveedor = value;
                                      if (value != null && value.regionId.isNotEmpty) {
                                        for (final region in appState.regionesActivas) {
                                          if (region.id == value.regionId) {
                                            _region = region;
                                            break;
                                          }
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                              _campo(
                                width: 320,
                                child: DropdownButtonFormField<RegionCompra>(
                                  isExpanded: true,
                                  value: _region,

                                  decoration: const InputDecoration(
                                    labelText: 'Región de compra (opcional)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.public),
                                  ),
                                  items: appState.regionesActivas
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(
                                            r.etiqueta,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _region = value),
                                ),
                              ),
                              _campo(
                                width: 220,
                                child: TextFormField(
                                  controller: _costo,
                                  decoration: const InputDecoration(
                                    labelText: 'Costo unitario',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.payments),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    final numero = _parseNumero(value ?? '');
                                    if (numero == null || numero < 0) {
                                      return 'Ingrese un costo válido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              _campo(
                                width: 150,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _moneda,
                                  decoration: const InputDecoration(
                                    labelText: 'Moneda',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _monedas
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _moneda = value ?? 'ARS'),
                                ),
                              ),
                              _campo(
                                width: 260,
                                child: TextFormField(
                                  controller: _ordenCompra,
                                  decoration: const InputDecoration(
                                    labelText: 'Orden de compra',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              _campo(
                                width: 260,
                                child: TextFormField(
                                  controller: _factura,
                                  decoration: const InputDecoration(
                                    labelText: 'Factura',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 260,
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: _seleccionarFecha,
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text(
                                    'Compra: ${_formatearFecha(_fechaCompra)}',
                                  ),
                                ),
                              ),
                              _campo(
                                width: 260,
                                child: TextFormField(
                                  controller: _usuario,
                                  decoration: const InputDecoration(
                                    labelText: 'Responsable',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                              ),
                              _campo(
                                width: 540,
                                child: TextFormField(
                                  controller: _observacion,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Observación',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: appState.registrandoRecepcion
                                  ? null
                                  : _registrar,
                              icon: appState.registrandoRecepcion
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                appState.registrandoRecepcion
                                    ? 'Registrando...'
                                    : 'Registrar recepción',
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
        );
      },
    );
  }

  Widget _campo({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }
}
