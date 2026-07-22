import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/deep_link_service.dart';
import '../../../features/partners/providers/invite_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  MobileScannerController? _scannerController;
  bool _scanned = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetected(BarcodeCapture capture) {
    if (_scanned || _isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawData = barcode.rawValue;
      if (rawData == null || rawData.isEmpty) continue;

      _scanned = true;
      _processScan(rawData);
      break;
    }
  }

  void _processScan(String rawData) {
    setState(() => _isProcessing = true);

    final deepLinkService = DeepLinkService.instance;
    final parsedUri = deepLinkService.parseScannedQrData(rawData);

    if (parsedUri != null) {
      final params = deepLinkService.extractInviteParams(parsedUri);
      if (params != null && params['token'] != null && params['token']!.isNotEmpty) {
        final token = params['token']!;
        final businessId = params['businessId'] ?? '';

        ref.read(inviteProvider.notifier).validateToken(token);

        if (mounted) {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            '/invite/accept',
            arguments: {
              'token': token,
              'businessId': businessId,
            },
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      _scanned = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid QR code. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Invite QR'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _scannerController?.torchEnabled == true
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
            ),
            onPressed: () => _scannerController?.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onDetected,
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -1,
                    left: -1,
                    child: _cornerDecoration(colorScheme.primary, isTopLeft: true),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: _cornerDecoration(colorScheme.primary, isTopRight: true),
                  ),
                  Positioned(
                    bottom: -1,
                    left: -1,
                    child: _cornerDecoration(colorScheme.primary, isBottomLeft: true),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: _cornerDecoration(colorScheme.primary, isBottomRight: true),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isProcessing)
                      const CircularProgressIndicator(color: Colors.white)
                    else ...[
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Point your camera at a Partner Ledger Pro QR code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The invite link will be detected automatically',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerDecoration(Color color, {bool isTopLeft = false, bool isTopRight = false, bool isBottomLeft = false, bool isBottomRight = false}) {
    return CustomPaint(
      size: const Size(30, 30),
      painter: _CornerPainter(
        color: color,
        isTopLeft: isTopLeft,
        isTopRight: isTopRight,
        isBottomLeft: isBottomLeft,
        isBottomRight: isBottomRight,
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  _CornerPainter({
    required this.color,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (isTopLeft) {
      path.moveTo(0, size.height * 0.7);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.7, 0);
    } else if (isTopRight) {
      path.moveTo(size.width * 0.3, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height * 0.7);
    } else if (isBottomLeft) {
      path.moveTo(0, size.height * 0.3);
      path.lineTo(0, size.height);
      path.lineTo(size.width * 0.7, size.height);
    } else if (isBottomRight) {
      path.moveTo(size.width * 0.3, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height * 0.3);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
