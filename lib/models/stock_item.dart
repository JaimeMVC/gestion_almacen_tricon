import 'material_item.dart';

class StockItem {
  final String id;
  final String materialId;
  MaterialItem material;
  final String almacenId;
  final String almacenCodigo;
  final String almacenNombre;
  final String proyecto;
  final bool almacenActivo;
  final String ubicacionId;
  final String ubicacion;
  final String ubicacionDescripcion;
  num cantidad;
  final num costoPromedio;
  final String moneda;

  StockItem({
    this.id = '',
    this.materialId = '',
    required this.material,
    this.almacenId = '',
    this.almacenCodigo = '',
    this.almacenNombre = '',
    this.proyecto = '',
    this.almacenActivo = true,
    this.ubicacionId = '',
    required this.ubicacion,
    this.ubicacionDescripcion = '',
    required this.cantidad,
    this.costoPromedio = 0,
    this.moneda = 'ARS',
  });

  num get valorTotal => cantidad * costoPromedio;

  String get almacenEtiqueta {
    if (almacenCodigo.isEmpty) return almacenNombre;
    if (almacenNombre.isEmpty) return almacenCodigo;
    return '$almacenCodigo - $almacenNombre';
  }

  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id']?.toString() ?? '',
      materialId: map['material_id']?.toString() ?? '',
      material: MaterialItem(
        codigo: map['material_codigo']?.toString() ?? '',
        nombre: map['material_nombre']?.toString() ?? '',
        familia: map['familia']?.toString() ?? '',
      ),
      almacenId: map['almacen_id']?.toString() ?? '',
      almacenCodigo: map['almacen_codigo']?.toString() ?? '',
      almacenNombre: map['almacen_nombre']?.toString() ?? '',
      proyecto: map['proyecto']?.toString() ?? '',
      almacenActivo: map['almacen_activo'] as bool? ?? true,
      ubicacionId: map['ubicacion_id']?.toString() ?? '',
      ubicacion: map['ubicacion_codigo']?.toString() ?? '',
      ubicacionDescripcion:
          map['ubicacion_descripcion']?.toString() ?? '',
      cantidad: map['cantidad'] as num? ?? 0,
      costoPromedio: map['costo_promedio'] as num? ?? 0,
      moneda: map['moneda']?.toString() ?? 'ARS',
    );
  }
}
