import 'package:flutter/cupertino.dart';

import 'lifecycle.dart';

/// @author luwenjie on 2023/4/22 15:54:00
///

@immutable
class LifecycleObserver with Observer {
  final Function(Lifecycle lifecycle)? onCreate;
  final Function(Lifecycle lifecycle)? onVisible;
  final Function(Lifecycle lifecycle)? onInvisible;
  final Function(Lifecycle lifecycle)? onDispose;
  final Function(Lifecycle lifecycle)? onBackground;
  final Function(Lifecycle lifecycle)? onForeground;

  LifecycleObserver({
    this.onCreate,
    this.onVisible,
    this.onInvisible,
    this.onDispose,
    this.onBackground,
    this.onForeground,
  });
}
