import 'package:flutter/material.dart';

import '../models/equipo.dart';
import '../models/material_item.dart';
import '../models/stock_item.dart';
import '../models/ubicacion.dart';
import '../services/excel_service.dart';
import '../state/app_state.dart';

class CargaMasivaScreen extends StatefulWidget {
  const CargaMasivaScreen({super.key});

  @override
  State<CargaMasivaScreen> createState() => _CargaMasivaScreenState();
}

class _CargaMasivaScreenState extends State<CargaMasivaScreen> {
  bool cargando = false;
  ImportPreview<Equipo>? previewEquipos;
  ImportPreview<MaterialItem>? previewMateriales;
  ImportPreview<Ubicacion>? previewUbicaciones;
  ImportPreview<StockItem>? previewStock;

  Future<void> _previsualizarEquipos() async {
    await _ejecutar(() async {
      final preview = await ExcelService.previsualizarEquipos();
      if (preview == null) return 'Operación cancelada';

      final existentes = appState.equipos.map((e) => e.codigo.trim().toLowerCase()).toSet();
      final nuevos = preview.registrosValidos
          .where((e) => !existentes.contains(e.codigo.trim().toLowerCase()))
          .toList(growable: false);
      final omitidos = preview.registrosValidos.length - nuevos.length;
      final errores = List<String>.from(preview.errores);
      if (omitidos > 0) {
        errores.add('$omitidos equipo(s) ya existen en TRICON y serán omitidos.');
      }

      setState(() => previewEquipos = ImportPreview(
            archivo: preview.archivo,
            registrosValidos: nuevos,
            errores: errores,
          ));
      return 'Archivo leído: ${preview.archivo}';
    });
  }

  Future<void> _previsualizarMateriales() async {
    await _ejecutar(() async {
      final preview = await ExcelService.previsualizarMateriales();
      if (preview == null) return 'Operación cancelada';
      setState(() => previewMateriales = preview);
      return 'Archivo leído: ${preview.archivo}';
    });
  }

  Future<void> _previsualizarUbicaciones() async {
    await _ejecutar(() async {
      final preview = await ExcelService.previsualizarUbicaciones();
      if (preview == null) return 'Operación cancelada';
      setState(() => previewUbicaciones = preview);
      return 'Archivo leído: ${preview.archivo}';
    });
  }

  Future<void> _previsualizarStock() async {
    await _ejecutar(() async {
      final preview = await ExcelService.previsualizarStock();
      if (preview == null) return 'Operación cancelada';
      setState(() => previewStock = preview);
      return 'Archivo leído: ${preview.archivo}';
    });
  }

  Future<void> _ejecutar(Future<String> Function() accion) async {
    setState(() => cargando = true);
    try {
      final mensaje = await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error durante la operación: $e')));
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Future<void> _confirmarEquipos() async {
    final preview = previewEquipos;
    if (preview == null) return;
    await _ejecutar(() async {
      final importados = await appState.cargaMasivaEquipos(preview.registrosValidos);
      if (!mounted) return 'Equipos importados: $importados';
      setState(() => previewEquipos = null);
      return 'Equipos importados correctamente: $importados';
    });
  }

  Future<void> _confirmarMateriales() async {
    final preview = previewMateriales;
    if (preview == null) return;
    appState.cargaMasivaMateriales(preview.registrosValidos);
    setState(() => previewMateriales = null);
    _mensaje('Materiales importados: ${preview.cantidadValida}');
  }

  Future<void> _confirmarUbicaciones() async {
    final preview = previewUbicaciones;
    if (preview == null) return;
    appState.cargaMasivaUbicaciones(preview.registrosValidos);
    setState(() => previewUbicaciones = null);
    _mensaje('Ubicaciones importadas: ${preview.cantidadValida}');
  }

  Future<void> _confirmarStock() async {
    final preview = previewStock;
    if (preview == null) return;
    appState.cargaMasivaStock(preview.registrosValidos);
    setState(() => previewStock = null);
    _mensaje('Registros de stock importados: ${preview.cantidadValida}');
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text('Carga masiva', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Importá datos desde archivos Excel .xlsx. Primero se previsualizan y validan los datos; luego confirmás la importación.'),
          const SizedBox(height: 22),
          if (cargando) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          _ImportCard<Equipo>(
            title: 'Equipos / Activos',
            description: 'Admite tu maestro de flota. Columnas: Codigo, Descripcion del activo, MARCA, Categoria, Capacidad. La columna N° se ignora.',
            icon: Icons.precision_manufacturing,
            preview: previewEquipos,
            onDownload: ExcelService.descargarPlantillaEquipos,
            onPreview: _previsualizarEquipos,
            onConfirm: _confirmarEquipos,
            onCancel: () => setState(() => previewEquipos = null),
          ),
          _ImportCard<MaterialItem>(
            title: 'Materiales',
            description: 'Columnas esperadas: codigo, descripcion, familia, observacion.',
            icon: Icons.inventory_2,
            preview: previewMateriales,
            onDownload: ExcelService.descargarPlantillaMateriales,
            onPreview: _previsualizarMateriales,
            onConfirm: _confirmarMateriales,
            onCancel: () => setState(() => previewMateriales = null),
          ),
          _ImportCard<Ubicacion>(
            title: 'Ubicaciones',
            description: 'Columnas esperadas: codigo, descripcion.',
            icon: Icons.location_on,
            preview: previewUbicaciones,
            onDownload: ExcelService.descargarPlantillaUbicaciones,
            onPreview: _previsualizarUbicaciones,
            onConfirm: _confirmarUbicaciones,
            onCancel: () => setState(() => previewUbicaciones = null),
          ),
          _ImportCard<StockItem>(
            title: 'Stock inicial / recepción masiva',
            description: 'Columnas esperadas: codigo, descripcion, familia, ubicacion, cantidad, observacion. Genera movimientos de INGRESO.',
            icon: Icons.warehouse,
            preview: previewStock,
            onDownload: ExcelService.descargarPlantillaStock,
            onPreview: _previsualizarStock,
            onConfirm: _confirmarStock,
            onCancel: () => setState(() => previewStock = null),
          ),
        ],
      ),
    );
  }
}

class _ImportCard<T> extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final ImportPreview<T>? preview;
  final VoidCallback onDownload;
  final VoidCallback onPreview;
  final Future<void> Function() onConfirm;
  final VoidCallback onCancel;

  const _ImportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.preview,
    required this.onDownload,
    required this.onPreview,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final p = preview;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const SizedBox(width: 12),
                OutlinedButton.icon(onPressed: onDownload, icon: const Icon(Icons.download), label: const Text('Plantilla')),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: onPreview, icon: const Icon(Icons.upload_file), label: const Text('Seleccionar archivo')),
              ],
            ),
            if (p != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Archivo: ${p.archivo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Registros válidos: ${p.cantidadValida}'),
                    Text('Errores detectados: ${p.errores.length}'),
                    if (p.errores.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Errores:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...p.errores.take(8).map((e) => Text('• $e')),
                      if (p.errores.length > 8) Text('• ... y ${p.errores.length - 8} errores más'),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: p.cantidadValida > 0 ? onConfirm : null,
                          icon: const Icon(Icons.check),
                          label: const Text('Confirmar importación'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
