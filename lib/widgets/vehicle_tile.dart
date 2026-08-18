import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Renders a single vehicle as a rounded, colored bar with a little arrow
/// showing which way it drives, and shakes briefly when the player taps it
/// while it's still blocked.
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

  IconData get _arrowIcon {
    final v = widget.vehicle;
    if (v.orientation == VehicleOrientation.horizontal) {
      return v.direction == 1 ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
    } else {
      return v.direction == 1 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final horizontal = v.orientation == VehicleOrientation.horizontal;
    final width = horizontal ? widget.cellSize * v.length : widget.cellSize;
    final height = horizontal ? widget.cellSize : widget.cellSize * v.length;
    const margin = 3.0;

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
          width: width - margin * 2,
          height: height - margin * 2,
          margin: const EdgeInsets.all(margin),
          decoration: BoxDecoration(
            color: v.color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
                ),
              ],
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
            ),
          child: Align(
            alignment: horizontal
            ? (v.direction == 1 ? Alignment.centerRight : Alignment.centerLeft)
            : (v.direction == 1 ? Alignment.bottomCenter : Alignment.topCenter),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(_arrowIcon, color: Colors.white, size: widget.cellSize * 0.32),
              ),
            ),
          ),
        ),
      );
  }
}
