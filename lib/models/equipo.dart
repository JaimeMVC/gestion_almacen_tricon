class Equipo {
  final String id;
  final String codigo;
  final String descripcion;
  final String marca;
  final String categoria;
  final String capacidad;
  final bool activo;

  const Equipo({
    this.id = '',
    required this.codigo,
    required this.descripcion,
    this.marca = '',
    this.categoria = '',
    this.capacidad = '',
    this.activo = true,
  });

  factory Equipo.fromMap(Map<String, dynamic> map) => Equipo(
        id: map['id']?.toString() ?? '',
        codigo: map['codigo']?.toString() ?? '',
        descripcion: map['descripcion']?.toString() ?? '',
        marca: map['marca']?.toString() ?? '',
        categoria: map['categoria']?.toString() ?? '',
        capacidad: map['capacidad']?.toString() ?? '',
        activo: map['activo'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'codigo': codigo.trim(),
        'descripcion': descripcion.trim(),
        'marca': marca.trim(),
        'categoria': categoria.trim(),
        'capacidad': capacidad.trim(),
        'activo': activo,
      };

  String get etiqueta => '$codigo - $descripcion';
}
