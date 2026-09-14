import 'package:flutter/material.dart';

import '../models/proveedor.dart';
import '../models/region_compra.dart';
import '../state/app_state.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  String _busqueda = '';
  bool _mostrarInactivos = false;
  String? _regionFiltro;

  List<Proveedor> get _filtrados {
    final texto = _busqueda.trim().toLowerCase();
    return appState.proveedores.where((p) {
      if (!_mostrarInactivos && !p.activo) return false;
      if (_regionFiltro != null && p.regionId != _regionFiltro) return false;
      return texto.isEmpty ||
          p.codigo.toLowerCase().contains(texto) ||
          p.razonSocial.toLowerCase().contains(texto) ||
          p.nombreComercial.toLowerCase().contains(texto) ||
          p.cuit.toLowerCase().contains(texto) ||
          p.pais.toLowerCase().contains(texto);
    }).toList();
  }

  Future<void> _formulario([Proveedor? actual]) async {
    final codigo = TextEditingController(text: actual?.codigo ?? '');
    final razon = TextEditingController(text: actual?.razonSocial ?? '');
    final comercial = TextEditingController(text: actual?.nombreComercial ?? '');
    final cuit = TextEditingController(text: actual?.cuit ?? '');
    final pais = TextEditingController(text: actual?.pais ?? '');
    final contacto = TextEditingController(text: actual?.contacto ?? '');
    final email = TextEditingController(text: actual?.email ?? '');
    final telefono = TextEditingController(text: actual?.telefono ?? '');
    final observacion = TextEditingController(text: actual?.observacion ?? '');

    RegionCompra? region;
    if (actual != null && actual.regionId.isNotEmpty) {
      for (final item in appState.regiones) {
        if (item.id == actual.regionId) {
          region = item;
          break;
        }
      }
    }

    final formKey = GlobalKey<FormState>();

    // El diálogo solo captura los datos y se cierra.
    // El guardado en Supabase se realiza después, evitando reconstrucciones
    // globales mientras la ruta del diálogo todavía está montada.
    final proveedorParaGuardar = await showDialog<Proveedor>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(actual == null ? 'Nuevo proveedor' : 'Editar proveedor'),
          content: SizedBox(
            width: 650,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _campo(codigo, 'Código *', 200, requerido: true),
                    _campo(cuit, 'CUIT / Identificación fiscal', 260),
                    _campo(razon, 'Razón social *', 420, requerido: true),
                    _campo(comercial, 'Nombre comercial', 420),
                    SizedBox(
                      width: 310,
                      child: DropdownButtonFormField<RegionCompra>(
                        initialValue: region,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Región',
                          border: OutlineInputBorder(),
                        ),
                        items: appState.regionesActivas
                            .map(
                              (r) => DropdownMenuItem<RegionCompra>(
                                value: r,
                                child: Text(
                                  r.etiqueta,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            region = value;
                            if (value != null && pais.text.trim().isEmpty) {
                              pais.text = value.pais;
                            }
                          });
                        },
                      ),
                    ),
                    _campo(pais, 'País', 260),
                    _campo(contacto, 'Contacto', 310),
                    _campo(email, 'Email', 310, email: true),
                    _campo(telefono, 'Teléfono', 260),
                    _campo(observacion, 'Observaciones', 600, maxLines: 2),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;

                Navigator.of(dialogContext).pop(
                  Proveedor(
                    id: actual?.id ?? '',
                    codigo: codigo.text.trim(),
                    razonSocial: razon.text.trim(),
                    nombreComercial: comercial.text.trim(),
                    cuit: cuit.text.trim(),
                    regionId: region?.id ?? '',
                    regionNombre: region?.nombre ?? '',
                    pais: pais.text.trim(),
                    contacto: contacto.text.trim(),
                    email: email.text.trim(),
                    telefono: telefono.text.trim(),
                    observacion: observacion.text.trim(),
                    activo: actual?.activo ?? true,
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    codigo.dispose();
    razon.dispose();
    comercial.dispose();
    cuit.dispose();
    pais.dispose();
    contacto.dispose();
    email.dispose();
    telefono.dispose();
    observacion.dispose();

    if (proveedorParaGuardar == null || !mounted) return;

    try {
      await appState.guardarProveedorEnSupabase(proveedorParaGuardar);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actual == null
                ? 'Proveedor creado correctamente.'
                : 'Proveedor actualizado correctamente.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorProveedores ?? 'No se pudo guardar el proveedor.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _campo(TextEditingController c, String label, double width,
      {bool requerido = false, bool email = false, int maxLines = 1}) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          if (requerido && (value == null || value.trim().isEmpty)) {
            return 'Campo obligatorio';
          }
          if (email && value != null && value.trim().isNotEmpty && !value.contains('@')) {
            return 'Email inválido';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _cambiarEstado(Proveedor p) async {
    await appState.cambiarEstadoProveedor(proveedor: p, activo: !p.activo);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final proveedores = _filtrados;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Text('Maestro de Proveedores',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                FilledButton.icon(
                  onPressed: () => _formulario(),
                  icon: const Icon(Icons.add_business),
                  label: const Text('Nuevo proveedor'),
                ),
              ]),
              const SizedBox(height: 18),
              Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(width: 420, child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar por código, nombre, CUIT o país',
                      prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => _busqueda = v),
                  )),
                  SizedBox(width: 280, child: DropdownButtonFormField<String?>(
                    value: _regionFiltro,
                    decoration: const InputDecoration(labelText: 'Región', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                      ...appState.regiones.map((r) => DropdownMenuItem<String?>(value: r.id, child: Text(r.etiqueta))).toList(),
                    ],
                    onChanged: (v) => setState(() => _regionFiltro = v),
                  )),
                  FilterChip(
                    selected: _mostrarInactivos,
                    label: const Text('Mostrar inactivos'),
                    onSelected: (v) => setState(() => _mostrarInactivos = v),
                  ),
                  IconButton(onPressed: appState.cargarProveedoresDesdeSupabase, icon: const Icon(Icons.refresh), tooltip: 'Actualizar'),
                ],
              ),
              const SizedBox(height: 18),
              if (appState.cargandoProveedores) const LinearProgressIndicator(),
              if (appState.errorProveedores != null)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(appState.errorProveedores!, style: const TextStyle(color: Colors.red))),
              Expanded(
                child: proveedores.isEmpty
                    ? const Center(child: Text('No se encontraron proveedores.'))
                    : ListView.separated(
                        itemCount: proveedores.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = proveedores[i];
                          return Card(child: ListTile(
                            leading: CircleAvatar(child: Icon(p.activo ? Icons.business : Icons.business_outlined)),
                            title: Text(p.etiqueta, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text([
                              if (p.cuit.isNotEmpty) 'CUIT: ${p.cuit}',
                              if (p.regionNombre.isNotEmpty) p.regionNombre,
                              if (p.pais.isNotEmpty) p.pais,
                              if (p.contacto.isNotEmpty) 'Contacto: ${p.contacto}',
                            ].join(' · ')),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Chip(label: Text(p.activo ? 'Activo' : 'Inactivo')),
                              IconButton(onPressed: () => _formulario(p), icon: const Icon(Icons.edit)),
                              IconButton(
                                onPressed: () => _cambiarEstado(p),
                                icon: Icon(p.activo ? Icons.block : Icons.check_circle),
                                tooltip: p.activo ? 'Inhabilitar' : 'Reactivar',
                              ),
                            ]),
                          ));
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
