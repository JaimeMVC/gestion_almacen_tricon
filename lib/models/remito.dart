class Remito {
  final String numero;
  final DateTime fecha;
  final String codigoMaterial;
  final String nombreMaterial;
  final int cantidad;
  final String ubicacionOrigen;
  final String destino;
  final String despachadoPor;
  final String observacion;

  Remito({
    required this.numero,
    required this.fecha,
    required this.codigoMaterial,
    required this.nombreMaterial,
    required this.cantidad,
    required this.ubicacionOrigen,
    required this.destino,
    required this.despachadoPor,
    this.observacion = '',
  });
}
