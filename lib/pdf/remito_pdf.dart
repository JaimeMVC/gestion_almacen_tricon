import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/remito.dart';

class RemitoPdf {
  static Future<void> imprimir(Remito remito) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TRICON WMS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Remito de salida de material'),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Remito N°: ${remito.numero}'),
                  pw.Text('Fecha: ${_formatearFecha(remito.fecha)}'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Datos del despacho', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600),
                columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(4)},
                children: [
                  _fila('Destino', remito.destino),
                  _fila('Despachado por', remito.despachadoPor),
                  _fila('Ubicación origen', remito.ubicacionOrigen),
                  _fila('Observaciones', remito.observacion.isEmpty ? '-' : remito.observacion),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('Material despachado', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [_celdaHeader('Código'), _celdaHeader('Descripción'), _celdaHeader('Cantidad'), _celdaHeader('Ubicación')],
                  ),
                  pw.TableRow(
                    children: [_celda(remito.codigoMaterial), _celda(remito.nombreMaterial), _celda(remito.cantidad.toString()), _celda(remito.ubicacionOrigen)],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [_firma('Firma despacho'), _firma('Firma recepción')],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.TableRow _fila(String titulo, String valor) {
    return pw.TableRow(children: [_celdaHeader(titulo), _celda(valor)]);
  }

  static pw.Widget _celdaHeader(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(texto, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _celda(String texto) {
    return pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(texto));
  }

  static pw.Widget _firma(String titulo) {
    return pw.Column(
      children: [
        pw.Container(width: 180, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 6),
        pw.Text(titulo),
      ],
    );
  }

  static String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio $hora:$minuto';
  }
}
