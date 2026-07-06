import 'package:flutter/material.dart';

import '../models/material_item.dart';
import '../models/ubicacion.dart';
import '../state/app_state.dart';

class IngresoMaterialScreen extends StatefulWidget {
  const IngresoMaterialScreen({super.key});

  @override
  State<IngresoMaterialScreen> createState() => _IngresoMaterialScreenState();
}

class _IngresoMaterialScreenState extends State<IngresoMaterialScreen> {
  final _formKey = GlobalKey<FormState>();

  MaterialItem? materialSeleccionado;
  Ubicacion? ubicacionSeleccionada;

  final cantidadController = TextEditingController();
  final usuarioController = TextEditingController(text: 'Operador');
  final observacionController = TextEditingController();

  @override
  void dispose() {
    cantidadController.dispose();
    usuarioController.dispose();
    observacionController.dispose();
    super.dispose();
  }

  void _guardarRecepcion() {
    if (!_formKey.currentState!.validate()) return;
    if (materialSeleccionado == null || ubicacionSeleccionada == null) return;

    appState.ingresarStock(
      material: materialSeleccionado!,
      ubicacion: ubicacionSeleccionada!.codigo,
      cantidad: int.parse(cantidadController.text.trim()),
      usuario: usuarioController.text.trim(),
      observacion: observacionController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recepción registrada: ${materialSeleccionado!.codigo}')),
    );

    setState(() {
      materialSeleccionado = null;
      ubicacionSeleccionada = null;
    });

    cantidadController.clear();
    usuarioController.text = 'Operador';
    observacionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final materiales = appState.materiales;
    final ubicaciones = appState.ubicaciones;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text('Recepción de material', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Wrap(
                  runSpacing: 18,
                  spacing: 18,
                  children: [
                    SizedBox(
                      width: 660,
                      child: DropdownButtonFormField<MaterialItem>(
                        value: materialSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Material',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        items: materiales.map((m) {
                          return DropdownMenuItem(value: m, child: Text('${m.codigo} - ${m.nombre} | ${m.familia}'));
                        }).toList(),
                        validator: (value) => value == null ? 'Seleccione un material' : null,
                        onChanged: (value) => setState(() => materialSeleccionado = value),
                      ),
                    ),
                    if (materialSeleccionado != null)
                      SizedBox(
                        width: 660,
                        child: Card(
                          color: const Color(0xFFEFF6FF),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(materialSeleccionado!.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Código: ${materialSeleccionado!.codigo}'),
                                Text('Familia: ${materialSeleccionado!.familia}'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    _campoTexto(controller: cantidadController, label: 'Cantidad recibida', icon: Icons.numbers, obligatorio: true, esNumero: true),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<Ubicacion>(
                        value: ubicacionSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación destino',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        items: ubicaciones.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.descripcion.isEmpty ? u.codigo : '${u.codigo} - ${u.descripcion}'),
                          );
                        }).toList(),
                        validator: (value) => value == null ? 'Seleccione una ubicación' : null,
                        onChanged: (value) => setState(() => ubicacionSeleccionada = value),
                      ),
                    ),
                    _campoTexto(controller: usuarioController, label: 'Recibido por', icon: Icons.person, obligatorio: true),
                    SizedBox(
                      width: 660,
                      child: TextFormField(
                        controller: observacionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
                      ),
                    ),
                    SizedBox(
                      width: 660,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(onPressed: _guardarRecepcion, icon: const Icon(Icons.save), label: const Text('Guardar recepción')),
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
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obligatorio = false,
    bool esNumero = false,
  }) {
    return SizedBox(
      width: 320,
      child: TextFormField(
        controller: controller,
        keyboardType: esNumero ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
        validator: obligatorio
            ? (value) {
                if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
                if (esNumero && int.tryParse(value) == null) return 'Ingrese un número válido';
                if (esNumero && int.parse(value) <= 0) return 'La cantidad debe ser mayor a 0';
                return null;
              }
            : null,
      ),
    );
  }
}
