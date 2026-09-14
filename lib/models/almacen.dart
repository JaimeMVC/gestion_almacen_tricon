class EstadoAlmacen {
  static const preparacion = 'PREPARACION';
  static const operativo = 'OPERATIVO';
  static const cerrado = 'CERRADO';
  static const archivado = 'ARCHIVADO';

  static const valores = [preparacion, operativo, cerrado, archivado];

  static String etiqueta(String estado) {
    switch (estado) {
      case preparacion:
        return 'En preparación';
      case cerrado:
        return 'Cerrado';
      case archivado:
        return 'Archivado';
      case operativo:
      default:
        return 'Operativo';
    }
  }

  static bool permiteOperaciones(String estado) =>
      estado == preparacion || estado == operativo;
}

class Almacen {
  final String id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String proyectoId;
  final String proyecto;
  final DateTime? fechaInicio;
  final DateTime? fechaFinEstimada;
  final DateTime? fechaCierre;
  final bool activo;
  final String estado;
  final String observacion;

  const Almacen({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion = '',
    this.proyectoId = '',
    this.proyecto = '',
    this.fechaInicio,
    this.fechaFinEstimada,
    this.fechaCierre,
    this.activo = true,
    this.estado = EstadoAlmacen.operativo,
    this.observacion = '',
  });

  factory Almacen.fromMap(Map<String, dynamic> map) {
    DateTime? parseFecha(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    final proyectoMap = map['proyectos'];
    String proyectoNombre = map['proyecto']?.toString() ?? '';
    if (proyectoMap is Map) {
      final codigo = proyectoMap['codigo']?.toString() ?? '';
      final nombre = proyectoMap['nombre']?.toString() ?? '';
      proyectoNombre = [codigo, nombre].where((e) => e.isNotEmpty).join(' - ');
    }

    final activo = map['activo'] as bool? ?? true;
    final estadoGuardado = map['estado']?.toString().toUpperCase();
    final estado = EstadoAlmacen.valores.contains(estadoGuardado)
        ? estadoGuardado!
        : (activo ? EstadoAlmacen.operativo : EstadoAlmacen.cerrado);

    return Almacen(
      id: map['id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      descripcion: map['descripcion']?.toString() ?? '',
      proyectoId: map['proyecto_id']?.toString() ?? '',
      proyecto: proyectoNombre,
      fechaInicio: parseFecha(map['fecha_inicio']),
      fechaFinEstimada: parseFecha(map['fecha_fin_estimada']),
      fechaCierre: parseFecha(map['fecha_cierre']),
      activo: activo,
      estado: estado,
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

    final permiteOperaciones = EstadoAlmacen.permiteOperaciones(estado);
    return {
      'codigo': codigo.trim(),
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'proyecto_id': proyectoId.isEmpty ? null : proyectoId,
      'fecha_inicio': formatoFecha(fechaInicio),
      'fecha_fin_estimada': formatoFecha(fechaFinEstimada),
      'fecha_cierre': formatoFecha(fechaCierre),
      'activo': permiteOperaciones,
      'estado': estado,
      'observacion': observacion.trim(),
    };
  }
}
