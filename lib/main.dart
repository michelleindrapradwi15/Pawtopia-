import 'package:flutter/material.dart';
import 'splash_page.dart';

const Color kNavy = Color(0xFF1B3A6B);
const Color kCream = Color(0xFFFDF3E7);
const Color kPawLight = Color(0xFFEADCC4);

void main() => runApp(const PawtopiaApp());

class PawtopiaApp extends StatelessWidget {
  const PawtopiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawtopia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: kCream),
      builder: (context, child) => Container(
        color: const Color(0xFFE9DDCD),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRect(child: child),
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

/// Kanvas desain: semua ukuran mengikuti frame desain 390 x 844.
/// builder menerima s (skala lebar) dan h (tinggi kanvas).
/// Kalau layar lebih pendek dari desain, halaman bisa di-scroll.
class DesignCanvas extends StatelessWidget {
  final Widget Function(double s, double h) builder;
  const DesignCanvas({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxWidth / 390;
        final h = c.maxHeight > 844 * s ? c.maxHeight : 844 * s;
        return SingleChildScrollView(
          child: SizedBox(
            width: c.maxWidth,
            height: h,
            child: builder(s, h),
          ),
        );
      },
    );
  }
}

/// Logo cakar (4 jari + bantalan) digambar dengan kode.
class PawLogo extends StatelessWidget {
  final double width;
  final Color color;
  final double angle;
  const PawLogo({
    super.key,
    required this.width,
    this.color = kNavy,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(width, width * 0.9),
        painter: _PawPainter(color),
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  final Color color;
  _PawPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    void toe(double cx, double cy, double tw, double th, double rot) {
      canvas.save();
      canvas.translate(cx * w, cy * h);
      canvas.rotate(rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: tw * w, height: th * h),
        paint,
      );
      canvas.restore();
    }

    toe(0.12, 0.45, 0.21, 0.31, -0.44);
    toe(0.35, 0.17, 0.20, 0.35, -0.14);
    toe(0.65, 0.17, 0.20, 0.35, 0.14);
    toe(0.88, 0.45, 0.21, 0.31, 0.44);

    final pad = Path()
      ..moveTo(0.50 * w, 0.47 * h)
      ..cubicTo(0.70 * w, 0.47 * h, 0.84 * w, 0.60 * h, 0.82 * w, 0.78 * h)
      ..cubicTo(0.80 * w, 0.93 * h, 0.66 * w, h, 0.50 * w, h)
      ..cubicTo(0.34 * w, h, 0.20 * w, 0.93 * h, 0.18 * w, 0.78 * h)
      ..cubicTo(0.16 * w, 0.60 * h, 0.30 * w, 0.47 * h, 0.50 * w, 0.47 * h)
      ..close();
    canvas.drawPath(pad, paint);
  }

  @override
  bool shouldRepaint(covariant _PawPainter old) => old.color != color;
}

/// Cakar kecil dekorasi background. cx, cy = titik tengah (satuan desain).
Widget bgPaw(double s, double cx, double cy, double size, [double angle = 0]) {
  return Positioned(
    left: (cx - size / 2) * s,
    top: (cy - size * 0.45) * s,
    child: PawLogo(width: size * s, color: kPawLight, angle: angle),
  );
}
