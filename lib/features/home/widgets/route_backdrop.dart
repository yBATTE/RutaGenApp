import 'package:flutter/material.dart';

/// Decorative local vector art. It never intercepts gestures or semantics.
class RouteBackdrop extends StatelessWidget {
  const RouteBackdrop({super.key, this.card = false});

  final bool card;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(painter: _RoutePainter(card: card)),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.card});

  final bool card;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width, size.height);

    final sky = Paint()
      ..shader = const RadialGradient(
        center: Alignment(.7, -.3),
        radius: .9,
        colors: [Color(0xFF176DD6), Color(0xFF063A87), Color(0xFF032A46)],
      ).createShader(const Rect.fromLTWH(0, 0, 1, 1));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), sky);

    if (!card) {
      // The header has its own abstract treatment so the road remains
      // exclusive to the points card.
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1, 1),
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(.85, -.75),
            radius: .85,
            colors: [
              Color(0x5526A9FF),
              Color(0x180B7EF5),
              Color(0x000B7EF5),
            ],
          ).createShader(const Rect.fromLTWH(0, 0, 1, 1)),
      );
      for (final radius in [.32, .48, .65]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(1.1, -.12),
            width: radius * 2,
            height: radius * 2.3,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .002
            ..shader = const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0x3820C5E8), Color(0x0020C5E8)],
            ).createShader(const Rect.fromLTWH(.4, 0, .6, .7)),
        );
      }
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1, 1),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF032A46), Color(0xCC032A46), Color(0x00032A46)],
            stops: [0, .38, .85],
          ).createShader(const Rect.fromLTWH(0, 0, 1, 1)),
      );
      canvas.restore();
      return;
    }
    const horizon = .34;
    final distantRidge = Path()
      ..moveTo(.27, horizon + .17)
      ..lineTo(.38, horizon - .07)
      ..lineTo(.45, horizon - .1)
      ..lineTo(.52, horizon + .01)
      ..lineTo(.55, horizon - .02)
      ..lineTo(.64, horizon + .12)
      ..lineTo(.71, horizon + .07)
      ..lineTo(.75, horizon + .1)
      ..lineTo(.87, horizon - .04)
      ..lineTo(.91, horizon)
      ..lineTo(.95, horizon - .05)
      ..lineTo(1, horizon - .03)
      ..lineTo(1, 1)
      ..lineTo(.27, 1)
      ..close();
    canvas.drawPath(distantRidge, Paint()..color = const Color(0xFF124781));
    final mountains = Path()
      ..moveTo(.3, .75)
      ..lineTo(.46, horizon + .06)
      ..lineTo(.54, horizon + .13)
      ..lineTo(.61, horizon + .06)
      ..lineTo(.65, horizon + .07)
      ..lineTo(.67, horizon + .02)
      ..lineTo(.73, horizon + .04)
      ..lineTo(.8, horizon + .06)
      ..lineTo(.82, horizon + .03)
      ..lineTo(.94, horizon + .1)
      ..lineTo(1, horizon + .02)
      ..lineTo(1, 1)
      ..lineTo(.3, 1)
      ..close();
    canvas.drawPath(mountains, Paint()..color = const Color(0xFF07316B));

    // A tapered road: narrow at the horizon and wide in the foreground.
    final road = Path()
      ..moveTo(.75, horizon)
      ..cubicTo(.55, horizon + .04, .98, horizon + .1, .85, horizon + .23)
      ..cubicTo(.78, horizon + .32, .58, .8, .46, 1.08)
      ..lineTo(1.12, 1.08)
      ..cubicTo(.92, .78, .94, horizon + .34, .93, horizon + .25)
      ..cubicTo(1, horizon + .1, .6, horizon + .04, .75, horizon)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF061B42));

    final yellowEdge = Path()
      ..moveTo(.75, horizon)
      ..cubicTo(.55, horizon + .04, .98, horizon + .1, .85, horizon + .23)
      ..cubicTo(.78, horizon + .32, .58, .8, .46, 1.08)
      ..lineTo(.56, 1.08)
      ..cubicTo(.64, .8, .81, horizon + .32, .87, horizon + .23)
      ..cubicTo(.98, horizon + .1, .57, horizon + .04, .75, horizon)
      ..close();
    canvas.drawPath(
      yellowEdge,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE57B), Color(0xFFFFC900)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(0, 0, 1, 1)),
    );
    final blueEdge = Path()
      ..moveTo(.75, horizon)
      ..cubicTo(.6, horizon + .04, 1, horizon + .1, .93, horizon + .25)
      ..cubicTo(.94, horizon + .34, .92, .78, 1.12, 1.08)
      ..lineTo(1.04, 1.08)
      ..cubicTo(.9, .78, .92, horizon + .34, .91, horizon + .25)
      ..cubicTo(.99, horizon + .1, .6, horizon + .04, .75, horizon)
      ..close();
    canvas.drawPath(blueEdge, Paint()..color = const Color(0xFF0787FF));

    final center = Path()
      ..moveTo(.75, horizon)
      ..cubicTo(.58, horizon + .04, 1, horizon + .1, .9, horizon + .24)
      ..cubicTo(.86, horizon + .34, .77, .8, .76, 1.08);
    final metric = center.computeMetrics().first;
    for (double t = .04; t < metric.length; t += .075) {
      canvas.drawPath(
        metric.extractPath(t, t + .035),
        Paint()
          ..color = const Color(0xFFFFD329)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .005,
      );
    }

    // Keep all text on a quiet, high-contrast part of the backdrop.
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF032A46),
            const Color(0xFF03244D).withValues(alpha: .94),
            const Color(0xFF03244D).withValues(alpha: 0),
          ],
          stops: [0, card ? .38 : .35, .8],
        ).createShader(const Rect.fromLTWH(0, 0, 1, 1)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.card != card;
}
