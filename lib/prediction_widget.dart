import 'dart:math';
import 'package:flutter/material.dart';
import 'prediction_model.dart';

class PredictionWidget extends StatefulWidget {
  final Prediction? prediction;

  const PredictionWidget({super.key, this.prediction});

  @override
  State<PredictionWidget> createState() => _PredictionWidgetState();
}

class _PredictionWidgetState extends State<PredictionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shapeController;

  @override
  void initState() {
    super.initState();
    _shapeController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shapeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prediction == null) {
      return const Text(
        "8",
        style: TextStyle(fontSize: 80, color: Colors.white),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimatedBuilder(
        animation: _shapeController,
        builder: (context, child) {
          final t = _shapeController.value * 2 * pi;
          return CustomPaint(
            painter: RhombusPainter(
              color: widget.prediction!.color,
              animationValue: _shapeController.value,
            ),
            child: Container(
              width: 130,
              height: 130,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(32),
              child: Transform.scale(
                scale: 0.95 + 0.05 * sin(t),
                child: Transform.rotate(
                  angle: 0.05 * cos(t),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(
                        widget.prediction!.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black54,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RhombusPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  RhombusPainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 4D spin effect: distort the rhombus vertices based on sine waves
    final t = animationValue * 2 * pi;

    path.moveTo(cx + sin(t) * 8, 0.0 + cos(t * 2) * 8); // Top
    path.lineTo(w + sin(t * 2) * 8, cy + cos(t) * 8); // Right
    path.lineTo(cx + sin(t * 3) * 8, h + cos(t * 2) * 8); // Bottom
    path.lineTo(0.0 + sin(t * 2) * 8, cy + cos(t * 3) * 8); // Left
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant RhombusPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color;
}
