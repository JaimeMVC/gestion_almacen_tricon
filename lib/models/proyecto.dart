class Proyecto {
  final String id;
  final String codigo;
  final String nombre;
  final String cliente;
  final String descripcion;
  final DateTime? fechaInicio;
  final DateTime? fechaFinEstimada;
  final DateTime? fechaCierre;
  final bool activo;
  final String responsable;
  final String observacion;

  const Proyecto({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.cliente = '',
    this.descripcion = '',
    this.fechaInicio,
    this.fechaFinEstimada,
    this.fechaCierre,
    this.activo = true,
    this.responsable = '',
    this.observacion = '',
  });

  String get etiqueta => '$codigo - $nombre';

  factory Proyecto.fromMap(Map<String, dynamic> map) {
    DateTime? parseFecha(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    return Proyecto(
      id: map['id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      cliente: map['cliente']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      fechaInicio: parseFecha(map['fecha_inicio']),
      fechaFinEstimada: parseFecha(map['fecha_fin_estimada']),
      fechaCierre: parseFecha(map['fecha_cierre']),
      activo: map['activo'] as bool? ?? true,
      responsable: map['responsable']?.toString() ?? '',
      observacion: map['observacion']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    String? formatoFecha(DateTime? fecha) {
      if (fecha == null) return null;
      final mes = fecha.month.toString().padLeft(2, '0');
      final dia = fecha.day.toString().padLeft(2, '0');
      return '${fecha.year}-$mes-$dia';
    }

    return {
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'cliente': cliente.trim(),
      'descripcion': descripcion.trim(),
      'fecha_inicio': formatoFecha(fechaInicio),
      'fecha_fin_estimada': formatoFecha(fechaFinEstimada),
      'fecha_cierre': formatoFecha(fechaCierre),
      'activo': activo,
      'responsable': responsable.trim(),
      'observacion': observacion.trim(),
    };
  }
}
