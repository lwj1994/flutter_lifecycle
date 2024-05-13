import 'state.dart';

/// @author luwenjie on 2023/4/22 15:26:03
///

mixin LifecycleOwner {
  Lifecycle get lifecycle;

  bool get isResumed =>
      lifecycle.currentState.isAtLeast(LifecycleState.resumed);
}

abstract class Lifecycle {
  void addObserver(Observer observer);

  void removeObserver(Observer observer);

  void clearObserver();

  LifecycleState get currentState;
  LifecycleState get previousState;

  bool get isResumed => currentState.isAtLeast(LifecycleState.resumed);
}

mixin Observer {}
