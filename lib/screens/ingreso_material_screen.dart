import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/auth_state.dart';
import '../services/supabase_service.dart';
import '../pdf/documento_pdf.dart';
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

  bool _transito = false;
  bool _procesandoTransito = false;
  String? _solicitudTransito;
  Map<String, dynamic>? _datosPendientes;
  final _destinoTransito = TextEditingController();

  String _nuevoId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0,8)}-${h.substring(8,12)}-${h.substring(12,16)}-${h.substring(16,20)}-${h.substring(20)}';
  }

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
    _destinoTransito.dispose();
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
        .where((u) => u.activa && u.almacenId == _almacen!.id && u.codigo != 'TRANSITO')
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

  Future<void> _buscarYSeleccionarMaterial() async {
    final busqueda = TextEditingController();
    final seleccionado = await showDialog<MaterialItem>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, actualizarDialogo) {
          final texto = busqueda.text.trim().toLowerCase();
          final resultados = appState.materiales.where((material) {
            final contenido =
                '${material.codigo} ${material.nombre} ${material.familia}'
                    .toLowerCase();
            return contenido.contains(texto);
          }).toList(growable: false);

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 650),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Buscar material',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: busqueda,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Escribí código, descripción o familia',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => actualizarDialogo(() {}),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${resultados.length} materiales encontrados'),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: resultados.isEmpty
                          ? const Center(child: Text('No se encontraron materiales'))
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: resultados.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final material = resultados[index];
                                return ListTile(
                                  title: Text(material.codigo,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${material.nombre} | ${material.familia}'),
                                  onTap: () => Navigator.of(dialogContext).pop(material),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    busqueda.dispose();
    if (seleccionado != null && mounted) {
      setState(() => _material = seleccionado);
      _formKey.currentState?.validate();
    }
  }

  Future<void> _registrarTransito() async {
    if (!sessionState.puede('recepcionar') || !sessionState.puede('despachar')) return;
    if (_datosPendientes == null) {
      if (!_formKey.currentState!.validate() || _almacen == null || _material == null) return;
      _datosPendientes = {
        'almacen_id': _almacen!.id, 'material_id': _material!.id,
        'cantidad': _parseNumero(_cantidad.text), 'costo_unitario': _parseNumero(_costo.text),
        'moneda': _moneda, 'proveedor_id': _proveedor?.id, 'region_id': _region?.id,
        'orden_compra': _ordenCompra.text, 'factura': _factura.text,
        'fecha_compra': _fechaCompra?.toIso8601String().split('T').first,
        'usuario': _usuario.text, 'observacion': _observacion.text,
        'destino': _destinoTransito.text.trim(),
      };
      _solicitudTransito = _nuevoId();
    }
    setState(() => _procesandoTransito = true);
    String? remito;
    try {
      final resultado = await Supabase.instance.client.rpc('registrar_transito_directo', params: {
        'p_id': _solicitudTransito, 'p_datos': _datosPendientes,
      });
      remito = resultado.toString();
    } catch (error) {
      if (!mounted) return;
      // Un error SQL confirmado revierte toda la transacción; un error de red puede ser ambiguo.
      if (error is PostgrestException && RegExp(r'^[0-9A-Z]{5}$').hasMatch(error.code ?? '') && !(error.code ?? '').startsWith('08')) {
        _datosPendientes = null;
        _solicitudTransito = null;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tránsito no confirmado: $error. Si hay una solicitud pendiente, reintente sin cambiar los datos.')));
    } finally {
      if (mounted) setState(() => _procesandoTransito = false);
    }
    if (!mounted || remito == null) return;
    setState(() {
      _datosPendientes = null; _solicitudTransito = null;
      _transito = false; _material = null; _proveedor = null; _region = null; _fechaCompra = null;
      _cantidad.clear(); _costo.text = '0'; _ordenCompra.clear(); _factura.clear(); _observacion.clear(); _destinoTransito.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recepción y despacho registrados. Remito emitido.')));
    if (!sessionState.puede('imprimir_remitos')) return;
    final imprimir = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Tránsito registrado'), content: const Text('¿Desea imprimir el remito de salida?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cerrar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Imprimir'))],
    ));
    if (imprimir == true && mounted) {
      try { await DocumentoPdf.imprimir(await supabaseService.obtenerDocumentoPorId(remito)); }
      catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Remito registrado. Consulte Remitos para imprimir: $error'))); }
    }
  }

  Future<void> _registrar() async {
    if (_procesandoTransito) return;
    if (_transito) { await _registrarTransito(); return; }
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
                          if (sessionState.puede('despachar'))
                            SwitchListTile(
                              title: const Text('Material en tránsito'),
                              subtitle: const Text('Despacho total y remito automático'),
                              value: _transito,
                              onChanged: _procesandoTransito || _datosPendientes != null ? null : (v) => setState(() { _transito = v; _ubicacion = null; }),
                            ),
                          if (_transito) ...[
                            TextFormField(controller: _destinoTransito, decoration: const InputDecoration(labelText: 'Destino final / obra / equipo *', border: OutlineInputBorder()), validator: (v) => (v ?? '').trim().isEmpty ? 'Indique el destino' : null),
                            const SizedBox(height: 12),
                            const Text('Ubicación automática: TRANSITO. Variación de stock: 0.'),
                          ],
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
                              if (!_transito) _campo(
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
                          if (!_transito && _almacen != null && ubicaciones.isEmpty) ...[
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
                                child: FormField<MaterialItem>(
                                  validator: (_) => _material == null
                                      ? 'Seleccione un material'
                                      : null,
                                  builder: (campo) => InkWell(
                                    onTap: _buscarYSeleccionarMaterial,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Material *',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.inventory_2),
                                        suffixIcon: const Icon(Icons.search),
                                        errorText: campo.errorText,
                                      ),
                                      child: Text(
                                        _material == null
                                            ? 'Tocá para buscar por código o descripción'
                                            : '${_material!.codigo} - ${_material!.nombre} | ${_material!.familia}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _material == null
                                              ? Theme.of(context).hintColor
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
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
                              onPressed: (appState.registrandoRecepcion || _procesandoTransito)
                                  ? null
                                  : _registrar,
                              icon: (appState.registrandoRecepcion || _procesandoTransito)
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                (appState.registrandoRecepcion || _procesandoTransito)
                                    ? 'Registrando...'
                                    : (_transito ? (_datosPendientes != null ? 'Reintentar tránsito pendiente' : 'Registrar recepción y despacho') : 'Registrar recepción'),
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
