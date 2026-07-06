class Ubicacion {
  final String codigo;
  final String descripcion;
  final bool activa;

  Ubicacion({
    required this.codigo,
    this.descripcion = '',
    this.activa = true,
  });
}
