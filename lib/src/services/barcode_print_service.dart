import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:barcode/barcode.dart';

/// Service for printing barcode labels
class BarcodePrintService {
  /// Print a single barcode label
  static Future<void> printBarcode({
    required String sku,
    required String itemName,
    String? company,
    double? price,
  }) async {
    final pdf = pw.Document();

    // Create barcode
    final barcode = Barcode.code128();
    final svgBarcode = barcode.toSvg(sku, width: 200, height: 80);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6, // Small label format
        build: (context) {
          return pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Item name
                  pw.Text(
                    itemName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (company != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      company,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                  pw.SizedBox(height: 16),
                  // Barcode
                  pw.SvgImage(svg: svgBarcode, width: 200, height: 80),
                  pw.SizedBox(height: 8),
                  // SKU text
                  pw.Text(
                    sku,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (price != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Rs. ${price.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    // Print or share the PDF
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /// Print multiple barcode labels in a grid (3x6 = 18 labels per A4 page)
  static Future<void> printBarcodeSheet({
    required List<Map<String, dynamic>> items,
    int columns = 3,
    int rows = 6,
  }) async {
    final pdf = pw.Document();

    // Split items into pages
    final itemsPerPage = columns * rows;
    for (
      int pageStart = 0;
      pageStart < items.length;
      pageStart += itemsPerPage
    ) {
      final pageItems = items.skip(pageStart).take(itemsPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              children: [
                for (int rowIndex = 0; rowIndex < rows; rowIndex++)
                  pw.Expanded(
                    child: pw.Row(
                      children: [
                        for (int colIndex = 0; colIndex < columns; colIndex++)
                          pw.Expanded(
                            child: _buildLabelCell(
                              pageItems,
                              rowIndex * columns + colIndex,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    // Print or share the PDF
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /// Build a single label cell for the grid
  static pw.Widget _buildLabelCell(
    List<Map<String, dynamic>> items,
    int index,
  ) {
    if (index >= items.length) {
      return pw.Container(); // Empty cell
    }

    final item = items[index];
    final sku = item['sku'] as String;
    final name = item['name'] as String;
    final company = item['company'] as String?;
    final price = item['price'] as double?;

    final barcode = Barcode.code128();
    final svgBarcode = barcode.toSvg(sku, width: 150, height: 50);

    return pw.Container(
      margin: const pw.EdgeInsets.all(5),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          // Item name (truncated)
          pw.Text(
            name.length > 25 ? '${name.substring(0, 25)}...' : name,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
          ),
          if (company != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              company,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center,
              maxLines: 1,
            ),
          ],
          pw.SizedBox(height: 4),
          // Barcode
          pw.SvgImage(svg: svgBarcode, width: 150, height: 50),
          pw.SizedBox(height: 2),
          // SKU
          pw.Text(
            sku,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          if (price != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Rs. ${price.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Preview barcode before printing
  static Future<void> previewBarcode({
    required String sku,
    required String itemName,
    String? company,
    double? price,
  }) async {
    final pdf = pw.Document();

    final barcode = Barcode.code128();
    final svgBarcode = barcode.toSvg(sku, width: 200, height: 80);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (context) {
          return pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    itemName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (company != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      company,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                  pw.SizedBox(height: 16),
                  pw.SvgImage(svg: svgBarcode, width: 200, height: 80),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    sku,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (price != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Rs. ${price.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    // Show print preview
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Barcode_$sku.pdf',
    );
  }
}
