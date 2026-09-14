class DocumentoItem {
  final String id;
  final String materialCodigo;
  final String materialNombre;
  final num cantidad;
  final String unidad;
  final num costoUnitario;
  final String moneda;
  final String ubicacionOrigen;
  final String ubicacionDestino;
  final String equipoCodigo;
  final String equipoDescripcion;

  const DocumentoItem({
    required this.id,
    required this.materialCodigo,
    required this.materialNombre,
    required this.cantidad,
    required this.unidad,
    required this.costoUnitario,
    required this.moneda,
    required this.ubicacionOrigen,
    required this.ubicacionDestino,
    required this.equipoCodigo,
    required this.equipoDescripcion,
  });

  num get total => cantidad * costoUnitario;
  String get equipoEtiqueta => equipoCodigo.isEmpty
      ? ''
      : (equipoDescripcion.isEmpty ? equipoCodigo : '$equipoCodigo - $equipoDescripcion');

  factory DocumentoItem.fromMap(Map<String, dynamic> map) => DocumentoItem(
        id: map['item_id']?.toString() ?? '',
        materialCodigo: map['material_codigo']?.toString() ?? '',
        materialNombre: map['material_nombre']?.toString() ?? '',
        cantidad: map['cantidad'] as num? ?? 0,
        unidad: map['unidad']?.toString() ?? 'UN',
        costoUnitario: map['costo_unitario'] as num? ?? 0,
        moneda: map['moneda']?.toString() ?? 'ARS',
        ubicacionOrigen: map['ubicacion_origen']?.toString() ?? '',
        ubicacionDestino: map['ubicacion_destino']?.toString() ?? '',
        equipoCodigo: map['equipo_codigo']?.toString() ?? '',
        equipoDescripcion: map['equipo_descripcion']?.toString() ?? '',
      );
}

class Documento {
  final String id;
  final String numero;
  final String tipo;
  final String estado;
  final DateTime fecha;
  final String proyecto;
  final String almacenOrigen;
  final String almacenDestino;
  final String destinoExterno;
  final String proveedor;
  final String responsable;
  final String observacion;
  final DateTime? emitidoAt;
  final DateTime? anuladoAt;
  final List<DocumentoItem> items;

  const Documento({
    required this.id,
    required this.numero,
    required this.tipo,
    required this.estado,
    required this.fecha,
    required this.proyecto,
    required this.almacenOrigen,
    required this.almacenDestino,
    required this.destinoExterno,
    required this.proveedor,
    required this.responsable,
    required this.observacion,
    required this.emitidoAt,
    required this.anuladoAt,
    required this.items,
  });

  String get tipoLegible {
    switch (tipo) {
      case 'TRANSFERENCIA_INTERNA':
        return 'Transferencia';
      case 'SALIDA_CONSUMO':
        return 'Consumo';
      case 'RECEPCION':
        return 'Recepción';
      default:
        return tipo.replaceAll('_', ' ');
    }
  }

  num get total => items.fold<num>(0, (suma, item) => suma + item.total);

  factory Documento.fromMap(Map<String, dynamic> map, List<DocumentoItem> items) {
    DateTime? parseNullable(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
    return Documento(
      id: map['id']?.toString() ?? '',
      numero: map['numero']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      estado: map['estado']?.toString() ?? 'EMITIDO',
      fecha: DateTime.tryParse(map['fecha']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      proyecto: map['proyecto']?.toString() ?? '',
      almacenOrigen: map['almacen_origen']?.toString() ?? '',
      almacenDestino: map['almacen_destino']?.toString() ?? '',
      destinoExterno: map['destino_externo']?.toString() ?? '',
      proveedor: map['proveedor']?.toString() ?? '',
      responsable: map['responsable']?.toString() ?? '',
      observacion: map['observacion']?.toString() ?? '',
      emitidoAt: parseNullable(map['emitido_at']),
      anuladoAt: parseNullable(map['anulado_at']),
      items: items,
    );
  }
}
