import '../models/documento.dart';
import '../services/supabase_service.dart';

class DocumentoRepository {
  DocumentoRepository({SupabaseService? service}) : _service = service ?? supabaseService;
  final SupabaseService _service;

  Future<List<Documento>> obtenerTodos() => _service.obtenerDocumentos();

  Future<void> cambiarEstado(String id, String estado) =>
      _service.cambiarEstadoDocumento(id: id, estado: estado);
}

final documentoRepository = DocumentoRepository();
