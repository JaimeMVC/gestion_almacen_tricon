import '../models/proveedor.dart';
import '../models/region_compra.dart';
import '../services/supabase_service.dart';

class CatalogoCompraRepository {
  CatalogoCompraRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<Proveedor>> obtenerProveedores({bool soloActivos = false}) =>
      _service.obtenerProveedores(soloActivos: soloActivos);

  Future<void> guardarProveedor(Proveedor proveedor) =>
      _service.guardarProveedor(proveedor);

  Future<void> cambiarEstadoProveedor({
    required String id,
    required bool activo,
  }) =>
      _service.cambiarEstadoProveedor(id: id, activo: activo);

  Future<List<RegionCompra>> obtenerRegiones({bool soloActivas = false}) =>
      _service.obtenerRegiones(soloActivas: soloActivas);

  Future<void> guardarRegion(RegionCompra region) =>
      _service.guardarRegion(region);

  Future<void> cambiarEstadoRegion({
    required String id,
    required bool activa,
  }) =>
      _service.cambiarEstadoRegion(id: id, activa: activa);
}

final catalogoCompraRepository = CatalogoCompraRepository();
