import 'package:flutter/material.dart';
import '../models/movimiento.dart';
import '../services/excel_service.dart';
import '../state/app_state.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) appState.cargarMovimientosDesdeSupabase();
    });
  }


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
      case 'SALIDA_CONSUMO':
      case 'DESPACHO':
        return Icons.local_shipping;
      case 'AJUSTE_POSITIVO':
      case 'AJUSTE_NEGATIVO':
      case 'AJUSTE':
        return Icons.tune;
      case 'TRANSFERENCIA_SALIDA':
      case 'TRANSFERENCIA_INGRESO':
      case 'TRANSFERENCIA':
        return Icons.swap_horiz;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final movimientos = appState.movimientos;
        final cargando = appState.cargandoMovimientos;
        final error = appState.errorMovimientos;
        return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('Movimientos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              IconButton(
                tooltip: 'Actualizar movimientos',
                onPressed: cargando ? null : () => appState.cargarMovimientosDesdeSupabase(),
                icon: const Icon(Icons.refresh),
              ),
              OutlinedButton.icon(
                onPressed: movimientos.isEmpty ? null : () => ExcelService.exportarMovimientos(movimientos),
                icon: const Icon(Icons.file_download),
                label: const Text('Exportar Excel'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: cargando && movimientos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : error != null && movimientos.isEmpty
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 36),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SelectableText(error, textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => appState.cargarMovimientosDesdeSupabase(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ))
                    : movimientos.isEmpty
                        ? const Center(child: Text('Todavía no hay movimientos registrados.'))
                        : ListView.separated(
                    itemCount: movimientos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final Movimiento m = movimientos[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(_iconoTipo(m.tipo))),
                          title: Text('${m.tipo} | ${m.codigoMaterial} - ${m.nombreMaterial}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Fecha: ${_formatearFecha(m.fecha)}\n'
                            'Cantidad: ${m.cantidad}\n'
                            'Origen: ${m.ubicacionOrigen.isEmpty ? "-" : m.ubicacionOrigen} | '
                            'Destino: ${m.ubicacionDestino.isEmpty ? "-" : m.ubicacionDestino}\n'
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
      },
    );
  }
}
