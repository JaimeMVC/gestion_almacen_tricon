import 'package:flutter/material.dart';
import '../models/ubicacion.dart';
import '../state/app_state.dart';

class UbicacionesScreen extends StatefulWidget {
  const UbicacionesScreen({super.key});

  @override
  State<UbicacionesScreen> createState() => _UbicacionesScreenState();
}

class _UbicacionesScreenState extends State<UbicacionesScreen> {
  String busqueda = '';

  final codigoController = TextEditingController();
  final descripcionController = TextEditingController();

  @override
  void dispose() {
    codigoController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  List<Ubicacion> get ubicacionesFiltradas {
    final texto = busqueda.toLowerCase();
    return appState.ubicaciones.where((u) {
      return u.codigo.toLowerCase().contains(texto) || u.descripcion.toLowerCase().contains(texto);
    }).toList();
  }

  void _abrirFormulario({Ubicacion? ubicacion}) {
    if (ubicacion != null) {
      codigoController.text = ubicacion.codigo;
      descripcionController.text = ubicacion.descripcion;
    } else {
      codigoController.clear();
      descripcionController.clear();
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(ubicacion == null ? 'Nueva ubicación' : 'Editar ubicación'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(codigoController, 'Código de ubicación', Icons.location_on),
                const SizedBox(height: 12),
                _campo(descripcionController, 'Descripción', Icons.description),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: () {
                if (codigoController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El código de ubicación es obligatorio')));
                  return;
                }

                final nueva = Ubicacion(codigo: codigoController.text.trim(), descripcion: descripcionController.text.trim());
                appState.guardarUbicacion(nueva);
                setState(() {});
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _campo(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
    );
  }

  int _cantidadMaterialesEnUbicacion(String codigoUbicacion) {
    return appState.stock.where((s) => s.ubicacion.toLowerCase() == codigoUbicacion.toLowerCase()).length;
  }

  int _stockTotalEnUbicacion(String codigoUbicacion) {
    return appState.stock
        .where((s) => s.ubicacion.toLowerCase() == codigoUbicacion.toLowerCase())
        .fold<int>(0, (total, s) => total + s.cantidad);
  }

  @override
  Widget build(BuildContext context) {
    final ubicaciones = ubicacionesFiltradas;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Ubicaciones', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              FilledButton.icon(onPressed: () => _abrirFormulario(), icon: const Icon(Icons.add), label: const Text('Nueva ubicación')),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(labelText: 'Buscar por código o descripción', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (value) => setState(() => busqueda = value),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ubicaciones.isEmpty
                ? const Center(child: Text('No se encontraron ubicaciones.'))
                : ListView.separated(
                    itemCount: ubicaciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final u = ubicaciones[index];
                      final materiales = _cantidadMaterialesEnUbicacion(u.codigo);
                      final stockTotal = _stockTotalEnUbicacion(u.codigo);
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.location_on)),
                          title: Text(u.codigo, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${u.descripcion.isEmpty ? "Sin descripción" : u.descripcion}\nMateriales distintos: $materiales | Stock total: $stockTotal'),
                          trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _abrirFormulario(ubicacion: u)),
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
