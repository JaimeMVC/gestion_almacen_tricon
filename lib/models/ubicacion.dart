class Ubicacion {
  final String id;
  final String almacenId;
  final String almacenCodigo;
  final String almacenNombre;
  final String codigo;
  final String descripcion;
  final String observacion;
  final bool activa;

  const Ubicacion({
    this.id = '',
    this.almacenId = '',
    this.almacenCodigo = '',
    this.almacenNombre = '',
    required this.codigo,
    this.descripcion = '',
    this.observacion = '',
    this.activa = true,
  });

  factory Ubicacion.fromMap(Map<String, dynamic> map) {
    final almacen = map['almacenes'];
    final almacenMap = almacen is Map
        ? Map<String, dynamic>.from(almacen)
        : <String, dynamic>{};

    return Ubicacion(
      id: map['id']?.toString() ?? '',
      almacenId: map['almacen_id']?.toString() ?? '',
      almacenCodigo: almacenMap['codigo']?.toString() ?? '',
      almacenNombre: almacenMap['nombre']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      observacion: map['observacion']?.toString() ?? '',
      activa: map['activa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'almacen_id': almacenId,
      'codigo': codigo.trim(),
      'descripcion': descripcion.trim(),
      'observacion': observacion.trim(),
      'activa': activa,
    };
  }

  Ubicacion copyWith({
    String? id,
    String? almacenId,
    String? almacenCodigo,
    String? almacenNombre,
    String? codigo,
    String? descripcion,
    String? observacion,
    bool? activa,
  }) {
    return Ubicacion(
      id: id ?? this.id,
      almacenId: almacenId ?? this.almacenId,
      almacenCodigo: almacenCodigo ?? this.almacenCodigo,
      almacenNombre: almacenNombre ?? this.almacenNombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      observacion: observacion ?? this.observacion,
      activa: activa ?? this.activa,
    );
  }
}
