import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'state.dart';

/// Fires callbacks every time the widget appears or disappears from the screen.
class LifecycleAware extends StatefulWidget {
  const LifecycleAware({
    required this.child,
    this.controller,
    this.onCreate,
    this.onShow,
    this.onHide,
    this.onDestroy,
    this.onAppResume,
    this.onAppPause,
    this.isWidgetTest,
    super.key,
    this.showVisibilityThreshold = 1,
    this.hideVisibilityThreshold = 0,
  });

  final LifecycleController? controller;
  final double showVisibilityThreshold;
  final double hideVisibilityThreshold;

  final VoidCallback? onCreate;
  final VoidCallback? onShow;
  final VoidCallback? onHide;
  final VoidCallback? onDestroy;
  final VoidCallback? onAppResume;
  final VoidCallback? onAppPause;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Set Visibility Detector Update Interval to Duration.zero.
  final bool? isWidgetTest;

  @override
  LifecycleAwareState createState() => LifecycleAwareState();
}

class LifecycleAwareState extends State<LifecycleAware> {
  late final AppLifecycleListener _appLifecycleListener;
  AppLifecycleState? _appState;
  late final _controller = widget.controller ?? LifecycleController();
  final _visibilityDetectorKey = UniqueKey();

  double _lastVisibleFraction = 0;

  /// Whether the app is in the foreground.
  bool _isAppResumed = true;

  @override
  void initState() {
    assert(widget.showVisibilityThreshold > widget.hideVisibilityThreshold);
    widget.onCreate?.call();
    _controller._update(LifecycleState.created);
    _controller._triggerNotifier.addListener(() {
      _notifyVisibilityStatusChange(
        _lastVisibleFraction,
        force: true,
      );
    });
    _appState = SchedulerBinding.instance.lifecycleState;
    _isAppResumed = _appState == AppLifecycleState.resumed;
    _appLifecycleListener = AppLifecycleListener(
      onShow: () {
        _notifyAppLifecycleChanged(AppLifecycleState.resumed);
      },
      onResume: () {},
      onHide: () {
        _notifyAppLifecycleChanged(AppLifecycleState.hidden);
      },
      onInactive: () {},
      onPause: () {},
      onDetach: () {},
      onRestart: () {},
      // This fires for each state change. Callbacks above fire only for
      // specific state transitions.
      onStateChange: _handleAppStateChange,
    );

    if (widget.isWidgetTest == true) {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
    }
    super.initState();
  }

  void _handleAppStateChange(AppLifecycleState state) {
    setState(() {
      _appState = state;
    });
  }

  /// Notifies app's transitions to/from the foreground.
  void _notifyAppLifecycleChanged(AppLifecycleState state) {
    final wasVisible = _lastVisibleFraction >= widget.showVisibilityThreshold;
    if (!wasVisible) {
      return;
    }
    final isAppResumed = state == AppLifecycleState.resumed;
    final wasResumed = _isAppResumed;
    if (isAppResumed && !wasResumed) {
      _isAppResumed = true;
      _notifyAppResumed();
      return;
    }

    final isAppPaused = state == AppLifecycleState.hidden;
    if (isAppPaused && wasResumed) {
      _isAppResumed = false;
      _notifyAppPaused();
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
  void _notifyVisibilityStatusChange(
    double visibleFraction, {
    bool force = false,
  }) {
    if (!_isAppResumed) {
      return;
    }

    final wasHidden = _lastVisibleFraction <= widget.hideVisibilityThreshold;
    final isHidden = visibleFraction <= widget.hideVisibilityThreshold;
    final wasShow = _lastVisibleFraction >= widget.showVisibilityThreshold;
    final isShow = visibleFraction >= widget.showVisibilityThreshold;
    if (force) {
      if (isShow) {
        _notifyShow();
        _lastVisibleFraction = visibleFraction;
      }
    } else {
      if (!wasShow && isShow && wasHidden) {
        _notifyShow();
        _lastVisibleFraction = visibleFraction;
      }
    }

    if (force) {
      if (isHidden) {
        _notifyHidden();
        _lastVisibleFraction = visibleFraction;
      }
    } else {
      if (!wasHidden && isHidden && wasShow) {
        _notifyHidden();
        _lastVisibleFraction = visibleFraction;
      }
    }
  }

  void _notifyShow() {
    _controller._update(LifecycleState.resumed);
    final onShow = widget.onShow;
    if (onShow != null) {
      onShow();
    }
  }

  void _notifyHidden() {
    _controller._update(LifecycleState.hidden);
    final onHide = widget.onHide;
    if (onHide != null) {
      onHide();
    }
  }

  void _notifyAppResumed() {
    final onAppResume = widget.onAppResume;
    if (onAppResume != null) {
      onAppResume();
    }
    _notifyShow();
  }

  void _notifyAppPaused() {
    _notifyHidden();
    final onAppPause = widget.onAppPause;
    if (onAppPause != null) {
      onAppPause();
    }
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    _controller._dispose();
    widget.onDestroy?.call();
    super.dispose();
  }
}

class LifecycleController {
  LifecycleState _state = LifecycleState.created;
  LifecycleState? _previousState;
  final ValueNotifier<int> _triggerNotifier = ValueNotifier(0);

  LifecycleController();

  LifecycleState? get previousState => _previousState;

  LifecycleState get state => _state;

  void _update(LifecycleState state) {
    _previousState = _state;
    _state = state;
  }

  // trigger current callback
  trigger() {
    _triggerNotifier.value = _triggerNotifier.value + 1;
  }

  void _dispose() {
    _triggerNotifier.dispose();
    _state = LifecycleState.destroyed;
  }
}
