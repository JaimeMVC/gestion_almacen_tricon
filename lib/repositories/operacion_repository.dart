import '../services/supabase_service.dart';

class OperacionRepository {
  OperacionRepository({SupabaseService? service})
      : _service = service ?? supabaseService;

  final SupabaseService _service;

  Future<String> registrarRecepcion({
    required String materialId,
    required String almacenId,
    required String ubicacionId,
    required num cantidad,
    required num costoUnitario,
    required String moneda,
    String? proveedorId,
    String? regionId,
    String ordenCompra = '',
    String factura = '',
    DateTime? fechaCompra,
    String usuario = '',
    String observacion = '',
  }) =>
      _service.registrarRecepcion(
        materialId: materialId,
        almacenId: almacenId,
        ubicacionId: ubicacionId,
        cantidad: cantidad,
        costoUnitario: costoUnitario,
        moneda: moneda,
        proveedorId: proveedorId,
        regionId: regionId,
        ordenCompra: ordenCompra,
        factura: factura,
        fechaCompra: fechaCompra,
        usuario: usuario,
        observacion: observacion,
      );

  Future<String> registrarTransferencia({
    required String materialId,
    required String almacenOrigenId,
    required String ubicacionOrigenId,
    required String almacenDestinoId,
    required String ubicacionDestinoId,
    required num cantidad,
    String usuario = '',
    String observacion = '',
  }) =>
      _service.registrarTransferencia(
        materialId: materialId,
        almacenOrigenId: almacenOrigenId,
        ubicacionOrigenId: ubicacionOrigenId,
        almacenDestinoId: almacenDestinoId,
        ubicacionDestinoId: ubicacionDestinoId,
        cantidad: cantidad,
        usuario: usuario,
        observacion: observacion,
      );

  Future<String> registrarSalidaConsumoMultiple({
    required String almacenOrigenId,
    required List<Map<String, dynamic>> items,
    required String destinoExterno,
    String? equipoId,
    String usuario = '',
    String observacion = '',
  }) => _service.registrarSalidaConsumoMultiple(
    almacenOrigenId: almacenOrigenId,
    items: items,
    destinoExterno: destinoExterno,
    equipoId: equipoId,
    usuario: usuario,
    observacion: observacion,
  );

  Future<String> registrarSalidaConsumo({
    required String materialId,
    required String almacenOrigenId,
    required String ubicacionOrigenId,
    required num cantidad,
    required String destinoExterno,
    String? equipoId,
    String usuario = '',
    String observacion = '',
  }) =>
      _service.registrarSalidaConsumo(
        materialId: materialId,
        almacenOrigenId: almacenOrigenId,
        ubicacionOrigenId: ubicacionOrigenId,
        cantidad: cantidad,
        destinoExterno: destinoExterno,
        equipoId: equipoId,
        usuario: usuario,
        observacion: observacion,
      );
}

final operacionRepository = OperacionRepository();
