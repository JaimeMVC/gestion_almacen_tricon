class MaterialItem {
  final String codigo;
  final String nombre;
  final String familia;
  final String observacion;

  MaterialItem({
    required this.codigo,
    required this.nombre,
    required this.familia,
    this.observacion = '',
  });
}
