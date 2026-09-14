import 'package:flutter/material.dart';
import '../models/region_compra.dart';
import '../state/app_state.dart';

class RegionesScreen extends StatefulWidget {
  const RegionesScreen({super.key});
  @override
  State<RegionesScreen> createState() => _RegionesScreenState();
}

class _RegionesScreenState extends State<RegionesScreen> {
  String _busqueda = '';
  bool _mostrarInactivas = false;

  Future<void> _formulario([RegionCompra? actual]) async {
    final nombre = TextEditingController(text: actual?.nombre ?? '');
    final pais = TextEditingController(text: actual?.pais ?? '');
    final key = GlobalKey<FormState>();
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(actual == null ? 'Nueva región' : 'Editar región'),
      content: SizedBox(width: 480, child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nombre, decoration: const InputDecoration(labelText: 'Región *', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null),
        const SizedBox(height: 12),
        TextFormField(controller: pais, decoration: const InputDecoration(labelText: 'País', border: OutlineInputBorder())),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
        FilledButton.icon(onPressed: () async {
          if (!key.currentState!.validate()) return;
          try {
            await appState.guardarRegionEnSupabase(RegionCompra(
              id: actual?.id ?? '', nombre: nombre.text.trim(), pais: pais.text.trim(), activa: actual?.activa ?? true));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          } catch (_) {
            if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(appState.errorRegiones ?? 'Error')));
          }
        }, icon: const Icon(Icons.save), label: const Text('Guardar')),
      ],
    ));
    nombre.dispose(); pais.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: appState, builder: (context, _) {
      final texto = _busqueda.toLowerCase();
      final regiones = appState.regiones.where((r) =>
        (_mostrarInactivas || r.activa) &&
        (texto.isEmpty || r.nombre.toLowerCase().contains(texto) || r.pais.toLowerCase().contains(texto))).toList();
      return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        Row(children: [
          const Expanded(child: Text('Maestro de Regiones', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
          FilledButton.icon(onPressed: () => _formulario(), icon: const Icon(Icons.add_location_alt), label: const Text('Nueva región')),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Buscar región o país', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => _busqueda = v))),
          const SizedBox(width: 12),
          FilterChip(selected: _mostrarInactivas, label: const Text('Mostrar inactivas'), onSelected: (v) => setState(() => _mostrarInactivas = v)),
          IconButton(onPressed: appState.cargarRegionesDesdeSupabase, icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 18),
        if (appState.cargandoRegiones) const LinearProgressIndicator(),
        Expanded(child: regiones.isEmpty ? const Center(child: Text('No se encontraron regiones.')) : ListView.separated(
          itemCount: regiones.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) {
            final r=regiones[i];
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.public)),
              title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(r.pais.isEmpty ? 'Sin país informado' : r.pais),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Chip(label: Text(r.activa ? 'Activa' : 'Inactiva')),
                IconButton(onPressed: () => _formulario(r), icon: const Icon(Icons.edit)),
                IconButton(onPressed: () async { await appState.cambiarEstadoRegion(region: r, activa: !r.activa); if (mounted) setState(() {}); }, icon: Icon(r.activa ? Icons.block : Icons.check_circle)),
              ]),
            ));
          },
        )),
      ]));
    });
  }
}
