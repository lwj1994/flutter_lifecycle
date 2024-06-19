import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Fires callbacks every time the widget appears or disappears from the screen.
class FocusDetector extends StatefulWidget {
  const FocusDetector({
    required this.child,
    this.onVisibilityGained,
    this.onVisibilityLost,
    this.onForegroundGained,
    this.onForegroundLost,
    this.isWidgetTest,
    super.key,
    this.visibleThreshold = 1,
    this.inVisibleThreshold = 0,
  });

  final double visibleThreshold;
  final double inVisibleThreshold;

  /// Called when the widget becomes visible.
  final VoidCallback? onVisibilityGained;

  /// Called when the widget becomes invisible.
  final VoidCallback? onVisibilityLost;

  /// Called when the app entered the foreground while the widget is visible.
  final VoidCallback? onForegroundGained;

  /// Called when the app is sent to background while the widget was visible.
  final VoidCallback? onForegroundLost;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Set Visibility Detector Update Interval to Duration.zero.
  final bool? isWidgetTest;

  @override
  FocusDetectorState createState() => FocusDetectorState();
}

class FocusDetectorState extends State<FocusDetector> {
  late final AppLifecycleListener _listener;
  late AppLifecycleState? _state;

  final _visibilityDetectorKey = UniqueKey();

  double _lastVisibleFraction = 0;

  /// Whether the app is in the foreground.
  bool _isAppInForeground = true;
  final List<String> _states = <String>[];

  @override
  void initState() {
    assert(widget.visibleThreshold > widget.inVisibleThreshold);
    _state = SchedulerBinding.instance.lifecycleState;
    _listener = AppLifecycleListener(
      onShow: () {
        _notifyPlaneTransition(AppLifecycleState.resumed);
      },
      onResume: () {},
      onHide: () {
        _notifyPlaneTransition(AppLifecycleState.paused);
      },
      onInactive: () {},
      onPause: () {},
      onDetach: () {},
      onRestart: () {},
      // This fires for each state change. Callbacks above fire only for
      // specific state transitions.
      onStateChange: _handleStateChange,
    );
    if (_state != null) {
      _states.add(_state!.name);
    }

    if (widget.isWidgetTest == true) {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
    }
    super.initState();
  }

  void _handleStateChange(AppLifecycleState state) {
    setState(() {
      _state = state;
    });
  }

  /// Notifies app's transitions to/from the foreground.
  void _notifyPlaneTransition(AppLifecycleState state) {
    final wasVisible = _lastVisibleFraction >= widget.visibleThreshold;
    if (!wasVisible) {
      return;
    }
    final isAppResumed = state == AppLifecycleState.resumed;
    final wasResumed = _isAppInForeground;
    if (isAppResumed && !wasResumed) {
      _isAppInForeground = true;
      _notifyForegroundGain();
      return;
    }

    final isAppPaused = state == AppLifecycleState.paused;
    if (isAppPaused && wasResumed) {
      _isAppInForeground = false;
      _notifyForegroundLoss();
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: _visibilityDetectorKey,
        onVisibilityChanged: (visibilityInfo) {
          final visibleFraction = visibilityInfo.visibleFraction;
          _notifyVisibilityStatusChange(visibleFraction);
        },
        child: widget.child,
      );

  /// Notifies changes in the widget's visibility.
  void _notifyVisibilityStatusChange(double newVisibleFraction) {
    if (!_isAppInForeground) {
      return;
    }

    final wasVisible = _lastVisibleFraction >= widget.visibleThreshold;
    final isVisible = newVisibleFraction >= widget.visibleThreshold;
    if (!wasVisible && isVisible) {
      _notifyVisibilityGain();
    }

    final wasInvisible = _lastVisibleFraction <= widget.inVisibleThreshold;
    final isInvisible = newVisibleFraction <= widget.inVisibleThreshold;
    if (!wasInvisible && isInvisible) {
      _notifyVisibilityLoss();
    }

    _lastVisibleFraction = newVisibleFraction;
  }

  void _notifyVisibilityGain() {
    final onVisibilityGained = widget.onVisibilityGained;
    if (onVisibilityGained != null) {
      onVisibilityGained();
    }
  }

  void _notifyVisibilityLoss() {
    final onVisibilityLost = widget.onVisibilityLost;
    if (onVisibilityLost != null) {
      onVisibilityLost();
    }
  }

  void _notifyForegroundGain() {
    final onForegroundGained = widget.onForegroundGained;
    if (onForegroundGained != null) {
      onForegroundGained();
    }
    _notifyVisibilityGain();
  }

  void _notifyForegroundLoss() {
    _notifyVisibilityLoss();
    final onForegroundLost = widget.onForegroundLost;
    if (onForegroundLost != null) {
      onForegroundLost();
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }
}
