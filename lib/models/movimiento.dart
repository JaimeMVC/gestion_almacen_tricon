class Movimiento {
  final String id;
  final DateTime fecha;
  final String tipo;
  final String materialId;
  final String codigoMaterial;
  final String nombreMaterial;
  final String familia;
  final num cantidad;
  final String almacenOrigenId;
  final String almacenOrigenNombre;
  final String almacenDestinoId;
  final String almacenDestinoNombre;
  final String ubicacionOrigenId;
  final String ubicacionOrigen;
  final String ubicacionDestinoId;
  final String ubicacionDestino;
  final String proveedorId;
  final String proveedorNombre;
  final String regionId;
  final String regionNombre;
  final String regionPais;
  final num costoUnitario;
  final String moneda;
  final num valorTotal;
  final String ordenCompra;
  final String factura;
  final DateTime? fechaCompra;
  final String remitoId;
  final String remitoNumero;
  final String transferenciaId;
  final String usuario;
  final String destinoExterno;
  final String observacion;
  final String equipoId;
  final String equipoCodigo;
  final String equipoDescripcion;

  const Movimiento({
    this.id = '',
    required this.fecha,
    required this.tipo,
    this.materialId = '',
    required this.codigoMaterial,
    required this.nombreMaterial,
    this.familia = '',
    required this.cantidad,
    this.almacenOrigenId = '',
    this.almacenOrigenNombre = '',
    this.almacenDestinoId = '',
    this.almacenDestinoNombre = '',
    this.ubicacionOrigenId = '',
    this.ubicacionOrigen = '',
    this.ubicacionDestinoId = '',
    this.ubicacionDestino = '',
    this.proveedorId = '',
    this.proveedorNombre = '',
    this.regionId = '',
    this.regionNombre = '',
    this.regionPais = '',
    this.costoUnitario = 0,
    this.moneda = 'ARS',
    this.valorTotal = 0,
    this.ordenCompra = '',
    this.factura = '',
    this.fechaCompra,
    this.remitoId = '',
    this.remitoNumero = '',
    this.transferenciaId = '',
    required this.usuario,
    this.destinoExterno = '',
    this.observacion = '',
    this.equipoId = '',
    this.equipoCodigo = '',
    this.equipoDescripcion = '',
  });

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    DateTime? parseFecha(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString())?.toLocal();
    }

    return Movimiento(
      id: map['id']?.toString() ?? '',
      fecha: parseFecha(map['fecha']) ?? DateTime.now(),
      tipo: map['tipo']?.toString() ?? '',
      materialId: map['material_id']?.toString() ?? '',
      codigoMaterial: map['material_codigo']?.toString() ?? '',
      nombreMaterial: map['material_nombre']?.toString() ?? '',
      familia: map['familia']?.toString() ?? '',
      cantidad: map['cantidad'] as num? ?? 0,
      almacenOrigenId: map['almacen_origen_id']?.toString() ?? '',
      almacenOrigenNombre: map['almacen_origen_nombre']?.toString() ?? '',
      almacenDestinoId: map['almacen_destino_id']?.toString() ?? '',
      almacenDestinoNombre: map['almacen_destino_nombre']?.toString() ?? '',
      ubicacionOrigenId: map['ubicacion_origen_id']?.toString() ?? '',
      ubicacionOrigen: map['ubicacion_origen_codigo']?.toString() ?? '',
      ubicacionDestinoId: map['ubicacion_destino_id']?.toString() ?? '',
      ubicacionDestino: map['ubicacion_destino_codigo']?.toString() ?? '',
      proveedorId: map['proveedor_id']?.toString() ?? '',
      proveedorNombre: map['proveedor_nombre']?.toString() ?? '',
      regionId: map['region_id']?.toString() ?? '',
      regionNombre: map['region_nombre']?.toString() ?? '',
      regionPais: map['region_pais']?.toString() ?? '',
      costoUnitario: map['costo_unitario'] as num? ?? 0,
      moneda: map['moneda']?.toString() ?? 'ARS',
      valorTotal: map['valor_total'] as num? ?? 0,
      ordenCompra: map['orden_compra']?.toString() ?? '',
      factura: map['factura']?.toString() ?? '',
      fechaCompra: parseFecha(map['fecha_compra']),
      remitoId: map['remito_id']?.toString() ?? '',
      remitoNumero: map['remito_numero']?.toString() ?? '',
      transferenciaId: map['transferencia_id']?.toString() ?? '',
      usuario: map['usuario']?.toString() ?? '',
      destinoExterno: map['destino_externo']?.toString() ?? '',
      observacion: map['observacion']?.toString() ?? '',
      equipoId: map['equipo_id']?.toString() ?? '',
      equipoCodigo: map['equipo_codigo']?.toString() ?? '',
      equipoDescripcion: map['equipo_descripcion']?.toString() ?? '',
    );
  }

  String get almacenPrincipal =>
      almacenOrigenNombre.isNotEmpty ? almacenOrigenNombre : almacenDestinoNombre;

  String get ubicacionPrincipal =>
      ubicacionOrigen.isNotEmpty ? ubicacionOrigen : ubicacionDestino;

  String get equipoEtiqueta => equipoCodigo.isEmpty
      ? ''
      : equipoDescripcion.isEmpty
          ? equipoCodigo
          : '$equipoCodigo - $equipoDescripcion';
}
