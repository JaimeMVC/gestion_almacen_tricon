import 'package:flutter/material.dart';
import '../models/stock_item.dart';
import '../services/excel_service.dart';
import '../state/app_state.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String busqueda = '';
  String familiaSeleccionada = 'Todas';

  IconData _iconoFamilia(String familia) {
    switch (familia) {
      case 'Filtros':
        return Icons.filter_alt;
      case 'Cables':
        return Icons.cable;
      case 'Sensores':
        return Icons.sensors;
      case 'Mangueras':
        return Icons.linear_scale;
      default:
        return Icons.category;
    }
  }

  List<StockItem> _filtrarStock() {
    return appState.stock.where((s) {
      final m = s.material;
      final coincideFamilia = familiaSeleccionada == 'Todas' || m.familia == familiaSeleccionada;
      final texto = '${m.codigo} ${m.nombre} ${m.familia} ${s.ubicacion}'.toLowerCase();
      return coincideFamilia && texto.contains(busqueda.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final familias = appState.familias;
    final stock = _filtrarStock();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Stock actual', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              OutlinedButton.icon(
                onPressed: () => ExcelService.exportarStock(stock),
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar Excel'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(labelText: 'Buscar por código, nombre, familia o ubicación', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (value) => setState(() => busqueda = value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: familias.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final familia = familias[index];
                return ChoiceChip(
                  selected: familiaSeleccionada == familia,
                  avatar: Icon(familia == 'Todas' ? Icons.all_inbox : _iconoFamilia(familia), size: 18),
                  label: Text(familia),
                  onSelected: (_) => setState(() => familiaSeleccionada = familia),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: stock.isEmpty
                ? const Center(child: Text('No se encontraron materiales.'))
                : ListView.separated(
                    itemCount: stock.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final s = stock[index];
                      final m = s.material;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(_iconoFamilia(m.familia))),
                          title: Text('${m.codigo} - ${m.nombre}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Familia: ${m.familia}\nUbicación: ${s.ubicacion}'),
                          trailing: Text(s.cantidad.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
