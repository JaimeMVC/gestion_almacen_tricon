class RegionCompra {
  final String id;
  final String nombre;
  final String pais;
  final bool activa;

  const RegionCompra({
    this.id = '',
    required this.nombre,
    this.pais = '',
    this.activa = true,
  });

  factory RegionCompra.fromMap(Map<String, dynamic> map) {
    return RegionCompra(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      pais: map['pais']?.toString() ?? '',
      activa: map['activa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre.trim(),
        'pais': pais.trim(),
        'activa': activa,
      };

  String get etiqueta => pais.trim().isEmpty ? nombre : '$nombre - $pais';
}
