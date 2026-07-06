import 'package:flutter/material.dart';
import '../models/stock_item.dart';
import '../state/app_state.dart';

class DespachoScreen extends StatefulWidget {
  const DespachoScreen({super.key});

  @override
  State<DespachoScreen> createState() => _DespachoScreenState();
}

class _DespachoScreenState extends State<DespachoScreen> {
  final _formKey = GlobalKey<FormState>();

  StockItem? stockSeleccionado;

  final cantidadController = TextEditingController();
  final destinoController = TextEditingController();
  final despachadoPorController = TextEditingController(text: 'Operador');
  final observacionController = TextEditingController();

  @override
  void dispose() {
    cantidadController.dispose();
    destinoController.dispose();
    despachadoPorController.dispose();
    observacionController.dispose();
    super.dispose();
  }

  void _despachar() {
    if (!_formKey.currentState!.validate()) return;
    if (stockSeleccionado == null) return;

    final cantidad = int.parse(cantidadController.text.trim());

    final ok = appState.despacharStock(
      stockItem: stockSeleccionado!,
      cantidad: cantidad,
      destino: destinoController.text.trim(),
      usuario: despachadoPorController.text.trim(),
      observacion: observacionController.text.trim(),
    );

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay stock suficiente para despachar esa cantidad')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Despacho realizado: ${stockSeleccionado!.material.codigo} x $cantidad')));

    setState(() => stockSeleccionado = null);
    cantidadController.clear();
    destinoController.clear();
    despachadoPorController.text = 'Operador';
    observacionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final stock = appState.stock;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text('Despacho de material', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                      child: DropdownButtonFormField<StockItem>(
                        value: stockSeleccionado,
                        decoration: const InputDecoration(labelText: 'Material a despachar', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2)),
                        items: stock.map((s) {
                          final m = s.material;
                          return DropdownMenuItem(value: s, child: Text('${m.codigo} - ${m.nombre} | Stock: ${s.cantidad} | Ubicación: ${s.ubicacion}'));
                        }).toList(),
                        validator: (value) => value == null ? 'Seleccione un material' : null,
                        onChanged: (value) => setState(() => stockSeleccionado = value),
                      ),
                    ),
                    _campoTexto(controller: cantidadController, label: 'Cantidad a despachar', icon: Icons.numbers, obligatorio: true, esNumero: true),
                    _campoTexto(controller: destinoController, label: 'Destino', icon: Icons.place, obligatorio: true),
                    _campoTexto(controller: despachadoPorController, label: 'Despachado por', icon: Icons.person, obligatorio: true),
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
                        child: FilledButton.icon(onPressed: _despachar, icon: const Icon(Icons.local_shipping), label: const Text('Confirmar despacho')),
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

  Widget _campoTexto({required TextEditingController controller, required String label, required IconData icon, bool obligatorio = false, bool esNumero = false}) {
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
