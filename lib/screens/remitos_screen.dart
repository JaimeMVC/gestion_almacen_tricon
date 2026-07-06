import 'package:flutter/material.dart';
import '../models/remito.dart';
import '../pdf/remito_pdf.dart';
import '../state/app_state.dart';

class RemitosScreen extends StatelessWidget {
  const RemitosScreen({super.key});

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final remitos = appState.remitos;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Remitos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: remitos.isEmpty
                ? const Center(child: Text('Todavía no hay remitos generados.'))
                : ListView.separated(
                    itemCount: remitos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final Remito r = remitos[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                          title: Text('${r.numero} | ${r.codigoMaterial} - ${r.nombreMaterial}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Fecha: ${_formatearFecha(r.fecha)}\n'
                            'Cantidad: ${r.cantidad}\n'
                            'Origen: ${r.ubicacionOrigen} | Destino: ${r.destino}\n'
                            'Despachado por: ${r.despachadoPor}'
                            '${r.observacion.isEmpty ? "" : "\nObs: ${r.observacion}"}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.picture_as_pdf),
                            onPressed: () => RemitoPdf.imprimir(r),
                          ),
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
