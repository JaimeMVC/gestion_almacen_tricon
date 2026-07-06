import 'package:flutter/material.dart';
import '../models/movimiento.dart';
import '../state/app_state.dart';

class MovimientosScreen extends StatelessWidget {
  const MovimientosScreen({super.key});

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }

  IconData _iconoTipo(String tipo) {
    switch (tipo) {
      case 'INGRESO':
        return Icons.add_box;
      case 'DESPACHO':
        return Icons.local_shipping;
      case 'AJUSTE':
        return Icons.tune;
      case 'TRANSFERENCIA':
        return Icons.swap_horiz;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movimientos = appState.movimientos;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Movimientos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: movimientos.isEmpty
                ? const Center(child: Text('Todavía no hay movimientos registrados.'))
                : ListView.separated(
                    itemCount: movimientos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final Movimiento m = movimientos[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(_iconoTipo(m.tipo))),
                          title: Text('${m.tipo} | ${m.codigoMaterial} - ${m.nombreMaterial}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Fecha: ${_formatearFecha(m.fecha)}\n'
                            'Cantidad: ${m.cantidad}\n'
                            'Origen: ${m.ubicacionOrigen.isEmpty ? "-" : m.ubicacionOrigen} | Destino: ${m.ubicacionDestino.isEmpty ? "-" : m.ubicacionDestino}\n'
                            'Usuario: ${m.usuario}'
                            '${m.observacion.isEmpty ? "" : "\nObs: ${m.observacion}"}',
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
