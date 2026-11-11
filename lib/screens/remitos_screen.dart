import 'package:flutter/material.dart';

import '../models/documento.dart';
import '../pdf/documento_pdf.dart';
import '../repositories/documento_repository.dart';

class RemitosScreen extends StatefulWidget {
  const RemitosScreen({super.key});

  @override
  State<RemitosScreen> createState() => _RemitosScreenState();
}

class _RemitosScreenState extends State<RemitosScreen> {
  bool _cargando = true;
  String? _error;
  List<Documento> _documentos = [];

  @override
  void initState() {
    super.initState();
    _actualizar();
  }

  Future<void> _actualizar() async {
    if (mounted) setState(() { _cargando = true; _error = null; });
    try {
      final datos = await documentoRepository.obtenerTodos();
      if (mounted) setState(() => _documentos = datos);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _fecha(DateTime fecha) {
    final f = fecha.toLocal();
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} '
        '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: Text('Remitos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
          IconButton(tooltip: 'Actualizar remitos', onPressed: _cargando ? null : _actualizar,
              icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 16),
        Expanded(child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 38),
                    const SizedBox(height: 12),
                    const Text('No se pudieron cargar los remitos de Supabase.'),
                    const SizedBox(height: 8),
                    SelectableText(_error!, textAlign: TextAlign.center),
                    TextButton(onPressed: _actualizar, child: const Text('Reintentar')),
                  ]))
                : _documentos.isEmpty
                    ? const Center(child: Text('No hay remitos registrados en Supabase.'))
                    : RefreshIndicator(
                        onRefresh: _actualizar,
                        child: ListView.separated(
                          itemCount: _documentos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final d = _documentos[index];
                            final destino = d.destinoExterno.isNotEmpty
                                ? d.destinoExterno
                                : (d.almacenDestino.isNotEmpty ? d.almacenDestino : 'Ver detalle');
                            return Card(child: ExpansionTile(
                              leading: const Icon(Icons.receipt_long),
                              title: Text('${d.numero} · ${d.tipoLegible}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${_fecha(d.fecha)} · ${d.estado} · ${d.items.length} materiales'),
                              trailing: IconButton(
                                tooltip: 'Ver / imprimir PDF',
                                icon: const Icon(Icons.picture_as_pdf),
                                onPressed: () async {
                                  try { await DocumentoPdf.imprimir(d); }
                                  catch (e) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('No se pudo generar el PDF: $e')));
                                  }
                                },
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Origen: ${d.almacenOrigen} · Destino: $destino'),
                                    Text('Responsable: ${d.responsable}'),
                                    if (d.observacion.isNotEmpty) Text('Observaciones: ${d.observacion}'),
                                    const SizedBox(height: 8),
                                    for (final item in d.items)
                                      Padding(padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text('• ${item.materialCodigo} - ${item.materialNombre}: '
                                            '${item.cantidad} ${item.unidad}'
                                            '${item.equipoEtiqueta.isEmpty ? '' : ' · ${item.equipoEtiqueta}'}')),
                                  ]),
                                ),
                              ],
                            ));
                          },
                        ),
                      )),
      ]),
    );
  }
}
