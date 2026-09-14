import '../models/equipo.dart';
import '../services/supabase_service.dart';

class EquipoRepository {
  EquipoRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<Equipo>> obtenerEquipos({bool soloActivos = false}) =>
      _service.obtenerEquipos(soloActivos: soloActivos);

  Future<void> guardarEquipo(Equipo equipo) => _service.guardarEquipo(equipo);

  Future<void> cambiarEstado({required String id, required bool activo}) =>
      _service.cambiarEstadoEquipo(id: id, activo: activo);
}

final equipoRepository = EquipoRepository();
