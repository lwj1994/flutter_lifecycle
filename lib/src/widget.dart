import 'package:flutter/material.dart';

import 'focus_detector.dart';
import 'lifecycle.dart' as lifecycle_lifecycle;
import 'lifecycle_registry.dart';
import 'observer.dart';
import 'state.dart' as lifecycle_state;

class LifecycleAware extends StatefulWidget {
  final Function(BuildContext context, lifecycle_lifecycle.Lifecycle lifecycle)
      builder;
  final LifecycleObserver? observer;
  final double visibleThreshold;

  const LifecycleAware({
    super.key,
    required this.builder,
    this.visibleThreshold = 1.0,
    this.observer,
  });

  @override
  State<StatefulWidget> createState() {
    return LifecycleAwareState<LifecycleAware>();
  }
}

class LifecycleAwareState<T extends LifecycleAware> extends State<T>
    with lifecycle_lifecycle.LifecycleOwner, WidgetsBindingObserver {
  @override
  lifecycle_lifecycle.Lifecycle get lifecycle => _lifecycleRegistry;

  late final LifecycleRegistry _lifecycleRegistry = LifecycleRegistry(this);
  final GlobalKey _focusKey = GlobalKey();

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (mounted) {
      setState(() {
        _focusKey.currentState?.setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibleThreshold != widget.visibleThreshold) {
      _focusKey.currentState?.setState(() {});
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleRegistry
        .handleLifecycleEvent(lifecycle_state.LifecycleEvent.onCreate);
    if (widget.observer != null) {
      lifecycle.addObserver(widget.observer!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildRootPage(context);
  }

  @protected
  Widget buildRootPage(BuildContext context) {
    final page = buildPage(context);
    final Widget visibleDetector = FocusDetector(
        key: _focusKey,
        visibleThreshold: widget.visibleThreshold,
        onVisibilityGained: () {
          if (!mounted) return;
          _lifecycleRegistry
              .handleLifecycleEvent(lifecycle_state.LifecycleEvent.onVisible);
        },
        onVisibilityLost: () {
          if (!mounted) return;
          _lifecycleRegistry
              .handleLifecycleEvent(lifecycle_state.LifecycleEvent.onInvisible);
        },
        onForegroundGained: () {
          if (!mounted) return;
          widget.observer?.onForeground?.call(lifecycle);
        },
        onForegroundLost: () {
          if (!mounted) return;
          widget.observer?.onBackground?.call(lifecycle);
        },
        child: page);
    return visibleDetector;
  }

  @protected
  Widget buildPage(BuildContext context) {
    return widget.builder.call(context, this.lifecycle);
  }

  @override
  @mustCallSuper
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleRegistry
        .handleLifecycleEvent(lifecycle_state.LifecycleEvent.onDispose);
    lifecycle.clearObserver();
    super.dispose();
  }
}
