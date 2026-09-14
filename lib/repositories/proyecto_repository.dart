import '../models/proyecto.dart';
import '../services/supabase_service.dart';

class ProyectoRepository {
  ProyectoRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<Proyecto>> obtenerTodos({bool incluirInactivos = true}) =>
      _service.obtenerProyectos(incluirInactivos: incluirInactivos);

  Future<void> guardar(Proyecto proyecto) => _service.guardarProyecto(proyecto);

  Future<void> cambiarEstado({required String id, required bool activo}) =>
      _service.cambiarEstadoProyecto(id: id, activo: activo);
}

final proyectoRepository = ProyectoRepository();
