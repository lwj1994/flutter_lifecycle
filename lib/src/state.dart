/// @author luwenjie on 2024/6/19 21:24:38

enum LifecycleState {
  /// Destroyed state for a LifecycleOwner. After this event, this Lifecycle will not dispatch
  /// any more events. For instance, for an {@link android.app.Activity}, this state is reached
  /// <b>right before</b> Activity's {@link android.app.Activity#onDestroy() onDestroy} call.
  destroyed,
  created,
  hidden,
  resumed;

  /// Compares if this State is greater or equal to the given {@code state}.
  ///
  /// @param state State to compare with
  /// @return true if this State is greater or equal to the given {@code state}
  bool isAtLeast(LifecycleState state) {
    return index >= state.index;
  }
}
