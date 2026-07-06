import '../models/movimiento.dart';

class MovimientoService {
  static final List<Movimiento> _movimientos = [];

  List<Movimiento> obtenerMovimientos() {
    final lista = List<Movimiento>.from(_movimientos);
    lista.sort((a, b) => b.fecha.compareTo(a.fecha));
    return lista;
  }

  void registrarMovimiento(Movimiento movimiento) {
    _movimientos.add(movimiento);
  }

  int totalMovimientos() {
    return _movimientos.length;
  }
}