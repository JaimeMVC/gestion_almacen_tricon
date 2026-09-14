import '../models/almacen.dart';
import '../services/supabase_service.dart';

class AlmacenRepository {
  AlmacenRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<Almacen>> obtenerTodos({bool incluirInactivos = true}) =>
      _service.obtenerAlmacenes(incluirInactivos: incluirInactivos);

  Future<void> guardar(Almacen almacen) => _service.guardarAlmacen(almacen);

  Future<void> cambiarEstado({
    required String id,
    required String estado,
  }) =>
      _service.cambiarEstadoAlmacen(id: id, estado: estado);
}

final almacenRepository = AlmacenRepository();
