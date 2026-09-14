import '../models/stock_item.dart';
import '../services/supabase_service.dart';

class StockRepository {
  StockRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<List<StockItem>> obtenerActual() => _service.obtenerStock();
}

final stockRepository = StockRepository();
