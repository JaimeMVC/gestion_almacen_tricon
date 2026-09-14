import 'package:flutter/material.dart';

import '../models/proyecto.dart';
import '../state/app_state.dart';

class ProyectosScreen extends StatefulWidget {
  const ProyectosScreen({super.key});

  @override
  State<ProyectosScreen> createState() => _ProyectosScreenState();
}

class _ProyectosScreenState extends State<ProyectosScreen> {
  String _busqueda = '';
  bool _mostrarInactivos = false;

  List<Proyecto> get _filtrados {
    final texto = _busqueda.trim().toLowerCase();
    return appState.proyectos.where((p) {
      if (!_mostrarInactivos && !p.activo) return false;
      return texto.isEmpty ||
          p.codigo.toLowerCase().contains(texto) ||
          p.nombre.toLowerCase().contains(texto) ||
          p.cliente.toLowerCase().contains(texto) ||
          p.responsable.toLowerCase().contains(texto);
    }).toList();
  }

  Future<void> _formulario([Proyecto? actual]) async {
    // El diálogo administra sus propios controllers y los libera en dispose().
    // El guardado global ocurre recién cuando la ruta ya se cerró.
    final proyecto = await showDialog<Proyecto>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProyectoDialog(proyectoActual: actual),
    );

    if (proyecto == null || !mounted) return;

    try {
      await appState.guardarProyectoEnSupabase(proyecto);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actual == null ? 'Proyecto creado.' : 'Proyecto actualizado.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.errorProyectos ?? 'No se pudo guardar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _format(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  Future<void> _cambiarEstado(Proyecto proyecto) async {
    final activo = !proyecto.activo;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activo ? 'Reactivar proyecto' : 'Cerrar proyecto'),
        content: Text(
          activo
              ? '¿Confirmás la reactivación de ${proyecto.etiqueta}?'
              : '¿Confirmás el cierre de ${proyecto.etiqueta}? El historial y los almacenes asociados no se eliminarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(activo ? 'Reactivar' : 'Cerrar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await appState.cambiarEstadoProyecto(proyecto: proyecto, activo: activo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorProyectos ?? 'No se pudo cambiar el estado.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final proyectos = _filtrados;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Maestro de Proyectos',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _formulario(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo proyecto'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Cada almacén puede vincularse a un proyecto para conservar trazabilidad, consumos y costos.',
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 440,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText:
                            'Buscar por código, nombre, cliente o responsable',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _busqueda = value),
                    ),
                  ),
                  FilterChip(
                    selected: _mostrarInactivos,
                    label: const Text('Mostrar cerrados'),
                    onSelected: (value) =>
                        setState(() => _mostrarInactivos = value),
                  ),
                  IconButton(
                    onPressed: appState.cargarProyectosDesdeSupabase,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (appState.cargandoProyectos)
                const LinearProgressIndicator()
              else if (appState.errorProyectos != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(appState.errorProyectos!),
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
                            DataColumn(label: Text('Proyecto')),
                            DataColumn(label: Text('Cliente')),
                            DataColumn(label: Text('Responsable')),
                            DataColumn(label: Text('Inicio')),
                            DataColumn(label: Text('Fin estimada')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: proyectos
                              .map(
                                (p) => DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        p.codigo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(p.nombre)),
                                    DataCell(
                                      Text(p.cliente.isEmpty ? '-' : p.cliente),
                                    ),
                                    DataCell(
                                      Text(
                                        p.responsable.isEmpty
                                            ? '-'
                                            : p.responsable,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        p.fechaInicio == null
                                            ? '-'
                                            : _format(p.fechaInicio!),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        p.fechaFinEstimada == null
                                            ? '-'
                                            : _format(p.fechaFinEstimada!),
                                      ),
                                    ),
                                    DataCell(
                                      Chip(
                                        label: Text(
                                          p.activo ? 'ACTIVO' : 'CERRADO',
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () => _formulario(p),
                                            icon: const Icon(Icons.edit),
                                            tooltip: 'Editar',
                                          ),
                                          IconButton(
                                            onPressed: () => _cambiarEstado(p),
                                            icon: Icon(
                                              p.activo
                                                  ? Icons.archive_outlined
                                                  : Icons.restore,
                                            ),
                                            tooltip:
                                                p.activo ? 'Cerrar' : 'Reactivar',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
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

class _ProyectoDialog extends StatefulWidget {
  const _ProyectoDialog({this.proyectoActual});

  final Proyecto? proyectoActual;

  @override
  State<_ProyectoDialog> createState() => _ProyectoDialogState();
}

class _ProyectoDialogState extends State<_ProyectoDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codigo;
  late final TextEditingController _nombre;
  late final TextEditingController _cliente;
  late final TextEditingController _responsable;
  late final TextEditingController _descripcion;
  late final TextEditingController _observacion;

  DateTime? _inicio;
  DateTime? _fin;

  @override
  void initState() {
    super.initState();
    final actual = widget.proyectoActual;
    _codigo = TextEditingController(text: actual?.codigo ?? '');
    _nombre = TextEditingController(text: actual?.nombre ?? '');
    _cliente = TextEditingController(text: actual?.cliente ?? '');
    _responsable = TextEditingController(text: actual?.responsable ?? '');
    _descripcion = TextEditingController(text: actual?.descripcion ?? '');
    _observacion = TextEditingController(text: actual?.observacion ?? '');
    _inicio = actual?.fechaInicio;
    _fin = actual?.fechaFinEstimada;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _nombre.dispose();
    _cliente.dispose();
    _responsable.dispose();
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
    setState(() => esInicio ? _inicio = fecha : _fin = fecha);
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

    final actual = widget.proyectoActual;
    Navigator.of(context).pop(
      Proyecto(
        id: actual?.id ?? '',
        codigo: _codigo.text.trim(),
        nombre: _nombre.text.trim(),
        cliente: _cliente.text.trim(),
        responsable: _responsable.text.trim(),
        descripcion: _descripcion.text.trim(),
        fechaInicio: _inicio,
        fechaFinEstimada: _fin,
        fechaCierre: actual?.fechaCierre,
        activo: actual?.activo ?? true,
        observacion: _observacion.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actual = widget.proyectoActual;
    return AlertDialog(
      title: Text(actual == null ? 'Nuevo proyecto' : 'Editar proyecto'),
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
                _campo(_cliente, 'Cliente', 315),
                _campo(_responsable, 'Responsable', 315),
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
                _campo(_descripcion, 'Descripción', 650, maxLines: 2),
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
