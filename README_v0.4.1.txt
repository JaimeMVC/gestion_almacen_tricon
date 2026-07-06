TRICON WMS v0.4.1 - Carga masiva y exportaciones Excel

Contenido:
- lib/ completa para reemplazar.
- Carga masiva con previsualización y validación.
- Plantillas Excel para materiales, ubicaciones y stock inicial.
- Exportaciones Excel de stock, movimientos, materiales y ubicaciones.
- Corrección de compatibilidad: usar excel ^2.1.0.

Dependencias requeridas en pubspec.yaml:
  pdf: ^3.11.1
  printing: ^5.13.4
  excel: ^2.1.0
  file_picker: ^8.1.2

Comandos:
  C:\src\flutter\bin\flutter.bat pub get
  C:\src\flutter\bin\flutter.bat run -d chrome

IMPORTANTE:
Esta versión guarda datos en memoria. Sirve para validar carga masiva, exportaciones y operación web.
El próximo paso para uso real permanente es Supabase/PostgreSQL.
