import 'package:flutter/material.dart';

import '../models/almacen.dart';
import '../models/proyecto.dart';
import '../state/app_state.dart';

class AlmacenesScreen extends StatefulWidget {
  const AlmacenesScreen({super.key});

  @override
  State<AlmacenesScreen> createState() => _AlmacenesScreenState();
}

class _AlmacenesScreenState extends State<AlmacenesScreen> {
  String _busqueda = '';
  bool _mostrarCerrados = true;
  String? _proyectoFiltro;
  String? _estadoFiltro;

  List<Almacen> get _filtrados {
    final texto = _busqueda.trim().toLowerCase();
    return appState.almacenes.where((a) {
      if (!_mostrarCerrados && !EstadoAlmacen.permiteOperaciones(a.estado)) {
        return false;
      }
      if (_proyectoFiltro != null && a.proyectoId != _proyectoFiltro) {
        return false;
      }
      if (_estadoFiltro != null && a.estado != _estadoFiltro) return false;
      return texto.isEmpty ||
          a.codigo.toLowerCase().contains(texto) ||
          a.nombre.toLowerCase().contains(texto) ||
          a.proyecto.toLowerCase().contains(texto) ||
          a.descripcion.toLowerCase().contains(texto) ||
          a.observacion.toLowerCase().contains(texto);
    }).toList();
  }

  Future<void> _formulario([Almacen? actual]) async {
    final almacen = await showDialog<Almacen>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AlmacenDialog(almacenActual: actual),
    );

    if (almacen == null || !mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      await appState.guardarAlmacenEnSupabase(almacen);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actual == null ? 'Almacén creado.' : 'Almacén actualizado.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.errorAlmacenes ?? 'No se pudo guardar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _format(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  Color _colorEstado(String estado, ColorScheme colors) {
    switch (estado) {
      case EstadoAlmacen.preparacion:
        return Colors.orange;
      case EstadoAlmacen.cerrado:
        return colors.error;
      case EstadoAlmacen.archivado:
        return Colors.grey;
      case EstadoAlmacen.operativo:
      default:
        return Colors.green;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case EstadoAlmacen.preparacion:
        return Icons.construction;
      case EstadoAlmacen.cerrado:
        return Icons.lock_outline;
      case EstadoAlmacen.archivado:
        return Icons.inventory_2_outlined;
      case EstadoAlmacen.operativo:
      default:
        return Icons.check_circle_outline;
    }
  }

  Future<void> _cambiarEstado(Almacen almacen, String nuevoEstado) async {
    if (almacen.estado == nuevoEstado) return;

    final cierre = nuevoEstado == EstadoAlmacen.cerrado ||
        nuevoEstado == EstadoAlmacen.archivado;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar estado del almacén'),
        content: Text(
          cierre
              ? '¿Querés pasar ${almacen.codigo} - ${almacen.nombre} a "${EstadoAlmacen.etiqueta(nuevoEstado)}"? '
                  'El sistema rechazará el cambio si todavía tiene stock disponible.'
              : '¿Querés pasar ${almacen.codigo} - ${almacen.nombre} a "${EstadoAlmacen.etiqueta(nuevoEstado)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      await appState.cambiarEstadoAlmacen(
        almacen: almacen,
        estado: nuevoEstado,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estado actualizado a ${EstadoAlmacen.etiqueta(nuevoEstado)}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorAlmacenes ?? 'No se pudo cambiar el estado.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _duplicar(Almacen almacen) async {
    final copia = Almacen(
      id: '',
      codigo: '${almacen.codigo}-COPIA',
      nombre: '${almacen.nombre} (copia)',
      descripcion: almacen.descripcion,
      proyectoId: almacen.proyectoId,
      proyecto: almacen.proyecto,
      fechaInicio: almacen.fechaInicio,
      fechaFinEstimada: almacen.fechaFinEstimada,
      activo: true,
      estado: EstadoAlmacen.preparacion,
      observacion: almacen.observacion,
    );
    await _formulario(copia);
  }

  Future<void> _mostrarResumen(Almacen almacen) async {
    await Future.wait([
      appState.cargarStockDesdeSupabase(),
      appState.cargarUbicacionesDesdeSupabase(),
      appState.cargarMovimientosDesdeSupabase(),
    ]);
    if (!mounted) return;

    final ubicaciones = appState.ubicaciones
        .where((u) => u.almacenId == almacen.id)
        .toList();
    final stock = appState.stock
        .where((s) => s.almacenId == almacen.id)
        .toList();
    final movimientos = appState.movimientos.where((m) =>
        m.almacenOrigenId == almacen.id || m.almacenDestinoId == almacen.id)
      .toList();
    movimientos.sort((a, b) => b.fecha.compareTo(a.fecha));
    final cantidad = stock.fold<num>(0, (total, item) => total + item.cantidad);
    final materiales = stock.map((e) => e.materialId).where((e) => e.isNotEmpty).toSet().length;
    final ultimo = movimientos.isEmpty ? null : movimientos.first.fecha;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${almacen.codigo} - ${almacen.nombre}'),
        content: SizedBox(
          width: 520,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ResumenDato(titulo: 'Proyecto', valor: almacen.proyecto.isEmpty ? 'Sin proyecto' : almacen.proyecto, icono: Icons.business_center_outlined),
              _ResumenDato(titulo: 'Estado', valor: EstadoAlmacen.etiqueta(almacen.estado), icono: _iconoEstado(almacen.estado)),
              _ResumenDato(titulo: 'Ubicaciones', valor: '${ubicaciones.length}', icono: Icons.location_on_outlined),
              _ResumenDato(titulo: 'Materiales con stock', valor: '$materiales', icono: Icons.category_outlined),
              _ResumenDato(titulo: 'Stock total', valor: cantidad.toStringAsFixed(cantidad % 1 == 0 ? 0 : 2), icono: Icons.inventory_2_outlined),
              _ResumenDato(titulo: 'Último movimiento', valor: ultimo == null ? 'Sin movimientos' : _format(ultimo), icono: Icons.history),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _mostrarStock(Almacen almacen) async {
    await appState.cargarStockDesdeSupabase();
    if (!mounted) return;
    final items = appState.stock.where((s) => s.almacenId == almacen.id).toList();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock · ${almacen.nombre}'),
        content: SizedBox(
          width: 720,
          height: 420,
          child: items.isEmpty
              ? const Center(child: Text('Este almacén no tiene stock disponible.'))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text('${item.material.codigo} · ${item.material.nombre}'),
                      subtitle: Text('Ubicación: ${item.ubicacion}'),
                      trailing: Text(item.cantidad.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _mostrarMovimientos(Almacen almacen) async {
    await appState.cargarMovimientosDesdeSupabase();
    if (!mounted) return;
    final items = appState.movimientos.where((m) =>
        m.almacenOrigenId == almacen.id || m.almacenDestinoId == almacen.id)
      .toList();
    items.sort((a, b) => b.fecha.compareTo(a.fecha));
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Últimos movimientos · ${almacen.nombre}'),
        content: SizedBox(
          width: 760,
          height: 440,
          child: items.isEmpty
              ? const Center(child: Text('No hay movimientos registrados para este almacén.'))
              : ListView.separated(
                  itemCount: items.take(100).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return ListTile(
                      leading: const Icon(Icons.swap_horiz),
                      title: Text('${item.tipo.toUpperCase()} · ${item.codigoMaterial}'),
                      subtitle: Text('${_format(item.fecha)} · ${item.nombreMaterial}'),
                      trailing: Text(item.cantidad.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _ejecutarAccion(String accion, Almacen almacen) async {
    switch (accion) {
      case 'editar':
        await _formulario(almacen);
        return;
      case 'resumen':
        await _mostrarResumen(almacen);
        return;
      case 'stock':
        await _mostrarStock(almacen);
        return;
      case 'movimientos':
        await _mostrarMovimientos(almacen);
        return;
      case 'duplicar':
        await _duplicar(almacen);
        return;
      default:
        if (accion.startsWith('estado:')) {
          await _cambiarEstado(almacen, accion.substring(7));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final almacenes = _filtrados;
        final colors = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Gestión de Almacenes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _formulario(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo almacén'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Editá sus datos, proyecto asociado y ciclo de vida sin perder el historial.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 340,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar almacén o proyecto',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _busqueda = value),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String?>(
                      value: _proyectoFiltro,
                      decoration: const InputDecoration(
                        labelText: 'Proyecto',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...appState.proyectos.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(
                              p.etiqueta,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _proyectoFiltro = value),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String?>(
                      value: _estadoFiltro,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...EstadoAlmacen.valores.map(
                          (estado) => DropdownMenuItem<String?>(
                            value: estado,
                            child: Text(EstadoAlmacen.etiqueta(estado)),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _estadoFiltro = value),
                    ),
                  ),
                  FilterChip(
                    selected: _mostrarCerrados,
                    label: const Text('Mostrar cerrados y archivados'),
                    onSelected: (value) =>
                        setState(() => _mostrarCerrados = value),
                  ),
                  IconButton(
                    onPressed: appState.cargarAlmacenesDesdeSupabase,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (appState.cargandoAlmacenes)
                const LinearProgressIndicator()
              else if (appState.errorAlmacenes != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(appState.errorAlmacenes!),
                  ),
                )
              else if (almacenes.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No hay almacenes que coincidan con los filtros.'),
                  ),
                )
              else
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Almacén')),
                            DataColumn(label: Text('Acciones')),
                            DataColumn(label: Text('Proyecto')),
                            DataColumn(label: Text('Inicio')),
                            DataColumn(label: Text('Fin estimada')),
                            DataColumn(label: Text('Estado')),
                          ],
                          rows: almacenes.map((a) {
                            final color = _colorEstado(a.estado, colors);
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    a.codigo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(Text(a.nombre)),
                                DataCell(
                                  PopupMenuButton<String>(
                                    tooltip: 'Acciones del almacén',
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (accion) => _ejecutarAccion(accion, a),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'editar', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'), dense: true)),
                                      const PopupMenuItem(value: 'resumen', child: ListTile(leading: Icon(Icons.analytics_outlined), title: Text('Ver resumen'), dense: true)),
                                      const PopupMenuItem(value: 'stock', child: ListTile(leading: Icon(Icons.inventory_2_outlined), title: Text('Ver stock'), dense: true)),
                                      const PopupMenuItem(value: 'movimientos', child: ListTile(leading: Icon(Icons.history), title: Text('Ver movimientos'), dense: true)),
                                      const PopupMenuItem(value: 'duplicar', child: ListTile(leading: Icon(Icons.copy_outlined), title: Text('Duplicar'), dense: true)),
                                      const PopupMenuDivider(),
                                      ...EstadoAlmacen.valores.where((e) => e != a.estado).map((estado) => PopupMenuItem(
                                        value: 'estado:$estado',
                                        child: ListTile(leading: Icon(_iconoEstado(estado)), title: Text('Pasar a ${EstadoAlmacen.etiqueta(estado)}'), dense: true),
                                      )),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    a.proyecto.isEmpty
                                        ? 'Sin proyecto'
                                        : a.proyecto,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    a.fechaInicio == null
                                        ? '-'
                                        : _format(a.fechaInicio!),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    a.fechaFinEstimada == null
                                        ? '-'
                                        : _format(a.fechaFinEstimada!),
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    avatar: Icon(
                                      _iconoEstado(a.estado),
                                      size: 18,
                                      color: color,
                                    ),
                                    label: Text(
                                      EstadoAlmacen.etiqueta(a.estado),
                                    ),
                                  ),
                                ),

                              ],
                            );
                          }).toList(),
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
}


class _ResumenDato extends StatelessWidget {
  const _ResumenDato({required this.titulo, required this.valor, required this.icono});
  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icono),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 3),
                    Text(valor, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlmacenDialog extends StatefulWidget {
  const _AlmacenDialog({this.almacenActual});

  final Almacen? almacenActual;

  @override
  State<_AlmacenDialog> createState() => _AlmacenDialogState();
}

class _AlmacenDialogState extends State<_AlmacenDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _observacion;

  Proyecto? _proyecto;
  DateTime? _inicio;
  DateTime? _fin;
  String _estadoNuevo = EstadoAlmacen.preparacion;

  @override
  void initState() {
    super.initState();
    final actual = widget.almacenActual;
    _codigo = TextEditingController(text: actual?.codigo ?? '');
    _nombre = TextEditingController(text: actual?.nombre ?? '');
    _descripcion = TextEditingController(text: actual?.descripcion ?? '');
    _observacion = TextEditingController(text: actual?.observacion ?? '');
    _inicio = actual?.fechaInicio;
    _fin = actual?.fechaFinEstimada;
    _estadoNuevo = actual?.estado ?? EstadoAlmacen.preparacion;

    if (actual != null && actual.proyectoId.isNotEmpty) {
      for (final item in appState.proyectos) {
        if (item.id == actual.proyectoId) {
          _proyecto = item;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _descripcion.dispose();
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio
          ? (_inicio ?? DateTime.now())
          : (_fin ?? _inicio ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha == null || !mounted) return;
    setState(() {
      if (esInicio) {
        _inicio = fecha;
      } else {
        _fin = fecha;
      }
    });
  }

  String _format(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  Widget _campo(
    TextEditingController controller,
    String label,
    double width, {
    bool requerido = false,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: requerido
            ? (value) => value == null || value.trim().isEmpty
                ? 'Campo obligatorio'
                : null
            : null,
      ),
    );
  }

  Widget _fecha(
    String label,
    DateTime? fecha,
    VoidCallback elegir,
    VoidCallback limpiar,
  ) {
    return SizedBox(
      width: 315,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(fecha == null ? 'Sin definir' : _format(fecha)),
            ),
            IconButton(
              onPressed: elegir,
              icon: const Icon(Icons.calendar_month),
            ),
            if (fecha != null)
              IconButton(
                onPressed: limpiar,
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_inicio != null && _fin != null && _fin!.isBefore(_inicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha fin no puede ser anterior al inicio.'),
        ),
      );
      return;
    }

    final actual = widget.almacenActual;
    final estado = actual?.estado ?? _estadoNuevo;
    Navigator.of(context).pop(
      Almacen(
        id: actual?.id ?? '',
        codigo: _codigo.text.trim(),
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        proyectoId: _proyecto?.id ?? '',
        proyecto: _proyecto?.etiqueta ?? '',
        fechaInicio: _inicio,
        fechaFinEstimada: _fin,
        fechaCierre: actual?.fechaCierre,
        activo: EstadoAlmacen.permiteOperaciones(estado),
        estado: estado,
        observacion: _observacion.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proyectosDisponibles = <Proyecto>[...appState.proyectosActivos];
    if (_proyecto != null &&
        !proyectosDisponibles.any((p) => p.id == _proyecto!.id)) {
      proyectosDisponibles.add(_proyecto!);
    }

    return AlertDialog(
      title: Text(
        widget.almacenActual == null ? 'Nuevo almacén' : 'Editar almacén',
      ),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _campo(_codigo, 'Código *', 210, requerido: true),
                _campo(_nombre, 'Nombre *', 420, requerido: true),
                SizedBox(
                  width: 650,
                  child: DropdownButtonFormField<Proyecto>(
                    initialValue: _proyecto,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Proyecto',
                      border: OutlineInputBorder(),
                      helperText:
                          'Opcional. El vínculo puede modificarse sin perder el historial.',
                    ),
                    items: proyectosDisponibles
                        .map(
                          (p) => DropdownMenuItem<Proyecto>(
                            value: p,
                            child: Text(
                              p.etiqueta,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _proyecto = value),
                  ),
                ),
                if (widget.almacenActual == null)
                  SizedBox(
                    width: 650,
                    child: DropdownButtonFormField<String>(
                      initialValue: _estadoNuevo,
                      decoration: const InputDecoration(
                        labelText: 'Estado inicial',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: EstadoAlmacen.preparacion,
                          child: Text('En preparación'),
                        ),
                        DropdownMenuItem(
                          value: EstadoAlmacen.operativo,
                          child: Text('Operativo'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _estadoNuevo = value);
                        }
                      },
                    ),
                  ),
                if (widget.almacenActual != null)
                  SizedBox(
                    width: 650,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Estado actual',
                        border: OutlineInputBorder(),
                        helperText:
                            'El estado se cambia desde el menú de acciones de la tabla.',
                      ),
                      child: Text(
                        EstadoAlmacen.etiqueta(widget.almacenActual!.estado),
                      ),
                    ),
                  ),
                _campo(_descripcion, 'Descripción', 650, maxLines: 2),
                _fecha(
                  'Fecha de inicio',
                  _inicio,
                  () => _elegirFecha(true),
                  () => setState(() => _inicio = null),
                ),
                _fecha(
                  'Fin estimada',
                  _fin,
                  () => _elegirFecha(false),
                  () => setState(() => _fin = null),
                ),
                _campo(_observacion, 'Observaciones', 650, maxLines: 2),
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
