import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/documento.dart';

class DocumentoPdf {
  static Future<void> imprimir(Documento documento) async {
    final pdf = pw.Document();
    final moneda = documento.items.isEmpty ? '' : documento.items.first.moneda;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        header: (_) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TRICON WMS', style: pw.TextStyle(fontSize: 23, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Warehouse Management System', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(documento.numero, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(documento.tipoLegible.toUpperCase()),
                    pw.Text('Estado: ${documento.estado}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.2),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ),
        build: (_) => [
          pw.SizedBox(height: 8),
          _datos(documento),
          pw.SizedBox(height: 20),
          pw.Text('Materiales', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: .5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(5),
            headers: const ['Código', 'Descripción', 'Cantidad', 'Unidad', 'Ubicación', 'Equipo', 'Costo unit.', 'Total'],
            data: documento.items.map((i) => [
              i.materialCodigo,
              i.materialNombre,
              _numero(i.cantidad),
              i.unidad,
              i.ubicacionDestino.isNotEmpty ? '${i.ubicacionOrigen} → ${i.ubicacionDestino}' : i.ubicacionOrigen,
              i.equipoEtiqueta.isEmpty ? '-' : i.equipoEtiqueta,
              '${i.moneda} ${_numero(i.costoUnitario)}',
              '${i.moneda} ${_numero(i.total)}',
            ]).toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Valor total: $moneda ${_numero(documento.total)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Observaciones', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Container(
            width: double.infinity,
            constraints: const pw.BoxConstraints(minHeight: 55),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500)),
            child: pw.Text(documento.observacion.isEmpty ? '-' : documento.observacion),
          ),
          pw.SizedBox(height: 55),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [_firma('Firma responsable'), _firma('Firma recepción')],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: '${documento.numero}.pdf');
  }

  static pw.Widget _datos(Documento d) {
    final destino = d.almacenDestino.isNotEmpty ? d.almacenDestino : d.destinoExterno;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: .5),
      columnWidths: const {0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(2.3), 2: pw.FlexColumnWidth(1.2), 3: pw.FlexColumnWidth(2.3)},
      children: [
        _fila4('Fecha', _fecha(d.fecha), 'Responsable', d.responsable),
        _fila4('Proyecto', d.proyecto.isEmpty ? '-' : d.proyecto, 'Proveedor', d.proveedor.isEmpty ? '-' : d.proveedor),
        _fila4('Almacén origen', d.almacenOrigen.isEmpty ? '-' : d.almacenOrigen, 'Destino', destino.isEmpty ? '-' : destino),
      ],
    );
  }

  static pw.TableRow _fila4(String a, String b, String c, String d) => pw.TableRow(children: [_th(a), _td(b), _th(c), _td(d)]);
  static pw.Widget _th(String text) => pw.Container(color: PdfColors.grey200, padding: const pw.EdgeInsets.all(6), child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)));
  static pw.Widget _td(String text) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)));
  static pw.Widget _firma(String text) => pw.Column(children: [pw.Container(width: 180, height: 1, color: PdfColors.black), pw.SizedBox(height: 5), pw.Text(text, style: const pw.TextStyle(fontSize: 9))]);
  static String _fecha(DateTime f) => '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  static String _numero(num n) => n.toStringAsFixed(n % 1 == 0 ? 0 : 2);
}
