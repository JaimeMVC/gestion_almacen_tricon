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
  String almacenSeleccionado = 'Todos';
  bool mostrarAlmacenesInactivos = false;

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

  List<String> _almacenesDisponibles() {
    final valores = appState.stock
        .where((item) => mostrarAlmacenesInactivos || item.almacenActivo)
        .map((item) => item.almacenId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    valores.sort((a, b) {
      final itemA = appState.stock.firstWhere((item) => item.almacenId == a);
      final itemB = appState.stock.firstWhere((item) => item.almacenId == b);
      return itemA.almacenEtiqueta.compareTo(itemB.almacenEtiqueta);
    });

    return valores;
  }

  String _nombreAlmacen(String almacenId) {
    final item = appState.stock.firstWhere((s) => s.almacenId == almacenId);
    return item.almacenEtiqueta;
  }

  List<StockItem> _filtrarStock() {
    final textoBuscado = busqueda.trim().toLowerCase();

    return appState.stock.where((s) {
      final m = s.material;
      final coincideFamilia =
          familiaSeleccionada == 'Todas' || m.familia == familiaSeleccionada;
      final coincideAlmacen =
          almacenSeleccionado == 'Todos' || s.almacenId == almacenSeleccionado;
      final coincideEstado = mostrarAlmacenesInactivos || s.almacenActivo;
      final texto = '${m.codigo} ${m.nombre} ${m.familia} '
              '${s.almacenCodigo} ${s.almacenNombre} ${s.proyecto} '
              '${s.ubicacion} ${s.ubicacionDescripcion}'
          .toLowerCase();

      return coincideFamilia &&
          coincideAlmacen &&
          coincideEstado &&
          texto.contains(textoBuscado);
    }).toList();
  }

  String _numero(num valor, {int decimales = 3}) {
    if (valor == valor.roundToDouble()) return valor.toInt().toString();
    return valor.toStringAsFixed(decimales);
  }

  @override
  Widget build(BuildContext context) {
    final familias = appState.familias;
    final almacenes = _almacenesDisponibles();

    if (almacenSeleccionado != 'Todos' &&
        !almacenes.contains(almacenSeleccionado)) {
      almacenSeleccionado = 'Todos';
    }

    final stock = _filtrarStock();
    final cantidadTotal = stock.fold<num>(0, (total, item) => total + item.cantidad);
    final valorTotal = stock.fold<num>(0, (total, item) => total + item.valorTotal);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Stock actual',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar stock',
                    onPressed: appState.cargandoStock
                        ? null
                        : appState.cargarStockDesdeSupabase,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: stock.isEmpty
                        ? null
                        : () => ExcelService.exportarStock(stock),
                    icon: const Icon(Icons.file_download),
                    label: const Text('Exportar Excel'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 430,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText:
                            'Buscar material, almacén, proyecto o ubicación',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => busqueda = value),
                    ),
                  ),
                  SizedBox(
                    width: 310,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: almacenSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Almacén',
                        prefixIcon: Icon(Icons.warehouse),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'Todos',
                          child: Text('Todos los almacenes'),
                        ),
                        ...almacenes.map(
                          (id) => DropdownMenuItem(
                            value: id,
                            child: Text(
                              _nombreAlmacen(id),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(
                        () => almacenSeleccionado = value ?? 'Todos',
                      ),
                    ),
                  ),
                  FilterChip(
                    selected: mostrarAlmacenesInactivos,
                    avatar: const Icon(Icons.history, size: 18),
                    label: const Text('Mostrar almacenes inactivos'),
                    onSelected: (value) => setState(() {
                      mostrarAlmacenesInactivos = value;
                      almacenSeleccionado = 'Todos';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: familias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final familia = familias[index];
                    return ChoiceChip(
                      selected: familiaSeleccionada == familia,
                      avatar: Icon(
                        familia == 'Todas'
                            ? Icons.all_inbox
                            : _iconoFamilia(familia),
                        size: 18,
                      ),
                      label: Text(familia),
                      onSelected: (_) =>
                          setState(() => familiaSeleccionada = familia),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ResumenCard(
                    titulo: 'Posiciones',
                    valor: stock.length.toString(),
                    icono: Icons.location_on,
                  ),
                  const SizedBox(width: 10),
                  _ResumenCard(
                    titulo: 'Cantidad total',
                    valor: _numero(cantidadTotal),
                    icono: Icons.inventory_2,
                  ),
                  const SizedBox(width: 10),
                  _ResumenCard(
                    titulo: 'Valor del filtro',
                    valor: stock.isEmpty
                        ? '-'
                        : '${stock.first.moneda} ${valorTotal.toStringAsFixed(2)}',
                    icono: Icons.payments,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: _contenidoStock(stock)),
            ],
          ),
        );
      },
    );
  }

  Widget _contenidoStock(List<StockItem> stock) {
    if (appState.cargandoStock) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appState.errorStock != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 10),
            Text(appState.errorStock!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: appState.cargarStockDesdeSupabase,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (stock.isEmpty) {
      return const Center(
        child: Text('No se encontraron existencias para los filtros aplicados.'),
      );
    }

    return ListView.separated(
      itemCount: stock.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final s = stock[index];
        final m = s.material;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(child: Icon(_iconoFamilia(m.familia))),
              title: Text(
                '${m.codigo} - ${m.nombre}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 5,
                  children: [
                    Text('Familia: ${m.familia}'),
                    Text('Almacén: ${s.almacenEtiqueta}'),
                    if (s.proyecto.isNotEmpty) Text('Proyecto: ${s.proyecto}'),
                    Text(
                      'Ubicación: ${s.ubicacion}'
                      '${s.ubicacionDescripcion.isEmpty ? '' : ' - ${s.ubicacionDescripcion}'}',
                    ),
                    Text(
                      'Costo prom.: ${s.moneda} ${s.costoPromedio.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Valor: ${s.moneda} ${s.valorTotal.toStringAsFixed(2)}',
                    ),
                    if (!s.almacenActivo)
                      const Text(
                        'Almacén inactivo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              trailing: Text(
                _numero(s.cantidad),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icono),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 12)),
                    Text(
                      valor,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
