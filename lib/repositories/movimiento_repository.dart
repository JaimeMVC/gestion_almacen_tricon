import '../models/movimiento.dart';
import '../services/supabase_service.dart';

class MovimientoRepository {
  MovimientoRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<Movimiento>> obtenerTodos() => _service.obtenerMovimientos();

  Future<PaginaMovimientos> obtenerPagina({
    required int pagina,
    required int tamanoPagina,
    String buscar = '',
    String almacenId = '',
    String proveedorId = '',
    String tipo = '',
    DateTime? desde,
    DateTime? hasta,
  }) => _service.obtenerPaginaMovimientos(
    pagina: pagina,
    tamanoPagina: tamanoPagina,
    buscar: buscar,
    almacenId: almacenId,
    proveedorId: proveedorId,
    tipo: tipo,
    desde: desde,
    hasta: hasta,
  );
}

final movimientoRepository = MovimientoRepository();
