inspired by android.lifecycle
## Getting Started

```dart
final controller = LifecycleController();
LifecycleAware(
    key: ValueKey("id"),
    controller: controller,
    onShow: () {
      debugPrint("onShow");
    },
    onHide: (){
    
    },
    showVisibilityThreshold: 0.5,
    hideVisibilityThreshold: 0.1,
    child: xxxx,
);


controller.trigger();

// resumed
controller.state == LifecycleState.resumed;
```