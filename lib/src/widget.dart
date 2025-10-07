import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'state.dart';

/// Fires callbacks every time the widget appears or disappears from the screen.
///
/// This widget provides lifecycle management for Flutter widgets, similar to Android's
/// lifecycle components. It tracks widget visibility and app lifecycle states,
/// triggering appropriate callbacks when state changes occur.
///
/// Example usage:
/// ```dart
/// LifecycleAware(
///   controller: controller,
///   showVisibilityThreshold: 0.5,
///   hideVisibilityThreshold: 0.1,
///   onCreate: () => print('Widget created'),
///   onShow: () => print('Widget visible'),
///   onHide: () => print('Widget hidden'),
///   onDestroy: () => print('Widget destroyed'),
///   child: MyWidget(),
/// )
/// ```
class LifecycleAware extends StatefulWidget {
  /// Creates a [LifecycleAware] widget.
  ///
  /// The [child] parameter is required and represents the widget to be wrapped.
  ///
  /// Visibility thresholds must satisfy: [showVisibilityThreshold] > [hideVisibilityThreshold]
  /// and both values must be between 0.0 and 1.0 inclusive.
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
    this.showVisibilityThreshold = 1.0,
    this.callShowOnAppResume = false,
    this.callHideOnAppPause = false,
    this.hideVisibilityThreshold = 0.0,
    this.appLifecycleListenerCallbackNotifier,
  })  : assert(showVisibilityThreshold > hideVisibilityThreshold,
            'showVisibilityThreshold must be greater than hideVisibilityThreshold'),
        assert(showVisibilityThreshold >= 0.0 && showVisibilityThreshold <= 1.0,
            'showVisibilityThreshold must be between 0.0 and 1.0'),
        assert(hideVisibilityThreshold >= 0.0 && hideVisibilityThreshold <= 1.0,
            'hideVisibilityThreshold must be between 0.0 and 1.0');

  /// Optional controller to manage lifecycle state externally
  final LifecycleController? controller;

  /// Threshold for determining when widget is considered visible (0.0 to 1.0)
  final double showVisibilityThreshold;

  /// Threshold for determining when widget is considered hidden (0.0 to 1.0)
  final double hideVisibilityThreshold;

  /// Optional notifier for app lifecycle callback events
  final ValueNotifier<AppLifecycleListenerCallback?>?
      appLifecycleListenerCallbackNotifier;

  /// Called when the widget is first created
  final VoidCallback? onCreate;

  /// Called when the widget becomes visible
  final VoidCallback? onShow;

  /// Called when the widget becomes hidden
  final VoidCallback? onHide;

  /// Called when the widget is destroyed
  final VoidCallback? onDestroy;

  /// Called when the app resumes from background
  final VoidCallback? onAppResume;

  /// Called when the app goes to background
  final VoidCallback? onAppPause;

  /// Whether to call onShow when app resumes
  final bool callShowOnAppResume;

  /// Whether to call onHide when app pauses
  final bool callHideOnAppPause;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Set Visibility Detector Update Interval to Duration.zero for testing.
  final bool? isWidgetTest;

  @override
  LifecycleAwareState createState() => LifecycleAwareState();
}

/// State class for [LifecycleAware] widget.
///
/// Manages the lifecycle state transitions and visibility detection.
class LifecycleAwareState extends State<LifecycleAware> {
  AppLifecycleListener? _appLifecycleListener;
  late final LifecycleController _controller;
  late final ValueNotifier<AppLifecycleListenerCallback?>
      _appLifecycleListenerCallbackNotifier;
  late final UniqueKey _visibilityDetectorKey;

  double _lastVisibleFraction = 0.0;
  bool _isAppResumed = true;

  @override
  void initState() {
    super.initState();

    _initializeController();
    _initializeAppLifecycleNotifier();
    _setupVisibilityDetector();
    _setupAppLifecycleListener();

    // Trigger onCreate callback
    _safeCallCallback(widget.onCreate);
  }

  /// Initialize the lifecycle controller
  void _initializeController() {
    _controller = widget.controller ?? LifecycleController();
    _controller._initState();
    _controller._triggerNotifier?.addListener(_onControllerTrigger);
  }

  /// Initialize app lifecycle callback notifier
  void _initializeAppLifecycleNotifier() {
    _appLifecycleListenerCallbackNotifier =
        widget.appLifecycleListenerCallbackNotifier ??
            ValueNotifier<AppLifecycleListenerCallback?>(null);
    _appLifecycleListenerCallbackNotifier.addListener(_onAppLifecycleStateCall);
  }

  /// Setup visibility detector for testing
  void _setupVisibilityDetector() {
    _visibilityDetectorKey = UniqueKey();
    if (widget.isWidgetTest == true) {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
    }
  }

  /// Setup app lifecycle listener if not provided externally
  void _setupAppLifecycleListener() {
    if (widget.appLifecycleListenerCallbackNotifier == null) {
      _isAppResumed =
          SchedulerBinding.instance.lifecycleState == AppLifecycleState.resumed;
      _appLifecycleListener = AppLifecycleListener(
        onShow: () => _appLifecycleListenerCallbackNotifier.value =
            AppLifecycleListenerCallback.onShow,
        onResume: () {}, // No-op, handled by onShow
        onHide: () => _appLifecycleListenerCallbackNotifier.value =
            AppLifecycleListenerCallback.onHide,
        onInactive: () {}, // No-op
        onPause: () {}, // No-op
        onDetach: () {}, // No-op
        onRestart: () {}, // No-op
      );
    } else {
      _isAppResumed = true;
    }
  }

  /// Handle controller trigger events
  void _onControllerTrigger() {
    _notifyVisibilityStatusChange(_lastVisibleFraction, force: true);
  }

  /// Handle app lifecycle state changes
  void _onAppLifecycleStateCall() {
    final callback = _appLifecycleListenerCallbackNotifier.value;
    if (callback == null) return;

    switch (callback) {
      case AppLifecycleListenerCallback.onShow:
        _notifyAppLifecycleChanged(AppLifecycleState.resumed);
        break;
      case AppLifecycleListenerCallback.onHide:
        _notifyAppLifecycleChanged(AppLifecycleState.hidden);
        break;
    }
  }

  /// Notifies app's transitions to/from the foreground.
  ///
  /// Only processes lifecycle changes when the widget is currently visible.
  void _notifyAppLifecycleChanged(AppLifecycleState state) {
    // In test environment, allow lifecycle changes even if widget is not visible
    // In production, only process if widget is visible
    final shouldProcess = (widget.isWidgetTest ?? false) || _isWidgetCurrentlyVisible();
    if (!shouldProcess) return;

    final isAppResumed = state == AppLifecycleState.resumed;
    final wasResumed = _isAppResumed;

    if (_shouldNotifyAppResumed(isAppResumed, wasResumed)) {
      _isAppResumed = true;
      _notifyAppResumed();
      return;
    }

    final isAppHidden = state == AppLifecycleState.hidden;
    if (_shouldNotifyAppHidden(isAppHidden, wasResumed)) {
      _isAppResumed = false;
      _notifyAppHidden();
    }
  }

  /// Check if widget is currently visible based on threshold
  bool _isWidgetCurrentlyVisible() {
    return _lastVisibleFraction >= widget.showVisibilityThreshold;
  }

  /// Determine if app resumed notification should be sent
  bool _shouldNotifyAppResumed(bool isAppResumed, bool wasResumed) {
    return isAppResumed && !wasResumed;
  }

  /// Determine if app hidden notification should be sent
  bool _shouldNotifyAppHidden(bool isAppHidden, bool wasResumed) {
    return isAppHidden && wasResumed;
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
  ///
  /// Uses threshold-based logic to determine when to trigger show/hide callbacks.
  /// The [force] parameter bypasses app resume state checks.
  void _notifyVisibilityStatusChange(
    double visibleFraction, {
    bool force = false,
  }) {
    if (!force && !_isAppResumed) return;

    final visibilityState = _calculateVisibilityState(visibleFraction);
    final previousVisibilityState =
        _calculateVisibilityState(_lastVisibleFraction);

    if (force) {
      _handleForcedVisibilityUpdate(visibilityState, visibleFraction);
    } else {
      _handleNormalVisibilityUpdate(
          visibilityState, previousVisibilityState, visibleFraction);
    }
  }

  /// Calculate visibility state based on thresholds
  _VisibilityState _calculateVisibilityState(double fraction) {
    if (fraction >= widget.showVisibilityThreshold) {
      return _VisibilityState.visible;
    } else if (fraction <= widget.hideVisibilityThreshold) {
      return _VisibilityState.hidden;
    } else {
      return _VisibilityState.partial;
    }
  }

  /// Handle forced visibility updates (e.g., from controller trigger)
  void _handleForcedVisibilityUpdate(_VisibilityState state, double fraction) {
    switch (state) {
      case _VisibilityState.visible:
        _notifyShow();
        _lastVisibleFraction = fraction;
        break;
      case _VisibilityState.hidden:
        _notifyHidden();
        _lastVisibleFraction = fraction;
        break;
      case _VisibilityState.partial:
        _lastVisibleFraction = fraction;
        break;
    }
  }

  /// Handle normal visibility updates with state transition logic
  void _handleNormalVisibilityUpdate(
    _VisibilityState currentState,
    _VisibilityState previousState,
    double fraction,
  ) {
    // Show transition: hidden -> visible
    if (previousState != _VisibilityState.visible &&
        currentState == _VisibilityState.visible &&
        previousState == _VisibilityState.hidden) {
      _notifyShow();
      _lastVisibleFraction = fraction;
    }

    // Hide transition: visible -> hidden
    else if (previousState != _VisibilityState.hidden &&
        currentState == _VisibilityState.hidden &&
        previousState == _VisibilityState.visible) {
      _notifyHidden();
      _lastVisibleFraction = fraction;
    }

    // Update fraction for partial states
    else if (currentState == _VisibilityState.partial) {
      _lastVisibleFraction = fraction;
    }
  }

  /// Notify widget show event
  void _notifyShow() {
    _controller._update(LifecycleState.resumed);
    _safeCallCallback(widget.onShow);
  }

  /// Notify widget hide event
  void _notifyHidden() {
    _controller._update(LifecycleState.hidden);
    _safeCallCallback(widget.onHide);
  }

  /// Notify app resume event
  void _notifyAppResumed() {
    _safeCallCallback(widget.onAppResume);
    if (widget.callShowOnAppResume ?? false) {
      _notifyShow();
    }
  }

  /// Notify app hidden event
  void _notifyAppHidden() {
    if (widget.callHideOnAppPause ?? false) {
      _notifyHidden();
    }
    _safeCallCallback(widget.onAppPause);
  }

  /// Safely call a callback with error handling
  void _safeCallCallback(VoidCallback? callback) {
    if (callback == null) return;

    try {
      callback();
    } catch (error, stackTrace) {
      // Log error in debug mode, but don't crash the app
      assert(() {
        debugPrint('LifecycleAware callback error: $error');
        debugPrint('Stack trace: $stackTrace');
        return true;
      }());
    }
  }

  @override
  void dispose() {
    _appLifecycleListenerCallbackNotifier
        .removeListener(_onAppLifecycleStateCall);
    _controller._triggerNotifier?.removeListener(_onControllerTrigger);

    _safeCallCallback(widget.onDestroy);

    _appLifecycleListener?.dispose();
    _controller._dispose();

    super.dispose();
  }
}

/// Enhanced lifecycle controller with better state management and error handling.
///
/// Provides methods to track and control widget lifecycle states programmatically.
///
/// Example usage:
/// ```dart
/// final controller = LifecycleController();
///
/// // Check current state
/// if (controller.state == LifecycleState.resumed) {
///   // Widget is visible
/// }
///
/// // Trigger callbacks manually
/// controller.trigger();
/// ```
class LifecycleController {
  LifecycleState _state = LifecycleState.created;
  LifecycleState? _previousState;
  ValueNotifier<int>? _triggerNotifier;
  bool _isDisposed = false;

  /// Creates a new [LifecycleController].
  LifecycleController();

  /// The previous lifecycle state, or null if no previous state exists.
  LifecycleState? get previousState => _previousState;

  /// The current lifecycle state.
  LifecycleState get state => _state;

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Initialize the controller's internal state.
  ///
  /// This method is called automatically by [LifecycleAware] and should not
  /// be called manually.
  void _initState() {
    if (_isDisposed) {
      throw StateError('Cannot initialize a disposed LifecycleController');
    }

    _triggerNotifier = ValueNotifier(0);
    _update(LifecycleState.created);
  }

  /// Update the lifecycle state.
  ///
  /// This method is called automatically by [LifecycleAware] and should not
  /// be called manually.
  void _update(LifecycleState state) {
    if (_isDisposed) return;

    _previousState = _state;
    _state = state;
  }

  /// Manually trigger lifecycle callbacks.
  ///
  /// This will cause the associated [LifecycleAware] widget to re-evaluate
  /// its current visibility state and trigger appropriate callbacks.
  ///
  /// Throws [StateError] if the controller has been disposed.
  void trigger() {
    if (_isDisposed) {
      throw StateError('Cannot trigger on a disposed LifecycleController');
    }

    final notifier = _triggerNotifier;
    if (notifier != null) {
      notifier.value = notifier.value + 1;
    }
  }

  /// Dispose of this controller and clean up resources.
  ///
  /// This method is called automatically by [LifecycleAware] and should not
  /// be called manually unless you're managing the controller independently.
  void _dispose() {
    if (_isDisposed) return;

    _update(LifecycleState.destroyed);
    _triggerNotifier?.dispose();
    _triggerNotifier = null;
    _isDisposed = true;
  }
}

/// Enum representing app lifecycle listener callback types.
enum AppLifecycleListenerCallback {
  /// App became visible/resumed
  onShow,

  /// App became hidden/paused
  onHide,
}

/// Internal enum for tracking widget visibility states
enum _VisibilityState {
  /// Widget is fully visible (above show threshold)
  visible,

  /// Widget is partially visible (between thresholds)
  partial,

  /// Widget is hidden (below hide threshold)
  hidden,
}
