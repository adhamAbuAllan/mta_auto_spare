import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Debug-only timing for a widget subtree's layout and paint work.
class DebugPerformanceProbe extends SingleChildRenderObjectWidget {
  const DebugPerformanceProbe({
    super.key,
    required this.label,
    required super.child,
  });

  final String label;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return DebugPerformanceRenderBox(label);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant DebugPerformanceRenderBox renderObject,
  ) {
    renderObject.label = label;
  }
}

class DebugPerformanceRenderBox extends RenderProxyBox {
  DebugPerformanceRenderBox(this.label);

  static const _slowSectionThreshold = Duration(milliseconds: 2);
  static const _logThrottle = Duration(seconds: 1);
  static final Map<String, DateTime> _lastLogAt = {};

  String label;

  @override
  void performLayout() {
    if (!kDebugMode) {
      super.performLayout();
      return;
    }

    final stopwatch = Stopwatch()..start();
    super.performLayout();
    _logIfSlow('layout', stopwatch.elapsed);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!kDebugMode) {
      super.paint(context, offset);
      return;
    }

    final stopwatch = Stopwatch()..start();
    super.paint(context, offset);
    _logIfSlow('paint', stopwatch.elapsed);
  }

  void _logIfSlow(String phase, Duration elapsed) {
    if (elapsed < _slowSectionThreshold) {
      return;
    }

    final key = '$label/$phase';
    final now = DateTime.now();
    final lastLogAt = _lastLogAt[key];
    if (lastLogAt != null && now.difference(lastLogAt) < _logThrottle) {
      return;
    }
    _lastLogAt[key] = now;

    debugPrint(
      '[Requests][Probe] $label $phase=${(elapsed.inMicroseconds / 1000).toStringAsFixed(1)}ms',
    );
  }
}
