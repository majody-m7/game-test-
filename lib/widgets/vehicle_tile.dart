import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Renders a single vehicle as a stylized top-down vehicle whose look
/// scales with its size: a 1-cell vehicle reads as a motorcycle, a 2-cell
/// vehicle as a sedan, and anything 3 cells or longer as a bus/truck.
/// Shakes briefly when the player taps it while it's still blocked.
class VehicleTile extends StatefulWidget {
  final Vehicle vehicle;
  final double cellSize;
  final int shakeSignal;
  final VoidCallback onTap;

  const VehicleTile({
    super.key,
    required this.vehicle,
    required this.cellSize,
    required this.shakeSignal,
    required this.onTap,
  });

  @override
  State<VehicleTile> createState() => _VehicleTileState();
}

class _VehicleTileState extends State<VehicleTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(VehicleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeSignal != oldWidget.shakeSignal) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final horizontal = v.orientation == VehicleOrientation.horizontal;
    final width = horizontal ? widget.cellSize * v.length : widget.cellSize;
    final height = horizontal ? widget.cellSize : widget.cellSize * v.length;
    const margin = 3.0;
    final tileWidth = width - margin * 2;
    final tileHeight = height - margin * 2;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final dx = horizontal ? _shakeAnim.value : 0.0;
        final dy = horizontal ? 0.0 : _shakeAnim.value;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: tileWidth,
          height: tileHeight,
          margin: const EdgeInsets.all(margin),
          child: CustomPaint(
            size: Size(tileWidth, tileHeight),
            painter: _VehiclePainter(
              color: v.color,
              horizontal: horizontal,
              forward: v.direction == 1,
              length: v.length,
            ),
          ),
        ),
      ),
    );
  }
}

enum _VehicleKind { bike, car, bus }

/// Paints a stylized top-down vehicle. The silhouette changes with how many
/// cells the vehicle occupies so the board reads as genuine mixed traffic
/// (motorcycles, sedans, buses/trucks) instead of same-shaped blocks in
/// different colors.
class _VehiclePainter extends CustomPainter {
  final Color color;
  final bool horizontal;
  final bool forward;
  final int length;

  _VehiclePainter({
    required this.color,
    required this.horizontal,
    required this.forward,
    required this.length,
  });

  _VehicleKind get _kind {
    if (length <= 1) return _VehicleKind.bike;
    if (length == 2) return _VehicleKind.car;
    return _VehicleKind.bus;
  }

  Color _shade(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Work in a "local" space where x runs along the vehicle's length and
    // y runs across its width, then rotate into place for vertical vehicles.
    double lenAxis, widAxis;
    if (horizontal) {
      lenAxis = size.width;
      widAxis = size.height;
    } else {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(1.5707963267948966); // 90 degrees
      canvas.translate(-size.height / 2, -size.width / 2);
      lenAxis = size.height;
      widAxis = size.width;
    }

    switch (_kind) {
      case _VehicleKind.bike:
        _paintBike(canvas, lenAxis, widAxis);
        break;
      case _VehicleKind.car:
        _paintCar(canvas, lenAxis, widAxis);
        break;
      case _VehicleKind.bus:
        _paintBus(canvas, lenAxis, widAxis);
        break;
    }

    canvas.restore();
  }

  void _paintBike(Canvas canvas, double lenAxis, double widAxis) {
    final midY = widAxis / 2;
    final bodyWidth = widAxis * 0.4;
    final bodyRect = Rect.fromCenter(
      center: Offset(lenAxis / 2, midY),
      width: lenAxis * 0.86,
      height: bodyWidth,
    );
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(bodyWidth * 0.5));

    canvas.drawRRect(
      bodyRRect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withOpacity(0.2),
    );

    final wheelPaint = Paint()..color = const Color(0xFF2B2B2B);
    final wheelR = widAxis * 0.16;
    canvas.drawCircle(Offset(lenAxis * 0.12, midY), wheelR, wheelPaint);
    canvas.drawCircle(Offset(lenAxis * 0.88, midY), wheelR, wheelPaint);
    final hubPaint = Paint()..color = const Color(0xFF6B6B6B);
    canvas.drawCircle(Offset(lenAxis * 0.12, midY), wheelR * 0.4, hubPaint);
    canvas.drawCircle(Offset(lenAxis * 0.88, midY), wheelR * 0.4, hubPaint);

    canvas.drawRRect(bodyRRect, Paint()..color = color);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final seatCenter = Offset(lenAxis * 0.5, midY);
    canvas.drawOval(
      Rect.fromCenter(center: seatCenter, width: lenAxis * 0.22, height: bodyWidth * 0.8),
      Paint()..color = _shade(color, -0.28),
    );

    final frontHandleX = forward ? lenAxis * 0.82 : lenAxis * 0.18;
    canvas.drawLine(
      Offset(frontHandleX, midY - widAxis * 0.26),
      Offset(frontHandleX, midY + widAxis * 0.26),
      Paint()
        ..color = const Color(0xFF2B2B2B)
        ..strokeWidth = widAxis * 0.06
        ..strokeCap = StrokeCap.round,
    );

    final frontTip = forward ? lenAxis * 0.94 : lenAxis * 0.06;
    final backTip = forward ? lenAxis * 0.06 : lenAxis * 0.94;
    canvas.drawCircle(Offset(frontTip, midY), widAxis * 0.1, Paint()..color = const Color(0xFFFFF3B0));
    canvas.drawCircle(Offset(backTip, midY), widAxis * 0.08, Paint()..color = const Color(0xFFE63946));
  }

  void _paintCar(Canvas canvas, double lenAxis, double widAxis) {
    final bodyRect = Rect.fromLTWH(0, 0, lenAxis, widAxis);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(widAxis * 0.32));

    canvas.drawRRect(
      bodyRRect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withOpacity(0.22),
    );

    canvas.drawRRect(bodyRRect, Paint()..color = color);

    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final wheelPaint = Paint()..color = const Color(0xFF2B2B2B);
    final wheelR = widAxis * 0.13;
    for (final wx in [lenAxis * 0.26, lenAxis * 0.74]) {
      canvas.drawCircle(Offset(wx, 0), wheelR, wheelPaint);
      canvas.drawCircle(Offset(wx, widAxis), wheelR, wheelPaint);
    }

    final cabinCenter = forward ? lenAxis * 0.60 : lenAxis * 0.40;
    final cabinRect = Rect.fromCenter(
      center: Offset(cabinCenter, widAxis / 2),
      width: lenAxis * 0.42,
      height: widAxis * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabinRect, Radius.circular(widAxis * 0.18)),
      Paint()..color = _shade(color, -0.22).withOpacity(0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cabinRect.deflate(widAxis * 0.08),
        Radius.circular(widAxis * 0.12),
      ),
      Paint()..color = Colors.white.withOpacity(0.18),
    );

    _paintLights(canvas, lenAxis, widAxis, lightScale: 1.0);
  }

  void _paintBus(Canvas canvas, double lenAxis, double widAxis) {
    final bodyRect = Rect.fromLTWH(0, 0, lenAxis, widAxis);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(widAxis * 0.2));

    canvas.drawRRect(
      bodyRRect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withOpacity(0.24),
    );

    canvas.drawRRect(bodyRRect, Paint()..color = color);

    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final wheelPaint = Paint()..color = const Color(0xFF2B2B2B);
    final wheelR = widAxis * 0.12;
    for (final wx in [lenAxis * 0.18, lenAxis * 0.5, lenAxis * 0.82]) {
      canvas.drawCircle(Offset(wx, 0), wheelR, wheelPaint);
      canvas.drawCircle(Offset(wx, widAxis), wheelR, wheelPaint);
    }

    final frontX = forward ? lenAxis - lenAxis * 0.14 : lenAxis * 0.14;
    final cabRect = Rect.fromCenter(
      center: Offset(frontX, widAxis / 2),
      width: lenAxis * 0.16,
      height: widAxis * 0.7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabRect, Radius.circular(widAxis * 0.14)),
      Paint()..color = _shade(color, -0.26).withOpacity(0.9),
    );

    final windowPaint = Paint()..color = _shade(color, -0.16).withOpacity(0.85);
    final glintPaint = Paint()..color = Colors.white.withOpacity(0.2);
    const windowCount = 3;
    final spanStart = lenAxis * 0.28;
    final spanEnd = lenAxis * 0.86;
    final span = spanEnd - spanStart;
    for (var i = 0; i < windowCount; i++) {
      final wx = spanStart + span * (i + 0.5) / windowCount;
      if ((wx - frontX).abs() < lenAxis * 0.1) continue;
      final winRect = Rect.fromCenter(
        center: Offset(wx, widAxis / 2),
        width: (span / windowCount) * 0.6,
        height: widAxis * 0.5,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(winRect, Radius.circular(widAxis * 0.08)), windowPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(winRect.deflate(widAxis * 0.05), Radius.circular(widAxis * 0.05)),
        glintPaint,
      );
    }

    _paintLights(canvas, lenAxis, widAxis, lightScale: 1.15);
  }

  void _paintLights(Canvas canvas, double lenAxis, double widAxis, {required double lightScale}) {
    final lightW = widAxis * 0.16 * lightScale;
    final lightH = widAxis * 0.22 * lightScale;
    final frontX = forward ? lenAxis - lenAxis * 0.05 : lenAxis * 0.05;
    final backX = forward ? lenAxis * 0.05 : lenAxis - lenAxis * 0.05;

    final headlightPaint = Paint()..color = const Color(0xFFFFF3B0);
    final taillightPaint = Paint()..color = const Color(0xFFE63946);

    for (final side in [widAxis * 0.2, widAxis * 0.8]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(frontX, side), width: lightW, height: lightH),
          Radius.circular(lightW * 0.4),
        ),
        headlightPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(backX, side), width: lightW * 0.8, height: lightH * 0.8),
          Radius.circular(lightW * 0.3),
        ),
        taillightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VehiclePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.horizontal != horizontal ||
      oldDelegate.forward != forward ||
      oldDelegate.length != length;
}

