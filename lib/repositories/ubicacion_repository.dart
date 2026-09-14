import '../models/ubicacion.dart';
import '../services/supabase_service.dart';

class UbicacionRepository {
  UbicacionRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<Ubicacion>> obtenerTodas({bool incluirInactivas = true}) =>
      _service.obtenerUbicaciones(incluirInactivas: incluirInactivas);

  Future<void> guardar(Ubicacion ubicacion) =>
      _service.guardarUbicacion(ubicacion);

  Future<void> cambiarEstado({
    required String id,
    required bool activa,
  }) =>
      _service.cambiarEstadoUbicacion(id: id, activa: activa);
}

final ubicacionRepository = UbicacionRepository();
