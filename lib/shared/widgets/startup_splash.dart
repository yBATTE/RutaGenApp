import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Presenta el asset original con ritmo acelerado y un límite de 2 segundos.
/// Los diálogos de autenticación se solicitan después de esta pantalla.
class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onReady, this.assetBundle});

  final VoidCallback onReady;
  final AssetBundle? assetBundle;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with WidgetsBindingObserver {
  static const _minimumVisible = Duration(milliseconds: 2000);
  bool _minimumElapsed = false;
  bool _animationCompleted = false;
  final _frameClock = Stopwatch();
  final _minimumClock = Stopwatch();
  ui.Codec? _codec;
  ui.Image? _image;
  Timer? _frameTimer;
  Timer? _minimumTimer;
  Duration _frameRemaining = Duration.zero;
  Duration _minimumRemaining = _minimumVisible;
  int _frameIndex = 0;
  int _frameCount = 0;
  bool _foreground = true;
  bool _visible = false;
  bool _framePending = false;
  bool _decoding = false;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadAnimation());
  }

  Future<void> _loadAnimation() async {
    try {
      final bytes = await (widget.assetBundle ?? rootBundle).load(
        'assets/animations/ruta_gen_loader.gif',
      );
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      if (!mounted) {
        codec.dispose();
        return;
      }
      _codec = codec;
      _frameCount = codec.frameCount;
      await _decodeFrame();
    } catch (_) {
      _showFallback();
    }
  }

  Future<void> _decodeFrame() async {
    final codec = _codec;
    if (!mounted || codec == null || _decoding) return;
    _decoding = true;
    try {
      final frame = await codec.getNextFrame();
      if (!mounted || _notified) {
        frame.image.dispose();
        return;
      }
      final previous = _image;
      setState(() => _image = frame.image);
      _frameIndex++;
      // Un GIF sin duración explícita no debe generar un bucle inmediato.
      // El asset actual declara 5 s: acelerar 2,5x sin editar el archivo.
      // El límite independiente evita acumular retrasos de pintado por cuadro.
      _frameRemaining = frame.duration > Duration.zero
          ? Duration(microseconds: (frame.duration.inMicroseconds * 0.4).round())
          : const Duration(milliseconds: 16);
      _framePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previous?.dispose();
        if (!mounted) return;
        _markVisible();
        _resumeTimers();
      });
    } catch (_) {
      _showFallback();
    } finally {
      _decoding = false;
    }
  }

  void _showFallback() {
    if (!mounted) return;
    _codec?.dispose();
    _codec = null;
    _frameTimer?.cancel();
    _frameClock.stop();
    _framePending = false;
    _animationCompleted = true;
    // Si el asset falla, el indicador visible cumple igualmente el mínimo.
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _markVisible();
      _resumeTimers();
      _notifyIfReady();
    });
  }

  void _markVisible() {
    if (_visible) return;
    // Se llama después de pintar el primer cuadro o el fallback, nunca al
    // comenzar a leer el archivo ni al iniciar la consulta de sesión.
    _visible = true;
  }

  void _resumeTimers() {
    if (!mounted || !_foreground || !_visible) return;
    if (!_minimumElapsed && !_minimumClock.isRunning && _minimumTimer == null) {
      _minimumClock.start();
      _minimumTimer = Timer(_minimumRemaining, () {
        _minimumTimer = null;
        _minimumClock.stop();
        _minimumRemaining = Duration.zero;
        _minimumElapsed = true;
        _animationCompleted = true;
        _framePending = false;
        _frameTimer?.cancel();
        _frameTimer = null;
        _frameClock.stop();
        _notifyIfReady();
      });
    }
    if (_framePending && _frameTimer == null) {
      _frameClock.start();
      _frameTimer = Timer(_frameRemaining, () {
        _frameTimer = null;
        _frameClock.stop();
        _frameClock.reset();
        _framePending = false;
        if (_frameIndex >= _frameCount) {
          _codec?.dispose();
          _codec = null;
          _animationCompleted = true;
          _notifyIfReady();
        } else {
          unawaited(_decodeFrame());
        }
      });
    }
  }

  void _notifyIfReady() {
    if (!mounted || !_foreground || _notified || !(_minimumElapsed && _animationCompleted)) return;
    _notified = true;
    widget.onReady();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      if (_frameClock.isRunning) {
        _frameRemaining -= _frameClock.elapsed;
        if (_frameRemaining.isNegative) _frameRemaining = Duration.zero;
      }
      if (_minimumClock.isRunning) {
        _minimumRemaining -= _minimumClock.elapsed;
        if (_minimumRemaining.isNegative) _minimumRemaining = Duration.zero;
      }
      _frameTimer?.cancel();
      _minimumTimer?.cancel();
      _frameTimer = null;
      _minimumTimer = null;
      _frameClock.stop();
      _frameClock.reset();
      _minimumClock.stop();
      _minimumClock.reset();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resumeTimers();
        _notifyIfReady();
      });
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameTimer?.cancel();
    _minimumTimer?.cancel();
    _codec?.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFCFCFC),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AspectRatio(
                  aspectRatio: 500 / 540,
                  child: _image == null
                      ? const _LoadingFallback()
                      : Semantics(
                          label: 'Ruta GEN. Cargando…',
                          image: true,
                          child: RawImage(
                            image: _image,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _LoadingFallback extends StatelessWidget {
  const _LoadingFallback();

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.blue,
              strokeWidth: 3,
              semanticsLabel: 'Cargando Ruta GEN',
            ),
          ),
          SizedBox(height: 16),
          Text('Cargando Ruta GEN…', style: TextStyle(color: AppColors.muted)),
        ],
      );
}
