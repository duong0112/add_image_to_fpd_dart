import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class GlobalUserActivityDetector with WidgetsBindingObserver {
  static final GlobalUserActivityDetector _instance = GlobalUserActivityDetector._();
  factory GlobalUserActivityDetector() => _instance;

  final Duration debounceDuration = const Duration(seconds: 15);
  DateTime _lastAction = DateTime.now();
  Timer? _debounce;

  GlobalUserActivityDetector._() {
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointerEvent);
      RawKeyboard.instance.addListener(_onKeyEvent);
      html.window.onFocus.listen((_) => _markActivity());
    });
  }

  void _onPointerEvent(PointerEvent event) => _markActivity();

  void _onKeyEvent(RawKeyEvent event) => _markActivity();

  void _markActivity() {
    if (_debounce?.isActive ?? false) return;
    _debounce = Timer(debounceDuration, () {});
    _lastAction = DateTime.now();
    print('🧠 User active at $_lastAction');
  }

  // Optional tiện ích
  DateTime get lastActivity => _lastAction;
  Duration get inactiveDuration => DateTime.now().difference(_lastAction);

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointerEvent);
    RawKeyboard.instance.removeListener(_onKeyEvent);
  }
}
