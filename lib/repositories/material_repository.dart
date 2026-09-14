import '../models/material_item.dart';
import '../services/supabase_service.dart';

class MaterialRepository {
  MaterialRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<MaterialItem>> obtenerTodos() => _service.obtenerMateriales();

  Future<void> guardar(MaterialItem material) =>
      _service.guardarMaterial(material);
}

final materialRepository = MaterialRepository();
