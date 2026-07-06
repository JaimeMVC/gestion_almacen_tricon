import '../models/material_item.dart';
import '../models/stock_item.dart';
import '../models/ubicacion.dart';

final materialesDemo = [
  MaterialItem(codigo: 'FIL-001', nombre: 'Filtro de aceite', familia: 'Filtros'),
  MaterialItem(codigo: 'FIL-002', nombre: 'Filtro de combustible', familia: 'Filtros'),
  MaterialItem(codigo: 'CAB-001', nombre: 'Cable largo', familia: 'Cables'),
  MaterialItem(codigo: 'CAB-002', nombre: 'Cable corto', familia: 'Cables'),
  MaterialItem(codigo: 'SEN-001', nombre: 'Sensor de presión', familia: 'Sensores'),
];

final ubicacionesDemo = [
  Ubicacion(codigo: 'A.01.01', descripcion: 'Estantería A - Nivel 1'),
  Ubicacion(codigo: 'A.01.02', descripcion: 'Estantería A - Nivel 2'),
  Ubicacion(codigo: 'A.02.01', descripcion: 'Estantería A - Sector 2'),
  Ubicacion(codigo: 'B.02.01', descripcion: 'Estantería B - Nivel 1'),
  Ubicacion(codigo: 'B.02.02', descripcion: 'Estantería B - Nivel 2'),
  Ubicacion(codigo: 'C.01.01', descripcion: 'Estantería C - Nivel 1'),
];

final stockDemo = [
  StockItem(material: materialesDemo[0], ubicacion: 'A.01.01', cantidad: 12),
  StockItem(material: materialesDemo[0], ubicacion: 'A.01.02', cantidad: 5),
  StockItem(material: materialesDemo[1], ubicacion: 'A.02.01', cantidad: 8),
  StockItem(material: materialesDemo[2], ubicacion: 'B.02.01', cantidad: 5),
  StockItem(material: materialesDemo[3], ubicacion: 'B.02.02', cantidad: 20),
  StockItem(material: materialesDemo[4], ubicacion: 'C.01.01', cantidad: 6),
];
