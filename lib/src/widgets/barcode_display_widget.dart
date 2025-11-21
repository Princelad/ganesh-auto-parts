import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../services/barcode_print_service.dart';

/// Widget to display a barcode for an item SKU
///
/// Supports multiple barcode formats:
/// - Code 128 (default, most versatile)
/// - EAN-13 (for 13-digit codes)
/// - UPC-A (for 12-digit codes)
/// - QR Code (for any text)
class BarcodeDisplayWidget extends StatelessWidget {
  final String data;
  final double width;
  final double height;
  final bool showData;

  const BarcodeDisplayWidget({
    super.key,
    required this.data,
    this.width = 200,
    this.height = 80,
    this.showData = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: data,
            width: width,
            height: height,
            drawText: showData,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Dialog to show barcode in a larger view
class BarcodeDialogWidget extends StatelessWidget {
  final String sku;
  final String itemName;
  final String? company;
  final double? price;

  const BarcodeDialogWidget({
    super.key,
    required this.sku,
    required this.itemName,
    this.company,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              itemName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            BarcodeDisplayWidget(data: sku, width: 300, height: 100),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await BarcodePrintService.printBarcode(
                        sku: sku,
                        itemName: itemName,
                        company: company,
                        price: price,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Print error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
