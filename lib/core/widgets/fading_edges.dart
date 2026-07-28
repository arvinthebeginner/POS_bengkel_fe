import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Softens the edges of a scrollable's viewport so content dissolves into the
/// background instead of being sliced off mid-card at the clip boundary.
///
/// Both edges follow the scroll position rather than being always-on: the top
/// fade only appears once something has actually scrolled up past it, and the
/// bottom fade disappears once the list bottoms out. Without that, the very
/// first card would sit permanently half-faded (every list here starts with a
/// top padding of 0) and the last card would never resolve to full opacity.
///
/// When both edges are at rest the [ShaderMask] is skipped entirely, so a
/// list that fits on screen costs no `saveLayer` at all.
class FadingEdges extends StatefulWidget {
  const FadingEdges({
    super.key,
    required this.child,
    this.top = 24,
    this.bottom = 48,
  });

  final Widget child;

  /// How tall the fade grows to once content has scrolled past the top edge.
  final double top;

  /// How tall the fade is while there is still content below the bottom edge.
  final double bottom;

  @override
  State<FadingEdges> createState() => _FadingEdgesState();
}

class _FadingEdgesState extends State<FadingEdges> {
  double _topFactor = 0;
  double _bottomFactor = 0;

  bool _onScroll(ScrollNotification notification) {
    _apply(notification.metrics);
    // Let the notification keep bubbling — RefreshIndicator sits above us.
    return false;
  }

  // ScrollNotification only fires once the user actually scrolls. Without
  // this, a list that overflows on first layout would render a hard bottom
  // edge until first touch — which is the exact thing this widget exists to
  // avoid. ScrollMetricsNotification covers first layout and any later
  // change in content extent.
  bool _onMetrics(ScrollMetricsNotification notification) {
    _apply(notification.metrics);
    return false;
  }

  void _apply(ScrollMetrics metrics) {
    // Only a vertical list may drive the fade — a horizontal scrollable
    // nested in a row would otherwise report its own extents into ours.
    if (metrics.axis != Axis.vertical) return;

    final top = widget.top > 0
        ? (metrics.extentBefore / widget.top).clamp(0.0, 1.0)
        : 0.0;
    final bottom = widget.bottom > 0
        ? (metrics.extentAfter / widget.bottom).clamp(0.0, 1.0)
        : 0.0;

    // Repainting on every pixel of scroll would be wasteful; the eye can't
    // resolve a 1% change in fade height anyway.
    if ((top - _topFactor).abs() <= 0.01 &&
        (bottom - _bottomFactor).abs() <= 0.01) {
      return;
    }

    void assign() {
      if (!mounted) return;
      setState(() {
        _topFactor = top;
        _bottomFactor = bottom;
      });
    }

    // Metrics notifications arrive during layout, where setState is illegal,
    // so defer those to after the frame. Plain scroll updates are already
    // outside the build phase and can apply immediately.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => assign());
    } else {
      assign();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topExtent = widget.top * _topFactor;
    final bottomExtent = widget.bottom * _bottomFactor;
    final isAtRest = topExtent < 0.5 && bottomExtent < 0.5;

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: isAtRest
            ? widget.child
            : ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) =>
                    _mask(bounds, topExtent, bottomExtent),
                child: widget.child,
              ),
      ),
    );
  }

  Shader _mask(Rect bounds, double topExtent, double bottomExtent) {
    final height = bounds.height;
    if (height <= 0) {
      return const LinearGradient(
        colors: [Colors.black, Colors.black],
      ).createShader(bounds);
    }

    var topStop = (topExtent / height).clamp(0.0, 1.0);
    var bottomStop = (1 - bottomExtent / height).clamp(0.0, 1.0);
    // A viewport shorter than top + bottom would produce descending stops,
    // which LinearGradient asserts on. Collapse the opaque band to a point.
    if (topStop > bottomStop) {
      topStop = bottomStop = (topStop + bottomStop) / 2;
    }

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Colors.transparent,
        Colors.black,
        Colors.black,
        Colors.transparent,
      ],
      stops: [0, topStop, bottomStop, 1],
    ).createShader(bounds);
  }
}
