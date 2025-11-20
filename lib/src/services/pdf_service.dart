import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/customer.dart';
import '../models/item.dart';

/// Service for generating PDF invoices
class PdfService {
  /// Generate PDF for an invoice
  static Future<Uint8List> generateInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required List<Item> allItems,
    Customer? customer,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    // Get item details for each invoice item
    final itemDetails = items.map((invoiceItem) {
      final item = allItems.firstWhere(
        (i) => i.id == invoiceItem.itemId,
        orElse: () => Item(
          id: 0,
          sku: 'N/A',
          name: 'Unknown Item',
          company: '',
          unitPrice: 0,
          stock: 0,
          reorderLevel: 0,
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      return {
        'name': item.name,
        'company': item.company,
        'sku': item.sku,
        'qty': invoiceItem.qty,
        'unitPrice': invoiceItem.unitPrice,
        'lineTotal': invoiceItem.lineTotal,
      };
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(),
            pw.SizedBox(height: 20),

            // Invoice Details
            _buildInvoiceDetails(invoice, customer, dateFormat),
            pw.SizedBox(height: 20),

            // Items Table
            _buildItemsTable(itemDetails, currencyFormat),
            pw.SizedBox(height: 20),

            // Totals
            _buildTotals(invoice, currencyFormat),
            pw.SizedBox(height: 30),

            // Payment Status
            _buildPaymentStatus(invoice, currencyFormat),
            pw.SizedBox(height: 30),

            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Build PDF header with company name
  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GANESH AUTO PARTS',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Auto Parts & Accessories',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Build invoice details section
  static pw.Widget _buildInvoiceDetails(
    Invoice invoice,
    Customer? customer,
    DateFormat dateFormat,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Customer Details
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                customer?.name ?? 'Walk-in Customer',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (customer != null) ...[
                pw.SizedBox(height: 3),
                if (customer.phone.isNotEmpty)
                  pw.Text(
                    'Phone: ${customer.phone}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                if (customer.address != null && customer.address!.isNotEmpty)
                  pw.Text(
                    customer.address!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
              ],
            ],
          ),
        ),

        // Invoice Details
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Invoice No: ${invoice.invoiceNo}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Date: ${dateFormat.format(DateTime.fromMillisecondsSinceEpoch(invoice.date))}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(
    List<Map<String, dynamic>> items,
    NumberFormat currencyFormat,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1), // Sr. No
        1: const pw.FlexColumnWidth(3), // Item Name
        2: const pw.FlexColumnWidth(2), // Company
        3: const pw.FlexColumnWidth(2), // SKU
        4: const pw.FlexColumnWidth(1.5), // Qty
        5: const pw.FlexColumnWidth(2), // Rate
        6: const pw.FlexColumnWidth(2), // Amount
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableCell('Sr.', isHeader: true),
            _buildTableCell('Item Name', isHeader: true),
            _buildTableCell('Company', isHeader: true),
            _buildTableCell('SKU', isHeader: true),
            _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
            _buildTableCell('Rate', isHeader: true, align: pw.TextAlign.right),
            _buildTableCell(
              'Amount',
              isHeader: true,
              align: pw.TextAlign.right,
            ),
          ],
        ),
        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell('${index + 1}', align: pw.TextAlign.center),
              _buildTableCell(item['name'] as String),
              _buildTableCell(item['company'] as String),
              _buildTableCell(item['sku'] as String),
              _buildTableCell('${item['qty']}', align: pw.TextAlign.center),
              _buildTableCell(
                currencyFormat.format(item['unitPrice']),
                align: pw.TextAlign.right,
              ),
              _buildTableCell(
                currencyFormat.format(item['lineTotal']),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  /// Build totals section
  static pw.Widget _buildTotals(Invoice invoice, NumberFormat currencyFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal:', currencyFormat.format(invoice.total)),
              pw.Divider(height: 10, thickness: 1),
              _buildTotalRow(
                'Total Amount:',
                currencyFormat.format(invoice.total),
                isBold: true,
                fontSize: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build total row
  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 11,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Build payment status section
  static pw.Widget _buildPaymentStatus(
    Invoice invoice,
    NumberFormat currencyFormat,
  ) {
    final balance = invoice.total - invoice.paid;
    final isPaid = balance <= 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: isPaid ? PdfColors.green50 : PdfColors.orange50,
        border: pw.Border.all(
          color: isPaid ? PdfColors.green : PdfColors.orange,
          width: 1,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Payment Status:',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                isPaid ? 'PAID' : 'UNPAID',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: isPaid ? PdfColors.green900 : PdfColors.orange900,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Amount Paid: ${currencyFormat.format(invoice.paid)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (balance > 0) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  'Balance Due: ${currencyFormat.format(balance)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build footer
  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Ganesh Auto Parts - Quality Auto Parts & Accessories',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
