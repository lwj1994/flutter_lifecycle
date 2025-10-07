# Widget Lifecycle

[![pub package](https://img.shields.io/pub/v/widget_lifecycle.svg)](https://pub.dev/packages/widget_lifecycle)

A Flutter package inspired by Android's Lifecycle components that provides lifecycle management for Flutter widgets. It tracks widget visibility and app lifecycle states, triggering appropriate callbacks when state changes occur.

## Features

- 🔄 **Widget Lifecycle Management**: Track when widgets are created, shown, hidden, and destroyed
- 👁️ **Visibility Detection**: Monitor widget visibility with customizable thresholds
- 📱 **App Lifecycle Integration**: Respond to app foreground/background state changes
- 🎯 **Precise Control**: Fine-grained control over when callbacks are triggered
- 🧪 **Testing Support**: Built-in support for widget testing
- 🛡️ **Error Handling**: Robust error handling and edge case management

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  widget_lifecycle: ^1.4.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Usage

```dart
import 'package:widget_lifecycle/widget_lifecycle.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LifecycleAware(
      onCreate: () => print('Widget created'),
      onShow: () => print('Widget is now visible'),
      onHide: () => print('Widget is now hidden'),
      onDestroy: () => print('Widget destroyed'),
      child: Container(
        height: 200,
        color: Colors.blue,
        child: Center(child: Text('Hello World')),
      ),
    );
  }
}
```

### Advanced Usage with Controller

```dart
class MyAdvancedWidget extends StatefulWidget {
  @override
  _MyAdvancedWidgetState createState() => _MyAdvancedWidgetState();
}

class _MyAdvancedWidgetState extends State<MyAdvancedWidget> {
  final LifecycleController controller = LifecycleController();

  @override
  Widget build(BuildContext context) {
    return LifecycleAware(
      controller: controller,
      showVisibilityThreshold: 0.5,  // 50% visible to trigger onShow
      hideVisibilityThreshold: 0.1,  // 10% visible to trigger onHide
      callShowOnAppResume: true,      // Call onShow when app resumes
      callHideOnAppPause: true,       // Call onHide when app pauses
      onCreate: _handleCreate,
      onShow: _handleShow,
      onHide: _handleHide,
      onDestroy: _handleDestroy,
      onAppResume: _handleAppResume,
      onAppPause: _handleAppPause,
      child: YourWidget(),
    );
  }

  void _handleCreate() {
    print('Widget lifecycle: Created');
    // Initialize resources, start timers, etc.
  }

  void _handleShow() {
    print('Widget lifecycle: Visible');
    // Start animations, resume video playback, etc.
  }

  void _handleHide() {
    print('Widget lifecycle: Hidden');
    // Pause animations, stop video playback, etc.
  }

  void _handleDestroy() {
    print('Widget lifecycle: Destroyed');
    // Clean up resources, dispose controllers, etc.
  }

  void _handleAppResume() {
    print('App lifecycle: Resumed');
    // Handle app coming to foreground
  }

  void _handleAppPause() {
    print('App lifecycle: Paused');
    // Handle app going to background
  }

  void _manuallyTriggerCallbacks() {
    // Manually trigger lifecycle callbacks
    controller.trigger();
  }

  void _checkCurrentState() {
    if (controller.state == LifecycleState.resumed) {
      print('Widget is currently visible and active');
    }
    
    if (controller.state.isAtLeast(LifecycleState.created)) {
      print('Widget is at least created');
    }
  }
}
```

## API Reference

### LifecycleAware

The main widget that provides lifecycle management.

#### Constructor Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `child` | `Widget` | required | The widget to wrap with lifecycle management |
| `controller` | `LifecycleController?` | `null` | Optional controller for external state management |
| `showVisibilityThreshold` | `double` | `1.0` | Threshold (0.0-1.0) for triggering onShow callback |
| `hideVisibilityThreshold` | `double` | `0.0` | Threshold (0.0-1.0) for triggering onHide callback |
| `onCreate` | `VoidCallback?` | `null` | Called when widget is first created |
| `onShow` | `VoidCallback?` | `null` | Called when widget becomes visible |
| `onHide` | `VoidCallback?` | `null` | Called when widget becomes hidden |
| `onDestroy` | `VoidCallback?` | `null` | Called when widget is destroyed |
| `onAppResume` | `VoidCallback?` | `null` | Called when app resumes from background |
| `onAppPause` | `VoidCallback?` | `null` | Called when app goes to background |
| `callShowOnAppResume` | `bool` | `false` | Whether to call onShow when app resumes |
| `callHideOnAppPause` | `bool` | `false` | Whether to call onHide when app pauses |
| `isWidgetTest` | `bool?` | `null` | Set to true for widget testing |

#### Constraints

- `showVisibilityThreshold` must be greater than `hideVisibilityThreshold`
- Both thresholds must be between 0.0 and 1.0 inclusive

### LifecycleController

Controller for managing lifecycle state externally.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `state` | `LifecycleState` | Current lifecycle state |
| `previousState` | `LifecycleState?` | Previous lifecycle state |
| `isDisposed` | `bool` | Whether controller has been disposed |

#### Methods

| Method | Description |
|--------|-------------|
| `trigger()` | Manually trigger lifecycle callbacks |

### LifecycleState

Enum representing the lifecycle state of a widget.

| State | Description |
|-------|-------------|
| `destroyed` | Widget has been destroyed and should not be used |
| `created` | Widget has been created but may not be visible |
| `hidden` | Widget is not currently visible to the user |
| `resumed` | Widget is visible and active |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `isAtLeast(LifecycleState state)` | `bool` | Check if current state is at least the given state |
| `isActive` | `bool` | True if widget is in resumed state |
| `isDestroyed` | `bool` | True if widget is destroyed |
| `description` | `String` | Human-readable description of the state |

## Use Cases

### Video Player

```dart
LifecycleAware(
  onShow: () => videoController.play(),
  onHide: () => videoController.pause(),
  onDestroy: () => videoController.dispose(),
  child: VideoPlayer(videoController),
)
```

### Analytics Tracking

```dart
LifecycleAware(
  onShow: () => analytics.trackScreenView('MyScreen'),
  onHide: () => analytics.trackScreenExit('MyScreen'),
  child: MyScreen(),
)
```

### Resource Management

```dart
LifecycleAware(
  onCreate: () => _initializeResources(),
  onDestroy: () => _cleanupResources(),
  onShow: () => _startPeriodicUpdates(),
  onHide: () => _stopPeriodicUpdates(),
  child: MyResourceIntensiveWidget(),
)
```

### Animation Control

```dart
LifecycleAware(
  onShow: () => animationController.repeat(),
  onHide: () => animationController.stop(),
  child: AnimatedWidget(animation: animationController),
)
```

## Best Practices

### 1. Threshold Configuration

Choose appropriate visibility thresholds based on your use case:

```dart
// For critical content that should be fully visible
LifecycleAware(
  showVisibilityThreshold: 1.0,  // 100% visible
  hideVisibilityThreshold: 0.9,  // 90% visible
  // ...
)

// For less critical content
LifecycleAware(
  showVisibilityThreshold: 0.5,  // 50% visible
  hideVisibilityThreshold: 0.1,  // 10% visible
  // ...
)
```

### 2. Resource Management

Always clean up resources in the appropriate callbacks:

```dart
LifecycleAware(
  onCreate: () {
    // Initialize resources
    timer = Timer.periodic(Duration(seconds: 1), _updateData);
  },
  onDestroy: () {
    // Clean up resources
    timer?.cancel();
    subscription?.cancel();
  },
  // ...
)
```

### 3. Error Handling

The package includes built-in error handling, but you should still handle errors in your callbacks:

```dart
LifecycleAware(
  onShow: () {
    try {
      // Your code here
    } catch (e) {
      // Handle errors appropriately
      print('Error in onShow: $e');
    }
  },
  // ...
)
```

### 4. Testing

For widget tests, set `isWidgetTest: true` to ensure immediate visibility updates:

```dart
testWidgets('lifecycle callbacks work correctly', (tester) async {
  bool onShowCalled = false;
  
  await tester.pumpWidget(
    LifecycleAware(
      isWidgetTest: true,
      onShow: () => onShowCalled = true,
      child: Container(),
    ),
  );
  
  expect(onShowCalled, isTrue);
});
```

## Migration Guide

### From 1.3.x to 1.4.0

The API remains backward compatible. New features include:

- Enhanced error handling
- Better parameter validation
- Improved documentation
- Additional utility methods on `LifecycleState`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Inspiration

This package is inspired by [Android's Lifecycle components](https://developer.android.com/topic/libraries/architecture/lifecycle), bringing similar lifecycle management concepts to Flutter.