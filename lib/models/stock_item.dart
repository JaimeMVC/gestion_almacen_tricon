import 'material_item.dart';

class StockItem {
  MaterialItem material;
  final String ubicacion;
  int cantidad;

  StockItem({
    required this.material,
    required this.ubicacion,
    required this.cantidad,
  });
}
