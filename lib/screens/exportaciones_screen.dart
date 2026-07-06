import 'package:flutter/material.dart';
import '../services/excel_service.dart';
import '../state/app_state.dart';

class ExportacionesScreen extends StatelessWidget {
  const ExportacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text('Exportaciones', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Descargá información actual en formato Excel .xlsx.'),
          const SizedBox(height: 22),
          _ExportCard(
            title: 'Stock actual',
            description: 'Exporta código, descripción, familia, ubicación y cantidad.',
            icon: Icons.inventory_2,
            onExport: () => ExcelService.exportarStock(appState.stock),
          ),
          _ExportCard(
            title: 'Movimientos',
            description: 'Exporta ingresos y despachos registrados durante la sesión.',
            icon: Icons.swap_horiz,
            onExport: () => ExcelService.exportarMovimientos(appState.movimientos),
          ),
          _ExportCard(
            title: 'Materiales',
            description: 'Exporta el maestro de materiales.',
            icon: Icons.category,
            onExport: () => ExcelService.exportarMateriales(appState.materiales),
          ),
          _ExportCard(
            title: 'Ubicaciones',
            description: 'Exporta el maestro de ubicaciones.',
            icon: Icons.location_on,
            onExport: () => ExcelService.exportarUbicaciones(appState.ubicaciones),
          ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onExport;

  const _ExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
            FilledButton.icon(onPressed: onExport, icon: const Icon(Icons.file_download), label: const Text('Exportar')),
          ],
        ),
      ),
    );
  }
}
