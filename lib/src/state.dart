/// @author luwenjie on 2023/4/22 21:43:06

enum LifecycleState {
  /// Destroyed state for a LifecycleOwner. After this event, this Lifecycle will not dispatch
  /// any more events. For instance, for an {@link android.app.Activity}, this state is reached
  /// <b>right before</b> Activity's {@link android.app.Activity#onDestroy() onDestroy} call.
  destroyed,

  /// Initialized state for a LifecycleOwner. For an {@link android.app.Activity}, this is
  /// the state when it is constructed but has not received
  initialized,

  /// Created state for a LifecycleOwner. For an {@link android.app.Activity}, this state
  /// is reached in two cases:
  created,

  /// Resumed state for a LifecycleOwner. For an {@link android.app.Activity}, this state
  /// is reached after {@link android.app.Activity#onResume() onResume} is called.
  resumed;

  /// Compares if this State is greater or equal to the given {@code state}.
  ///
  /// @param state State to compare with
  /// @return true if this State is greater or equal to the given {@code state}
  bool isAtLeast(LifecycleState state) {
    return index >= state.index;
  }
}

enum LifecycleEvent {
  /// Constant for onCreate event of the {@link LifecycleOwner}.
  onCreate,

  /// Constant for onResume event of the {@link LifecycleOwner}.
  onVisible,

  /// Constant for onPause event of the {@link LifecycleOwner}.
  onInvisible,

  /// Constant for onDestroy event of the {@link LifecycleOwner}.
  onDispose,

  /// An {@link Event Event} constant that can be used to match all events.
  onAny;

  /// Returns the {@link Lifecycle.Event} that will be reported by a {@link Lifecycle}
  /// leaving the specified {@link Lifecycle.State} to a lower state, or {@code null}
  /// if there is no valid event that can move down from the given state.
  ///
  /// @param state the higher state that the returned event will transition down from
  /// @return the event moving down the lifecycle phases from state
  static LifecycleEvent? downFrom(LifecycleState state) {
    switch (state) {
      case LifecycleState.created:
        return LifecycleEvent.onDispose;
      case LifecycleState.resumed:
        return LifecycleEvent.onInvisible;
      default:
        return null;
    }
  }

  /// Returns the {@link Lifecycle.Event} that will be reported by a {@link Lifecycle}
  /// entering the specified {@link Lifecycle.State} from a higher state, or {@code null}
  /// if there is no valid event that can move down to the given state.
  ///
  /// @param state the lower state that the returned event will transition down to
  /// @return the event moving down the lifecycle phases to state
  LifecycleEvent? downTo(LifecycleState state) {
    switch (state) {
      case LifecycleState.destroyed:
        return LifecycleEvent.onDispose;
      case LifecycleState.created:
        return LifecycleEvent.onInvisible;
      default:
        return null;
    }
  }

  /// Returns the {@link Lifecycle.Event} that will be reported by a {@link Lifecycle}
  /// leaving the specified {@link Lifecycle.State} to a higher state, or {@code null}
  /// if there is no valid event that can move up from the given state.
  ///
  /// @param state the lower state that the returned event will transition up from
  /// @return the event moving up the lifecycle phases from state
  static LifecycleEvent? upFrom(LifecycleState state) {
    switch (state) {
      case LifecycleState.initialized:
        return LifecycleEvent.onCreate;
      case LifecycleState.created:
        return LifecycleEvent.onVisible;
      default:
        return null;
    }
  }

  /// Returns the {@link Lifecycle.Event} that will be reported by a {@link Lifecycle}
  /// entering the specified {@link Lifecycle.State} from a lower state, or {@code null}
  /// if there is no valid event that can move up to the given state.
  ///
  /// @param state the higher state that the returned event will transition up to
  /// @return the event moving up the lifecycle phases to state
  static LifecycleEvent? upTo(LifecycleState state) {
    switch (state) {
      case LifecycleState.created:
        return LifecycleEvent.onCreate;
      case LifecycleState.resumed:
        return LifecycleEvent.onVisible;
      default:
        return null;
    }
  }

  /// Returns the new {@link Lifecycle.State} of a {@link Lifecycle} that just reported
  /// this {@link Lifecycle.Event}.
  ///
  /// Throws {@link IllegalArgumentException} if called on {@link #ON_ANY}, as it is a special
  /// value used by {@link OnLifecycleEvent} and not a real lifecycle event.
  ///
  /// @return the state that will result from this event
  LifecycleState getTargetState() {
    switch (this) {
      case LifecycleEvent.onCreate:
      case LifecycleEvent.onInvisible:
        return LifecycleState.created;

      case LifecycleEvent.onVisible:
        return LifecycleState.resumed;
      case LifecycleEvent.onDispose:
        return LifecycleState.destroyed;
      case LifecycleEvent.onAny:
        break;
    }
    throw ArgumentError("$this has no target state");
  }
}
