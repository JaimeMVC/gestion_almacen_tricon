import 'package:flutter/material.dart';

import '../models/almacen.dart';
import '../models/ubicacion.dart';
import '../state/app_state.dart';

class UbicacionesScreen extends StatefulWidget {
  const UbicacionesScreen({super.key});

  @override
  State<UbicacionesScreen> createState() => _UbicacionesScreenState();
}

class _UbicacionesScreenState extends State<UbicacionesScreen> {
  String _busqueda = '';
  String? _almacenFiltroId;
  bool _mostrarInactivas = false;

  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _observacionController = TextEditingController();

  @override
  void dispose() {
    _codigoController.dispose();
    _descripcionController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  List<Ubicacion> _filtrarUbicaciones() {
    final texto = _busqueda.trim().toLowerCase();

    final lista = appState.ubicaciones.where((ubicacion) {
      if (!_mostrarInactivas && !ubicacion.activa) return false;
      if (_almacenFiltroId != null &&
          ubicacion.almacenId != _almacenFiltroId) {
        return false;
      }

      if (texto.isEmpty) return true;

      return ubicacion.codigo.toLowerCase().contains(texto) ||
          ubicacion.descripcion.toLowerCase().contains(texto) ||
          ubicacion.almacenCodigo.toLowerCase().contains(texto) ||
          ubicacion.almacenNombre.toLowerCase().contains(texto);
    }).toList();

    lista.sort((a, b) {
      final almacen = a.almacenNombre.compareTo(b.almacenNombre);
      if (almacen != 0) return almacen;
      return a.codigo.compareTo(b.codigo);
    });

    return lista;
  }

  Future<void> _abrirFormulario({Ubicacion? ubicacion}) async {
    final almacenesActivos = appState.almacenesActivos;

    if (almacenesActivos.isEmpty) {
      _mostrarMensaje(
        'Primero debés crear y activar al menos un almacén.',
        esError: true,
      );
      return;
    }

    _codigoController.text = ubicacion?.codigo ?? '';
    _descripcionController.text = ubicacion?.descripcion ?? '';
    _observacionController.text = ubicacion?.observacion ?? '';

    String? almacenSeleccionadoId = ubicacion?.almacenId;
    final almacenActualSigueActivo = almacenesActivos.any(
      (almacen) => almacen.id == almacenSeleccionadoId,
    );

    if (!almacenActualSigueActivo) {
      almacenSeleccionadoId = almacenesActivos.first.id;
    }

    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                ubicacion == null ? 'Nueva ubicación' : 'Editar ubicación',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: almacenSeleccionadoId,
                        decoration: const InputDecoration(
                          labelText: 'Almacén',
                          prefixIcon: Icon(Icons.warehouse),
                          border: OutlineInputBorder(),
                        ),
                        items: almacenesActivos
                            .map(
                              (almacen) => DropdownMenuItem(
                                value: almacen.id,
                                child: Text(
                                  '${almacen.codigo} · ${almacen.nombre}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: guardando
                            ? null
                            : (value) {
                                setDialogState(() {
                                  almacenSeleccionadoId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 14),
                      _campo(
                        _codigoController,
                        'Código de ubicación',
                        Icons.location_on,
                        habilitado: !guardando,
                      ),
                      const SizedBox(height: 14),
                      _campo(
                        _descripcionController,
                        'Descripción',
                        Icons.description,
                        habilitado: !guardando,
                      ),
                      const SizedBox(height: 14),
                      _campo(
                        _observacionController,
                        'Observación',
                        Icons.notes,
                        habilitado: !guardando,
                        lineas: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: guardando
                      ? null
                      : () async {
                          final codigo = _codigoController.text.trim();
                          if (almacenSeleccionadoId == null || codigo.isEmpty) {
                            _mostrarMensaje(
                              'El almacén y el código son obligatorios.',
                              esError: true,
                            );
                            return;
                          }

                          final duplicada = appState.ubicaciones.any((item) {
                            return item.id != (ubicacion?.id ?? '') &&
                                item.almacenId == almacenSeleccionadoId &&
                                item.codigo.toLowerCase() ==
                                    codigo.toLowerCase();
                          });

                          if (duplicada) {
                            _mostrarMensaje(
                              'Ya existe una ubicación con ese código en el almacén seleccionado.',
                              esError: true,
                            );
                            return;
                          }

                          final almacen = almacenesActivos.firstWhere(
                            (item) => item.id == almacenSeleccionadoId,
                          );

                          setDialogState(() => guardando = true);
                          try {
                            await appState.guardarUbicacionEnSupabase(
                              Ubicacion(
                                id: ubicacion?.id ?? '',
                                almacenId: almacen.id,
                                almacenCodigo: almacen.codigo,
                                almacenNombre: almacen.nombre,
                                codigo: codigo,
                                descripcion:
                                    _descripcionController.text.trim(),
                                observacion:
                                    _observacionController.text.trim(),
                                activa: ubicacion?.activa ?? true,
                              ),
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (_) {
                            if (dialogContext.mounted) {
                              setDialogState(() => guardando = false);
                            }
                          }
                        },
                  icon: guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(guardando ? 'Guardando...' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (guardado == true && mounted) {
      _mostrarMensaje('Ubicación guardada correctamente.');
    }
  }

  Future<void> _cambiarEstado(Ubicacion ubicacion) async {
    final nuevaActiva = !ubicacion.activa;
    final accion = nuevaActiva ? 'reactivar' : 'inhabilitar';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${nuevaActiva ? 'Reactivar' : 'Inhabilitar'} ubicación'),
        content: Text(
          '¿Querés $accion la ubicación ${ubicacion.codigo} de '
          '${ubicacion.almacenNombre}? El historial no se eliminará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(nuevaActiva ? 'Reactivar' : 'Inhabilitar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await appState.cambiarEstadoUbicacion(
        ubicacion: ubicacion,
        activa: nuevaActiva,
      );
      if (mounted) {
        _mostrarMensaje(
          nuevaActiva ? 'Ubicación reactivada.' : 'Ubicación inhabilitada.',
        );
      }
    } catch (_) {
      if (mounted) {
        _mostrarMensaje(
          appState.errorUbicaciones ?? 'No se pudo cambiar el estado.',
          esError: true,
        );
      }
    }
  }

  Widget _campo(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool habilitado = true,
    int lineas = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: habilitado,
      maxLines: lineas,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final ubicaciones = _filtrarUbicaciones();
        final almacenes = appState.almacenes;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicaciones',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('Ubicaciones físicas organizadas por almacén.'),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: appState.cargandoUbicaciones
                        ? null
                        : appState.cargarUbicacionesDesdeSupabase,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: appState.almacenesActivos.isEmpty
                        ? null
                        : () => _abrirFormulario(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva ubicación'),
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
                    width: 360,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar ubicación o almacén',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _busqueda = value),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: DropdownButtonFormField<String?>(
                      value: _almacenFiltroId,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por almacén',
                        prefixIcon: Icon(Icons.warehouse),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los almacenes'),
                        ),
                        ...almacenes.map(
                          (almacen) => DropdownMenuItem<String?>(
                            value: almacen.id,
                            child: Text(
                              '${almacen.codigo} · ${almacen.nombre}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _almacenFiltroId = value);
                      },
                    ),
                  ),
                  FilterChip(
                    selected: _mostrarInactivas,
                    label: const Text('Mostrar inactivas'),
                    avatar: const Icon(Icons.visibility, size: 18),
                    onSelected: (value) {
                      setState(() => _mostrarInactivas = value);
                    },
                  ),
                ],
              ),
              if (appState.errorUbicaciones != null) ...[
                const SizedBox(height: 12),
                MaterialBanner(
                  content: Text(appState.errorUbicaciones!),
                  leading: const Icon(Icons.error_outline),
                  actions: [
                    TextButton(
                      onPressed: appState.cargarUbicacionesDesdeSupabase,
                      child: const Text('REINTENTAR'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Expanded(
                child: appState.cargandoUbicaciones
                    ? const Center(child: CircularProgressIndicator())
                    : ubicaciones.isEmpty
                        ? _EstadoVacio(
                            hayAlmacenes:
                                appState.almacenesActivos.isNotEmpty,
                            onCrear: () => _abrirFormulario(),
                          )
                        : Card(
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Almacén')),
                                    DataColumn(label: Text('Código')),
                                    DataColumn(label: Text('Descripción')),
                                    DataColumn(label: Text('Estado')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: ubicaciones.map((ubicacion) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            '${ubicacion.almacenCodigo}\n${ubicacion.almacenNombre}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            ubicacion.codigo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            ubicacion.descripcion.isEmpty
                                                ? 'Sin descripción'
                                                : ubicacion.descripcion,
                                          ),
                                        ),
                                        DataCell(
                                          Chip(
                                            label: Text(
                                              ubicacion.activa
                                                  ? 'Activa'
                                                  : 'Inactiva',
                                            ),
                                            avatar: Icon(
                                              ubicacion.activa
                                                  ? Icons.check_circle
                                                  : Icons.pause_circle,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Editar',
                                                onPressed: ubicacion.activa
                                                    ? () => _abrirFormulario(
                                                          ubicacion: ubicacion,
                                                        )
                                                    : null,
                                                icon: const Icon(Icons.edit),
                                              ),
                                              IconButton(
                                                tooltip: ubicacion.activa
                                                    ? 'Inhabilitar'
                                                    : 'Reactivar',
                                                onPressed: () =>
                                                    _cambiarEstado(ubicacion),
                                                icon: Icon(
                                                  ubicacion.activa
                                                      ? Icons.block
                                                      : Icons.restart_alt,
                                                ),
                                              ),
                                            ],
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

class _EstadoVacio extends StatelessWidget {
  final bool hayAlmacenes;
  final VoidCallback onCrear;

  const _EstadoVacio({required this.hayAlmacenes, required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hayAlmacenes ? Icons.location_off : Icons.warehouse_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            hayAlmacenes
                ? 'No se encontraron ubicaciones.'
                : 'Primero debés crear un almacén activo.',
          ),
          if (hayAlmacenes) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add),
              label: const Text('Crear ubicación'),
            ),
          ],
        ],
      ),
    );
  }
}
