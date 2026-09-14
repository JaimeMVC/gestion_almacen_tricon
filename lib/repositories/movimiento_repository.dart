import '../models/movimiento.dart';
import '../services/supabase_service.dart';

class MovimientoRepository {
  MovimientoRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<Movimiento>> obtenerTodos() => _service.obtenerMovimientos();
}

final movimientoRepository = MovimientoRepository();
