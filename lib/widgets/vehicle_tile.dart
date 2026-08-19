import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Renders a single vehicle as a stylized top-down car: a rounded body,
/// a windshield/cabin band, headlights at the front, taillights at the
/// back, and wheels peeking out from the long sides. Shakes briefly when
/// the player taps it while it's still blocked.
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
            painter: _CarPainter(
              color: v.color,
              horizontal: horizontal,
              forward: v.direction == 1,
              isLong: v.length >= 3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a stylized top-down vehicle - rounded body, cabin/windshield
/// band, headlights, taillights, and wheels - so each piece on the board
/// reads clearly as "a car" without relying on licensed artwork or photos.
class _CarPainter extends CustomPainter {
  final Color color;
  final bool horizontal;
  final bool forward;
  final bool isLong;

  _CarPainter({
    required this.color,
    required this.horizontal,
    required this.forward,
    required this.isLong,
  });

  Color _shade(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Work in a "local" space where x runs along the vehicle's length and
    // y runs across its width, then rotate into place for vertical cars.
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

    final bodyRect = Rect.fromLTWH(0, 0, lenAxis, widAxis);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(widAxis * 0.32));

    // Drop shadow.
    canvas.drawRRect(
      bodyRRect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withOpacity(0.22),
    );

    // Body.
    canvas.drawRRect(bodyRRect, Paint()..color = color);

    // Body outline for a bit of pop against similarly-colored neighbors.
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Wheels along the two long edges.
    final wheelPaint = Paint()..color = const Color(0xFF2B2B2B);
    final wheelR = widAxis * 0.13;
    final wheelPositions = isLong
        ? [lenAxis * 0.2, lenAxis * 0.5, lenAxis * 0.8]
        : [lenAxis * 0.26, lenAxis * 0.74];
    for (final wx in wheelPositions) {
      canvas.drawCircle(Offset(wx, 0), wheelR, wheelPaint);
      canvas.drawCircle(Offset(wx, widAxis), wheelR, wheelPaint);
    }

    // Cabin / windshield band, offset toward the front so the car reads as
    // "driving" the way it will exit.
    final cabinCenter = forward ? lenAxis * 0.60 : lenAxis * 0.40;
    final cabinWidth = lenAxis * (isLong ? 0.34 : 0.42);
    final cabinRect = Rect.fromCenter(
      center: Offset(cabinCenter, widAxis / 2),
      width: cabinWidth,
      height: widAxis * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cabinRect, Radius.circular(widAxis * 0.18)),
      Paint()..color = _shade(color, -0.22).withOpacity(0.85),
    );
    // Windshield glass glint.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cabinRect.deflate(widAxis * 0.08),
        Radius.circular(widAxis * 0.12),
      ),
      Paint()..color = Colors.white.withOpacity(0.18),
    );

    // Headlights at the front edge, taillights at the back edge.
    final lightW = widAxis * 0.16;
    final lightH = widAxis * 0.22;
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

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.horizontal != horizontal ||
      oldDelegate.forward != forward ||
      oldDelegate.isLong != isLong;
}
