import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'prediction_model.dart';
import 'data.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Prediction? currentPrediction;
  double _opacity = 0.0;
  StreamSubscription? _subscription;
  DateTime _lastShakeTime = DateTime.now();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _subscription = accelerometerEventStream().listen((event) {
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > 45) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inSeconds > 1) {
          _lastShakeTime = now;
          shakeBall();
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  void shakeBall() {
    _animController.forward(from: 0.0);
    setState(() {
      _opacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        currentPrediction =
            defaultPredictions[Random().nextInt(defaultPredictions.length)];
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cosmic Oracle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/stars.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: shakeBall,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final double offset =
                        sin(_animController.value * 2 * pi * 3) * 10;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/magic_8_ball.png',
                        width: 300,
                        height: 300,
                      ),
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF101020,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[900]!,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: _opacity,
                              child: _buildPredictionContent(),
                            ),

                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Shake your phone or tap the ball!",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionContent() {
    if (currentPrediction == null) {
      return const Text(
        "8",
        style: TextStyle(fontSize: 80, color: Colors.white12),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: CustomPaint(
        painter: TrianglePainter(color: currentPrediction!.color),
        child: Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          child: Text(
            currentPrediction!.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
