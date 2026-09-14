import 'package:flutter/material.dart';

import '../models/equipo.dart';
import '../state/app_state.dart';

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  String _busqueda = '';
  String? _categoria;
  bool _mostrarInactivos = false;

  List<Equipo> get _filtrados {
    final texto = _busqueda.trim().toLowerCase();
    return appState.equipos.where((e) {
      if (!_mostrarInactivos && !e.activo) return false;
      if (_categoria != null && e.categoria != _categoria) return false;
      return texto.isEmpty ||
          e.codigo.toLowerCase().contains(texto) ||
          e.descripcion.toLowerCase().contains(texto) ||
          e.marca.toLowerCase().contains(texto) ||
          e.categoria.toLowerCase().contains(texto) ||
          e.capacidad.toLowerCase().contains(texto);
    }).toList(growable: false);
  }

  List<String> get _categorias {
    final valores = appState.equipos
        .map((e) => e.categoria.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return valores;
  }

  Future<void> _formulario([Equipo? actual]) async {
    final resultado = await showDialog<Equipo>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EquipoDialog(equipo: actual),
    );

    if (resultado == null || !mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      await appState.guardarEquipoEnSupabase(resultado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(actual == null ? 'Equipo creado.' : 'Equipo actualizado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.errorEquipos ?? 'No se pudo guardar el equipo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verHistorial(Equipo equipo) async {
    try {
      await appState.cargarMovimientosDesdeSupabase();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.errorMovimientos ?? 'No se pudo cargar el historial.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!mounted) return;

    final consumos = appState.movimientos.where((m) {
      if (m.equipoId != equipo.id) return false;
      final tipo = m.tipo.toLowerCase();
      return tipo.contains('consumo') ||
          tipo.contains('salida') ||
          tipo.contains('despacho');
    }).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    final totales = <String, num>{};
    final materiales = <String>{};
    num cantidad = 0;
    for (final m in consumos) {
      cantidad += m.cantidad;
      materiales.add(m.codigoMaterial);
      totales[m.moneda] = (totales[m.moneda] ?? 0) + m.valorTotal;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 760),
              child: Padding(
                padding: EdgeInsets.all(compact ? 14 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.precision_manufacturing),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${equipo.codigo} - ${equipo.descripcion}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [equipo.marca, equipo.categoria, equipo.capacidad]
                                    .where((e) => e.trim().isNotEmpty)
                                    .join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _resumenHistorial('Consumos', '${consumos.length}', Icons.receipt_long, compact: compact),
                        _resumenHistorial('Materiales', '${materiales.length}', Icons.category, compact: compact),
                        _resumenHistorial('Cantidad total', _numero(cantidad), Icons.numbers, compact: compact),
                        ...totales.entries.map(
                          (e) => _resumenHistorial(
                            'Gasto ${e.key}',
                            _numero(e.value),
                            Icons.payments,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Historial de consumos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: consumos.isEmpty
                          ? const Center(
                              child: Text('Este equipo todavía no registra consumos.'),
                            )
                          : compact
                              ? ListView.separated(
                                  itemCount: consumos.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final m = consumos[index];
                                    return Card(
                                      margin: EdgeInsets.zero,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${m.codigoMaterial} - ${m.nombreMaterial}',
                                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                Text(_fecha(m.fecha)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 16,
                                              runSpacing: 6,
                                              children: [
                                                Text('Cantidad: ${_numero(m.cantidad)}'),
                                                Text('Valor: ${m.moneda} ${_numero(m.valorTotal)}'),
                                                if (m.usuario.trim().isNotEmpty) Text('Responsable: ${m.usuario}'),
                                                if (m.remitoNumero.trim().isNotEmpty) Text('Remito: ${m.remitoNumero}'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Card(
                                  margin: EdgeInsets.zero,
                                  clipBehavior: Clip.antiAlias,
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                        child: DataTable(
                                          columnSpacing: 28,
                                          columns: const [
                                            DataColumn(label: Text('Fecha')),
                                            DataColumn(label: Text('Código')),
                                            DataColumn(label: Text('Material')),
                                            DataColumn(label: Text('Cantidad'), numeric: true),
                                            DataColumn(label: Text('Moneda')),
                                            DataColumn(label: Text('Valor'), numeric: true),
                                            DataColumn(label: Text('Responsable')),
                                            DataColumn(label: Text('Remito')),
                                          ],
                                          rows: consumos
                                              .map(
                                                (m) => DataRow(cells: [
                                                  DataCell(Text(_fecha(m.fecha))),
                                                  DataCell(Text(m.codigoMaterial)),
                                                  DataCell(
                                                    SizedBox(
                                                      width: 200,
                                                      child: Text(m.nombreMaterial),
                                                    ),
                                                  ),
                                                  DataCell(Text(_numero(m.cantidad))),
                                                  DataCell(Text(m.moneda)),
                                                  DataCell(Text(_numero(m.valorTotal))),
                                                  DataCell(Text(m.usuario)),
                                                  DataCell(Text(m.remitoNumero)),
                                                ]),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _resumenHistorial(
    String titulo,
    String valor,
    IconData icono, {
    required bool compact,
  }) {
    return SizedBox(
      width: compact ? 155 : 185,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(radius: 18, child: Icon(icono, size: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      valor,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  Future<void> _cambiarEstado(Equipo equipo) async {
    try {
      await appState.cambiarEstadoEquipo(equipo: equipo, activo: !equipo.activo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.errorEquipos ?? 'No se pudo cambiar el estado.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _accionesEquipo(Equipo e, {bool compact = false}) {
    if (compact) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          OutlinedButton.icon(
            onPressed: () => _verHistorial(e),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Historial'),
          ),
          OutlinedButton.icon(
            onPressed: () => _formulario(e),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Editar'),
          ),
          OutlinedButton.icon(
            onPressed: () => _cambiarEstado(e),
            icon: Icon(e.activo ? Icons.block : Icons.check_circle, size: 18),
            label: Text(e.activo ? 'Inactivar' : 'Activar'),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Ver historial y costos',
          onPressed: () => _verHistorial(e),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Editar',
          onPressed: () => _formulario(e),
        ),
        IconButton(
          icon: Icon(e.activo ? Icons.block : Icons.check_circle),
          tooltip: e.activo ? 'Inactivar' : 'Activar',
          onPressed: () => _cambiarEstado(e),
        ),
      ],
    );
  }

  Widget _listaCompacta(List<Equipo> equipos) {
    return ListView.separated(
      itemCount: equipos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = equipos[index];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.codigo} - ${e.descripcion}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [e.marca, e.categoria, e.capacidad]
                                .where((v) => v.trim().isNotEmpty)
                                .join(' · '),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(label: Text(e.activo ? 'Activo' : 'Inactivo')),
                  ],
                ),
                const SizedBox(height: 12),
                _accionesEquipo(e, compact: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tablaDesktop(List<Equipo> equipos) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Código')),
                DataColumn(label: Text('Descripción')),
                DataColumn(label: Text('Marca')),
                DataColumn(label: Text('Categoría')),
                DataColumn(label: Text('Capacidad')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: equipos
                  .map(
                    (e) => DataRow(cells: [
                      DataCell(Text(e.codigo)),
                      DataCell(Text(e.descripcion)),
                      DataCell(Text(e.marca)),
                      DataCell(Text(e.categoria)),
                      DataCell(Text(e.capacidad)),
                      DataCell(Chip(label: Text(e.activo ? 'Activo' : 'Inactivo'))),
                      DataCell(_accionesEquipo(e)),
                    ]),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final equipos = _filtrados;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1050;
            final veryCompact = constraints.maxWidth < 700;
            final horizontalPadding = veryCompact ? 14.0 : 24.0;

            return Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      const Text(
                        'Maestro de Equipos',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      FilledButton.icon(
                        onPressed: () => _formulario(),
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo equipo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: veryCompact ? constraints.maxWidth - (horizontalPadding * 2) : 420,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Buscar por código, descripción, marca o categoría',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => setState(() => _busqueda = v),
                        ),
                      ),
                      SizedBox(
                        width: veryCompact ? constraints.maxWidth - (horizontalPadding * 2) : 280,
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          value: _categoria,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ..._categorias.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _categoria = v),
                        ),
                      ),
                      FilterChip(
                        selected: _mostrarInactivos,
                        label: const Text('Mostrar inactivos'),
                        onSelected: (v) => setState(() => _mostrarInactivos = v),
                      ),
                      IconButton(
                        onPressed: appState.cargarEquiposDesdeSupabase,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualizar',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (appState.cargandoEquipos)
                    const LinearProgressIndicator()
                  else if (appState.errorEquipos != null)
                    Text(
                      appState.errorEquipos!,
                      style: const TextStyle(color: Colors.red),
                    )
                  else
                    Expanded(
                      child: equipos.isEmpty
                          ? const Center(child: Text('No hay equipos para los filtros seleccionados.'))
                          : compact
                              ? _listaCompacta(equipos)
                              : _tablaDesktop(equipos),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _EquipoDialog extends StatefulWidget {
  const _EquipoDialog({this.equipo});

  final Equipo? equipo;

  @override
  State<_EquipoDialog> createState() => _EquipoDialogState();
}

class _EquipoDialogState extends State<_EquipoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _descripcion;
  late final TextEditingController _marca;
  late final TextEditingController _categoria;
  late final TextEditingController _capacidad;

  @override
  void initState() {
    super.initState();
    final actual = widget.equipo;
    _codigo = TextEditingController(text: actual?.codigo ?? '');
    _descripcion = TextEditingController(text: actual?.descripcion ?? '');
    _marca = TextEditingController(text: actual?.marca ?? '');
    _categoria = TextEditingController(text: actual?.categoria ?? '');
    _capacidad = TextEditingController(text: actual?.capacidad ?? '');
  }

  @override
  void dispose() {
    _codigo.dispose();
    _descripcion.dispose();
    _marca.dispose();
    _categoria.dispose();
    _capacidad.dispose();
    super.dispose();
  }

  Widget _campo(
    TextEditingController controller,
    String label,
    double width, {
    bool requerido = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (requerido && (value == null || value.trim().isEmpty)) {
            return 'Campo obligatorio';
          }
          return null;
        },
      ),
    );
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final actual = widget.equipo;
    Navigator.of(context).pop(
      Equipo(
        id: actual?.id ?? '',
        codigo: _codigo.text.trim(),
        descripcion: _descripcion.text.trim(),
        marca: _marca.text.trim(),
        categoria: _categoria.text.trim(),
        capacidad: _capacidad.text.trim(),
        activo: actual?.activo ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.equipo != null;
    return AlertDialog(
      title: Text(editando ? 'Editar equipo' : 'Nuevo equipo'),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _campo(_codigo, 'Código *', 200, requerido: true),
                _campo(_descripcion, 'Descripción del activo *', 470, requerido: true),
                _campo(_marca, 'Marca', 220),
                _campo(_categoria, 'Categoría', 320),
                _campo(_capacidad, 'Capacidad', 220),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardar,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
        ),
      ],
    );
  }
}
