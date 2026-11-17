import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

const _gold = Color(0xFFFFC400);
const _blue = Color(0xFF0659ED);

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});
  final Future<void> Function() onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 2800));
  final _pages = PageController();
  bool _transitioning = false;
  int _page = 0;
  bool _saving = false;
  static const _titles = [
    'Bienvenido a\nRuta GEN', 'Cargá y sumá\npuntos', 'Elegí tu próximo\npremio',
  ];
  static const _descriptions = [
    'Tu próxima carga tiene premio.',
    'Presentá tu QR y sumá puntos con tus cargas participantes.',
    'Descubrí los beneficios y canjeá tus puntos.',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _motion.stop();
      _motion.value = 0;
    } else if (!_motion.isAnimating) {
      _motion.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _motion.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_saving || _transitioning) return;
    if (_page < 2) {
      await _goTo(_page + 1);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onComplete();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo guardar. Tocá Comenzar para reintentar.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _goTo(int target) async {
    if (_transitioning || _saving || !_pages.hasClients) return;
    setState(() => _transitioning = true);
    try {
      if (MediaQuery.of(context).disableAnimations) {
        _pages.jumpToPage(target);
      } else {
        await _pages.animateToPage(target,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic);
      }
    } finally {
      if (mounted) setState(() => _transitioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _page == 0 && !_saving && !_transitioning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving && !_transitioning && _page > 0) {
          _goTo(_page - 1);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Image.asset('assets/onboarding/wordmark.png',
                    width: 230, height: 76, fit: BoxFit.contain,
                    semanticLabel: 'Ruta GEN'),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    // El botón controla la transición y evita saltar dos pasos
                    // por un segundo toque mientras aún se está desplazando.
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    onPageChanged: (index) => setState(() => _page = index),
                    itemBuilder: (context, index) => LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        key: PageStorageKey('welcome-$index'),
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RepaintBoundary(
                                  child: SizedBox(
                                    height: (constraints.maxHeight * .58).clamp(180.0, 340.0),
                                    width: double.infinity,
                                    child: AnimatedBuilder(
                                      animation: _motion,
                                      child: index == 0
                                        ? Image.asset('assets/onboarding/rg.png',
                                            width: 245, height: 245,
                                            excludeFromSemantics: true)
                                        : const SizedBox.shrink(),
                                      builder: (context, child) {
                                        // Velocidad cero en ambos extremos: sin
                                        // cambio brusco de dirección al repetir.
                                        final phase = Curves.easeInOutSine.transform(_motion.value);
                                        return CustomPaint(
                                          painter: _WelcomePainter(index, phase),
                                          child: Center(child: Transform.translate(
                                            offset: Offset(0, -6 * phase), child: child)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Semantics(
                                  header: true,
                                  child: Text(_titles[index], textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 32, height: 1.12,
                                      fontWeight: FontWeight.w800, color: AppColors.navy)),
                                ),
                                const SizedBox(height: 18),
                                Text(_descriptions[index], textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, height: 1.45,
                                    color: Color(0xFF48546D))),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Semantics(
                      label: 'Pantalla ${_page + 1} de 3', liveRegion: true,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: i == _page ? 24 : 9, height: 9,
                          decoration: BoxDecoration(
                            color: i == _page ? _blue : const Color(0xFFD3DCE7),
                            borderRadius: BorderRadius.circular(8)),
                        )),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        child: Text(_saving ? 'Guardando…' : _page == 2 ? 'Comenzar' : 'Siguiente'),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

}

/// Ilustraciones vectoriales locales: no cargan videos ni necesitan internet.
class _WelcomePainter extends CustomPainter {
  _WelcomePainter(this.page, this.progress);
  final int page;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = math.min(size.width / 320, size.height / 280);
    canvas.scale(scale);
    final halo = Paint()..shader = const RadialGradient(
      colors: [Color(0xFFD9EBFF), Color(0x00D9EBFF)],
    ).createShader(const Rect.fromLTWH(-170, -140, 340, 280));
    canvas.drawOval(const Rect.fromLTWH(-170, -140, 340, 280), halo);
    if (page == 0) {
      final road = Path()..moveTo(-150, 140)..cubicTo(-110, 98, 82, 118, 40, 68)
        ..lineTo(48, 68)..cubicTo(110, 116, 30, 125, 85, 140)..close();
      canvas.drawPath(road, Paint()..color = _blue.withValues(alpha: .18));
    } else {
      canvas.translate(0, -6 * progress);
      canvas.drawOval(const Rect.fromLTWH(-85, 99, 170, 18),
        Paint()..color = _blue.withValues(alpha: .08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      if (page == 1) {
        canvas.save();
        canvas.rotate(-.08 + .025 * progress);
        canvas.drawRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(-90, -95, 180, 180), const Radius.circular(24)),
          Paint()..color = Colors.white);
        // QR ilustrativo deliberadamente no vinculado a ninguna cuenta.
        final ink = Paint()..color = AppColors.navy;
        for (var row = 0; row < 17; row++) {
          for (var col = 0; col < 17; col++) {
            final finder = (row < 7 && col < 7) || (row < 7 && col >= 10) || (row >= 10 && col < 7);
            if (!finder && (row * 13 + col * 7 + row * col) % 5 < 2) {
              canvas.drawRect(Rect.fromLTWH(-63 + col * 7, -68 + row * 7, 7, 7), ink);
            }
          }
        }
        for (final p in [const Offset(-63, -68), const Offset(7, -68), const Offset(-63, 2)]) {
          canvas.drawRect(p & const Size(49, 49), ink);
          canvas.drawRect((p + const Offset(7, 7)) & const Size(35, 35), Paint()..color = Colors.white);
          canvas.drawRect((p + const Offset(14, 14)) & const Size(21, 21), ink);
        }
        canvas.restore();
        _chip(canvas, const Offset(57, -114), '+ puntos');
        _chip(canvas, const Offset(-112, 72), '+ puntos');
      } else {
        final box = const Rect.fromLTWH(-79, -35, 158, 130);
        canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(14)),
          Paint()..shader = const LinearGradient(colors: [_blue, Color(0xFF00359F)],
            begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(box));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-89, -48, 178, 32), const Radius.circular(7)), Paint()..color = _blue);
        canvas.drawRect(const Rect.fromLTWH(-13, -48, 26, 143), Paint()..color = _gold);
        final ribbon = Paint()..color = _gold..style = PaintingStyle.stroke..strokeWidth = 13;
        canvas.drawPath(Path()..moveTo(0, -48)..cubicTo(-100, -55, -65, -135, 0, -48)
          ..cubicTo(100, -55, 65, -135, 0, -48), ribbon);
      }
      for (final p in [const Offset(-123, -78), const Offset(126, 18), const Offset(105, -104)]) {
        final r = 5 + 2 * progress;
        canvas.drawLine(p - Offset(r, 0), p + Offset(r, 0), Paint()..color = _gold..strokeWidth = 3);
        canvas.drawLine(p - Offset(0, r), p + Offset(0, r), Paint()..color = _gold..strokeWidth = 3);
      }
    }
    canvas.restore();
  }

  void _chip(Canvas canvas, Offset position, String label) {
    canvas.drawRRect(RRect.fromRectAndRadius(position & const Size(100, 33), const Radius.circular(17)), Paint()..color = _blue);
    final text = TextPainter(text: TextSpan(text: label,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr)..layout();
    text.paint(canvas, position + Offset((100 - text.width) / 2, 6));
  }

  @override
  bool shouldRepaint(covariant _WelcomePainter oldDelegate) =>
    oldDelegate.page != page || oldDelegate.progress != progress;
}
