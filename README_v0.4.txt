TRICON WMS v0.4 - Versión para reemplazo

Incluye:
- Maestro de Materiales
- Maestro de Ubicaciones
- Recepción con material y ubicación existentes
- Stock por ubicación
- Despacho
- Movimientos
- Remitos PDF
- Carga masiva desde Excel .xlsx
- Exportación a Excel .xlsx de stock, movimientos, materiales y ubicaciones

IMPORTANTE:
Agregar estas dependencias en pubspec.yaml:

  pdf: ^3.11.1
  printing: ^5.13.4
  excel: ^4.0.6
  file_picker: ^8.1.2

Después ejecutar:
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat run -d chrome

Nota:
Esta versión guarda datos en memoria. Sirve para pruebas funcionales y validación de carga/exportación. Para uso web permanente, el próximo paso es Supabase/PostgreSQL.
