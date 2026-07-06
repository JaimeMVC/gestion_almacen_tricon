class Movimiento {
  final DateTime fecha;
  final String tipo;
  final String codigoMaterial;
  final String nombreMaterial;
  final int cantidad;
  final String ubicacionOrigen;
  final String ubicacionDestino;
  final String usuario;
  final String observacion;

  Movimiento({
    required this.fecha,
    required this.tipo,
    required this.codigoMaterial,
    required this.nombreMaterial,
    required this.cantidad,
    this.ubicacionOrigen = '',
    this.ubicacionDestino = '',
    required this.usuario,
    this.observacion = '',
  });
}
