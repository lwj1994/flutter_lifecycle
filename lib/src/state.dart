/// Lifecycle state management for Flutter widgets.
///
/// This library provides lifecycle state definitions and utilities
/// for managing widget lifecycle events.
library;

/// @author luwenjie on 2024/6/19 21:24:38

/// Represents the lifecycle state of a widget.
///
/// This enum mirrors Android's Lifecycle.State and provides a way to track
/// the current state of a widget's lifecycle. States are ordered from least
/// to most active.
///
/// The lifecycle progression typically follows:
/// created -> resumed -> hidden -> destroyed
enum LifecycleState {
  /// Destroyed state for a LifecycleOwner.
  ///
  /// After this event, this Lifecycle will not dispatch any more events.
  /// For instance, for an Activity, this state is reached right before
  /// Activity's onDestroy() call.
  destroyed,

  /// Created state indicates the widget has been initialized but may not be visible.
  created,

  /// Hidden state indicates the widget is not currently visible to the user.
  hidden,

  /// Resumed state indicates the widget is visible and active.
  resumed;

  /// Compares if this State is greater or equal to the given [state].
  ///
  /// This method is useful for checking if the current lifecycle state
  /// meets a minimum requirement.
  ///
  /// Example:
  /// ```dart
  /// if (currentState.isAtLeast(LifecycleState.resumed)) {
  ///   // Widget is visible and can perform operations
  /// }
  /// ```
  ///
  /// @param state State to compare with
  /// @return true if this State is greater or equal to the given [state]
  bool isAtLeast(LifecycleState state) {
    return index >= state.index;
  }

  /// Returns true if the lifecycle state indicates the widget is active.
  ///
  /// A widget is considered active when it's in the [resumed] state.
  bool get isActive => this == LifecycleState.resumed;

  /// Returns true if the lifecycle state indicates the widget is destroyed.
  ///
  /// A destroyed widget should not perform any operations.
  bool get isDestroyed => this == LifecycleState.destroyed;

  /// Returns a human-readable description of the lifecycle state.
  String get description {
    switch (this) {
      case LifecycleState.destroyed:
        return 'Widget has been destroyed and should not be used';
      case LifecycleState.created:
        return 'Widget has been created but may not be visible';
      case LifecycleState.hidden:
        return 'Widget is not currently visible to the user';
      case LifecycleState.resumed:
        return 'Widget is visible and active';
    }
  }
}
