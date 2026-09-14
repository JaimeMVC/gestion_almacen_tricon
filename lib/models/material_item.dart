class MaterialItem {
  final String id;
  final String codigo;
  final String nombre;
  final String familia;
  final String observacion;

  const MaterialItem({
    this.id = '',
    required this.codigo,
    required this.nombre,
    required this.familia,
    this.observacion = '',
  });

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      id: map['id']?.toString() ?? '',
      codigo: map['codigo']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      familia: map['familia']?.toString() ?? '',
      observacion: map['observacion']?.toString() ?? '',
    );
  }
}
