import 'package:flutter/material.dart';
import '../models/material_item.dart';
import '../state/app_state.dart';

class MaterialesScreen extends StatefulWidget {
  const MaterialesScreen({super.key});

  @override
  State<MaterialesScreen> createState() => _MaterialesScreenState();
}

class _MaterialesScreenState extends State<MaterialesScreen> {
  String busqueda = '';
  final codigoController = TextEditingController();
  final nombreController = TextEditingController();
  final familiaController = TextEditingController();
  final observacionController = TextEditingController();

  @override
  void dispose() {
    codigoController.dispose();
    nombreController.dispose();
    familiaController.dispose();
    observacionController.dispose();
    super.dispose();
  }

  List<MaterialItem> get materialesFiltrados {
    final texto = busqueda.toLowerCase();
    return appState.materiales.where((m) {
      return m.codigo.toLowerCase().contains(texto) ||
          m.nombre.toLowerCase().contains(texto) ||
          m.familia.toLowerCase().contains(texto);
    }).toList();
  }

  void _abrirFormulario({MaterialItem? material}) {
    if (material != null) {
      codigoController.text = material.codigo;
      nombreController.text = material.nombre;
      familiaController.text = material.familia;
      observacionController.text = material.observacion;
    } else {
      codigoController.clear();
      nombreController.clear();
      familiaController.clear();
      observacionController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(material == null ? 'Nuevo material' : 'Editar material'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(codigoController, 'Código de pieza', Icons.qr_code),
              const SizedBox(height: 12),
              _campo(nombreController, 'Descripción', Icons.description),
              const SizedBox(height: 12),
              _campo(familiaController, 'Familia', Icons.category),
              const SizedBox(height: 12),
              _campo(observacionController, 'Observaciones', Icons.notes),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () {
              if (codigoController.text.trim().isEmpty ||
                  nombreController.text.trim().isEmpty ||
                  familiaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código, descripción y familia son obligatorios')),
                );
                return;
              }

              final nuevo = MaterialItem(
                codigo: codigoController.text.trim(),
                nombre: nombreController.text.trim(),
                familia: familiaController.text.trim(),
                observacion: observacionController.text.trim(),
              );

              appState.guardarMaterialEnSupabase(nuevo);
              setState(() {});
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController controller, String label, IconData icon) => TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
      );

  @override
  Widget build(BuildContext context) {
    final materiales = materialesFiltrados;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Maestro de Materiales', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              FilledButton.icon(onPressed: () => _abrirFormulario(), icon: const Icon(Icons.add), label: const Text('Nuevo material')),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(labelText: 'Buscar por código, descripción o familia', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (value) => setState(() => busqueda = value),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: materiales.isEmpty
                ? const Center(child: Text('No se encontraron materiales.'))
                : ListView.separated(
                    itemCount: materiales.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final m = materiales[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.inventory_2)),
                          title: Text('${m.codigo} - ${m.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Familia: ${m.familia}'),
                          trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _abrirFormulario(material: m)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
