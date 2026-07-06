import '../data/demo_data.dart';
import '../models/material_item.dart';

class MaterialService {
  static final List<MaterialItem> _materiales = List.from(materialesDemo);

  List<MaterialItem> obtenerMateriales() {
    return _materiales;
  }

  void agregarMaterial(MaterialItem material) {
    final index = _materiales.indexWhere(
      (m) =>
          m.codigo.toLowerCase() == material.codigo.toLowerCase() &&
          m.ubicacion.toLowerCase() == material.ubicacion.toLowerCase(),
    );

    if (index >= 0) {
      _materiales[index].cantidad += material.cantidad;
    } else {
      _materiales.add(material);
    }
  }

  void descontarStock({
    required String codigo,
    required String ubicacion,
    required int cantidad,
  }) {
    final index = _materiales.indexWhere(
      (m) =>
          m.codigo.toLowerCase() == codigo.toLowerCase() &&
          m.ubicacion.toLowerCase() == ubicacion.toLowerCase(),
    );

    if (index >= 0) {
      _materiales[index].cantidad -= cantidad;

      if (_materiales[index].cantidad <= 0) {
        _materiales.removeAt(index);
      }
    }
  }

  List<String> obtenerFamilias() {
    final familias = _materiales.map((m) => m.familia).toSet().toList();
    familias.sort();
    return ['Todas', ...familias];
  }
}