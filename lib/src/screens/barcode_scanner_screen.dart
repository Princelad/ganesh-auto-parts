import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Screen for scanning barcodes using device camera
///
/// Supports various barcode formats including:
/// - Code 128, Code 39, Code 93
/// - EAN-8, EAN-13
/// - UPC-A, UPC-E
/// - QR codes
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() => _isProcessing = true);

      // Return the scanned code
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(controller: _controller, onDetect: _onBarcodeDetect),

          // Scanning overlay with cutout
          CustomPaint(painter: ScannerOverlayPainter(), child: Container()),

          // Instructions at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Position barcode within the frame',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scanning will happen automatically',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay with transparent cutout
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    // Define the cutout rectangle (scanning area)
    final cutoutWidth = size.width * 0.7;
    final cutoutHeight = size.height * 0.3;
    final cutoutLeft = (size.width - cutoutWidth) / 2;
    final cutoutTop = (size.height - cutoutHeight) / 2;

    final cutoutRect = Rect.fromLTWH(
      cutoutLeft,
      cutoutTop,
      cutoutWidth,
      cutoutHeight,
    );

    // Draw the overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, paint);

    // Draw border around cutout
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)),
      borderPaint,
    );

    // Draw corner brackets
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cornerLength),
      Offset(cutoutLeft, cutoutTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop),
      Offset(cutoutLeft + cornerLength, cutoutTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cutoutLeft + cutoutWidth - cornerLength, cutoutTop),
      Offset(cutoutLeft + cutoutWidth, cutoutTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft + cutoutWidth, cutoutTop),
      Offset(cutoutLeft + cutoutWidth, cutoutTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cutoutHeight - cornerLength),
      Offset(cutoutLeft, cutoutTop + cutoutHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cutoutHeight),
      Offset(cutoutLeft + cornerLength, cutoutTop + cutoutHeight),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cutoutLeft + cutoutWidth - cornerLength, cutoutTop + cutoutHeight),
      Offset(cutoutLeft + cutoutWidth, cutoutTop + cutoutHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft + cutoutWidth, cutoutTop + cutoutHeight - cornerLength),
      Offset(cutoutLeft + cutoutWidth, cutoutTop + cutoutHeight),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
