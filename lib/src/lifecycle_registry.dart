import 'dart:collection';

import 'lifecycle.dart';
import 'observer.dart';
import 'state.dart';

/// @author luwenjie on 2023/4/22 15:45:34
///
///

/// An implementation of {@link Lifecycle} that can handle multiple observers.
/// <p>
/// It is used by Fragments and Support Library Activities. You can also directly use it if you have
/// a custom LifecycleOwner.
class LifecycleRegistry extends Lifecycle {
  /// Current state
  LifecycleState _state = LifecycleState.initialized;
  LifecycleState _preState = LifecycleState.destroyed;

  /// The provider that owns this Lifecycle.
  /// Only WeakReference on LifecycleOwner is kept, so if somebody leaks Lifecycle, they won't leak
  /// the whole Fragment / Activity. However, to leak Lifecycle object isn't great idea neither,
  /// because it keeps strong references on all other listeners, so you'll leak all of them as
  /// well.
  late final WeakReference<LifecycleOwner> _lifecycleOwner;

  var _addingObserverCounter = 0;

  bool _mHandlingEvent = false;
  bool _mNewEventOccurred = false;

  // we have to keep it for cases:
  // void onStart() {
  //     mRegistry.removeObserver(this);
  //     mRegistry.add(newObserver);
  // }
  // newObserver should be brought only to CREATED state during the execution of
  // this onStart method. our invariant with mObserverMap doesn't help, because parent observer
  // is no longer in the map.
  final List<LifecycleState> _parentStates = [];

  LinkedHashMap<Observer, ObserverWithState> _observerMap = LinkedHashMap();

  LifecycleRegistry(LifecycleOwner owner) {
    _lifecycleOwner = WeakReference(owner);
  }

  /// Moves the Lifecycle to the given state and dispatches necessary events to the observers.
  ///
  /// @param state new state
  void setCurrentState(LifecycleState state) {
    _moveToState(state);
  }

  /// Sets the current state and notifies the observers.
  /// <p>
  /// Note that if the {@code currentState} is the same state as the last call to this method,
  /// calling this method has no effect.
  ///
  /// @param event The event that was received
  void handleLifecycleEvent(LifecycleEvent event) {
    _moveToState(event.getTargetState());
  }

  void _moveToState(LifecycleState next) {
    if (_state == next) {
      return;
    }
    if (_state == LifecycleState.initialized &&
        next == LifecycleState.destroyed) {
      throw StateError("no event down from ${_state}");
    }

    _preState = _state;
    _state = next;
    if (_mHandlingEvent || _addingObserverCounter != 0) {
      _mNewEventOccurred = true;
      // we will figure out what to do on upper level.
      return;
    }
    _mHandlingEvent = true;
    _sync();
    _mHandlingEvent = false;
    if (_state == LifecycleState.destroyed) {
      _observerMap = LinkedHashMap();
    }
  }

  bool isSynced() {
    if (_observerMap.isEmpty) {
      return true;
    }
    final entries = _observerMap.entries.toList();
    LifecycleState eldestObserverState = entries.first.value.state;
    LifecycleState newestObserverState = entries.last.value.state;
    return eldestObserverState == newestObserverState &&
        _state == newestObserverState;
  }

  LifecycleState calculateTargetState(Observer observer) {
    final entries = _observerMap.entries.toList();
    MapEntry<Observer, ObserverWithState>? previous;
    for (int index = 0; index < entries.length; index++) {
      final element = entries[index];
      if (identical(element.key, observer)) {
        if (index - 1 >= 0) {
          previous = entries[index - 1];
        }
      }
    }
    LifecycleState? siblingState = previous?.value.state;
    LifecycleState? parentState =
        _parentStates.isNotEmpty ? _parentStates.last : null;
    return _min(_min(_state, siblingState), parentState);
  }

  static LifecycleState _min(LifecycleState state1, LifecycleState? state2) {
    return state2 != null && state2.index < state1.index ? state2 : state1;
  }

  @override
  void addObserver(Observer observer) {
    LifecycleState initialState = _state == LifecycleState.destroyed
        ? LifecycleState.destroyed
        : LifecycleState.initialized;
    ObserverWithState statefulObserver =
        ObserverWithState.observer(observer, state: initialState);
    ObserverWithState previous = _observerMap.putIfAbsent(observer, () {
      return statefulObserver;
    });

    if (!identical(previous, statefulObserver)) {
      return;
    }
    LifecycleOwner? lifecycleOwner = _lifecycleOwner.target;
    if (lifecycleOwner == null) {
      // it is null we should be destroyed. Fallback quickly
      return;
    }

    bool isReentrance = _addingObserverCounter != 0 || _mHandlingEvent;
    LifecycleState targetState = calculateTargetState(observer);
    _addingObserverCounter++;
    while ((statefulObserver.state.index < targetState.index &&
        _observerMap.containsKey(observer))) {
      pushParentState(statefulObserver.state);
      final LifecycleEvent? event =
          LifecycleEvent.upFrom(statefulObserver.state);
      if (event == null) {
        throw StateError("no event up from ${statefulObserver.state}");
      }
      statefulObserver.dispatchEvent(lifecycleOwner, event);
      popParentState();
      // mState / subling may have been changed recalculate
      targetState = calculateTargetState(observer);
    }

    if (!isReentrance) {
      // we do sync only on the top level.
      _sync();
    }
    _addingObserverCounter--;
  }

  void popParentState() {
    _parentStates.removeLast();
  }

  void pushParentState(LifecycleState state) {
    _parentStates.add(state);
  }

  @override
  void removeObserver(Observer observer) {
    // we consciously decided not to send destruction events here in opposition to addObserver.
    // Our reasons for that:
    // 1. These events haven't yet happened at all. In contrast to events in addObservers, that
    // actually occurred but earlier.
    // 2. There are cases when removeObserver happens as a consequence of some kind of fatal
    // event. If removeObserver method sends destruction events, then a clean up routine becomes
    // more cumbersome. More specific example of that is: your LifecycleObserver listens for
    // a web connection, in the usual routine in OnStop method you report to a server that a
    // session has just ended and you close the connection. Now let's assume now that you
    // lost an internet and as a result you removed this observer. If you get destruction
    // events in removeObserver, you should have a special case in your onStop method that
    // checks if your web connection died and you shouldn't try to report anything to a server.
    _observerMap.remove(observer);
  }

  @override
  void clearObserver() {
    _observerMap.clear();
  }

  /// The number of observers.
  ///
  /// @return The number of observers.
  int getObserverCount() {
    return _observerMap.length;
  }

  @override
  LifecycleState get currentState {
    return _state;
  }

  void forwardPass(LifecycleOwner lifecycleOwner) {
    Iterator<MapEntry<Observer, ObserverWithState>> ascendingIterator =
        _observerMap.entries.toList().iterator;
    while (ascendingIterator.moveNext() && !_mNewEventOccurred) {
      MapEntry<Observer, ObserverWithState> entry = ascendingIterator.current;
      ObserverWithState observer = entry.value;
      while ((observer.state.index < _state.index &&
          !_mNewEventOccurred &&
          _observerMap.containsKey(entry.key))) {
        pushParentState(observer.state);
        final LifecycleEvent? event = LifecycleEvent.upFrom(observer.state);
        if (event == null) {
          throw StateError("no event up from ${observer.state}");
        }
        observer.dispatchEvent(lifecycleOwner, event);
        popParentState();
      }
    }
  }

  void backwardPass(LifecycleOwner lifecycleOwner) {
    Iterator<MapEntry<Observer, ObserverWithState>> descendingIterator =
        _observerMap.entries.toList().reversed.iterator;
    while (descendingIterator.moveNext() && !_mNewEventOccurred) {
      MapEntry<Observer, ObserverWithState> entry = descendingIterator.current;
      ObserverWithState observer = entry.value;
      while ((observer.state.index > _state.index &&
          !_mNewEventOccurred &&
          _observerMap.containsKey(entry.key))) {
        LifecycleEvent? event = LifecycleEvent.downFrom(observer.state);
        if (event == null) {
          throw StateError("no event down from ${observer.state}");
        }
        pushParentState(event.getTargetState());
        observer.dispatchEvent(lifecycleOwner, event);
        popParentState();
      }
    }
  }

  // happens only on the top of stack (never in reentrance),
  // so it doesn't have to take in account parents
  void _sync() {
    LifecycleOwner? lifecycleOwner = _lifecycleOwner.target;
    if (lifecycleOwner == null) {
      throw StateError("LifecycleOwner of this LifecycleRegistry is already" +
          "garbage collected. It is too late to change lifecycle state.");
    }
    while (!isSynced()) {
      _mNewEventOccurred = false;
      // no need to check eldest for nullability, because isSynced does it for us.
      if (_state.index < _observerMap.entries.first.value.state.index) {
        backwardPass(lifecycleOwner);
      }
      MapEntry<Observer, ObserverWithState>? newest =
          _observerMap.entries.lastOrNull;
      if (!_mNewEventOccurred &&
          newest != null &&
          _state.index > newest.value.state.index) {
        forwardPass(lifecycleOwner);
      }
    }
    _mNewEventOccurred = false;
  }

  @override
  LifecycleState get previousState => _preState;
}

class ObserverWithState {
  LifecycleState state;
  _LifecycleEventObserver lifecycleObserver;

  ObserverWithState._({required this.state, required this.lifecycleObserver});

  factory ObserverWithState.observer(Observer observer,
      {required LifecycleState state}) {
    return ObserverWithState._(
        state: state,
        lifecycleObserver: _LifecycleEventObserverAdapter(observer));
  }

  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    LifecycleState newState = event.getTargetState();
    if (newState.index < state.index) {
      state = newState;
    }
    lifecycleObserver.onStateChanged(owner, event);
    state = newState;
  }
}

class _LifecycleEventObserverAdapter extends _LifecycleEventObserver {
  final Observer observer;

  _LifecycleEventObserverAdapter(this.observer);

  @override
  void onStateChanged(LifecycleOwner source, LifecycleEvent event) {
    LifecycleObserver? fullLifecycleObserver;
    _LifecycleEventObserver? lifecycleEventObserver;
    if (observer is LifecycleObserver) {
      fullLifecycleObserver = observer as LifecycleObserver?;
    } else if (observer is _LifecycleEventObserver) {
      lifecycleEventObserver = observer as _LifecycleEventObserver?;
    }
    lifecycleEventObserver?.onStateChanged(source, event);
    switch (event) {
      case LifecycleEvent.onCreate:
        fullLifecycleObserver?.onCreate?.call(source.lifecycle);
        break;
      case LifecycleEvent.onVisible:
        fullLifecycleObserver?.onVisible?.call(source.lifecycle);
        break;
      case LifecycleEvent.onInvisible:
        fullLifecycleObserver?.onInvisible?.call(source.lifecycle);
        break;
      case LifecycleEvent.onDispose:
        fullLifecycleObserver?.onDispose?.call(source.lifecycle);
        break;
      case LifecycleEvent.onAny:
        break;
    }
  }
}

abstract class _LifecycleEventObserver with Observer {
  /// Called when a state transition event happens.
  ///
  /// @param source The source of the event
  /// @param event The event
  void onStateChanged(LifecycleOwner source, LifecycleEvent event);
}
