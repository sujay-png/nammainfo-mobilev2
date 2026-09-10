import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/router.dart';

/// "Scan QR" tab — animated scan frame + live camera feed, matching the
/// Figma design's QR scanner tab. On a recognised Namma Info link it
/// routes straight into the public card screen.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    final raw = barcodes.isEmpty ? null : barcodes.first.rawValue;
    if (raw == null) return;

    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return;
    }

    final route = routeForExternalUri(uri);
    if (route == null) return;

    _handled = true;
    context.push(route).then((_) => _handled = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(color: Colors.black.withValues(alpha: 0.35)),
          Center(
            child: _ScanFrame(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Text(
              'Point your camera at a Namma Info QR code',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}


class _ScanFrame extends StatefulWidget {
  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 240.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ...[
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ].map((a) => _CornerBracket(alignment: a)),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Positioned(
              top: _controller.value * (size - 2),
              left: 0,
              right: 0,
              child: Container(height: 2, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final Alignment alignment;
  const _CornerBracket({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
