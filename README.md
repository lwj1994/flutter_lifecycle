inspired by android.lifecycle
## Getting Started

```dart
LifecycleAware(
        observer: LifecycleObserver(onCreate: (l) {
          print("\n");
          print("onCreate");
          print("old = ${l.previousState.name}");
          print(l.currentState.name);
        }, onVisible: (l) {
          print("\n");
          print("onVisible");
          print("old = ${l.previousState.name}");
          print(l.currentState.name);
        }, onBackground: (l) {
          print("\n");
          print("onBackground");
          print("old = ${l.previousState.name}");
          print(l.currentState.name);
        },onDispose: (l){
          print("\n");
          print("onDispose");
          print("old = ${l.previousState.name}");
          print(l.currentState.name);
        },onForeground: (l){
          print("\n");
          print("onForeground");
          print("old = ${l.previousState.name}");
          print(l.currentState.name);
        },onInvisible: (l){
          print("\n");
          print("onInvisible");
          print("old = ${l.previousState.name}");
          print(l.currentState.name);
        }),
        builder: (BuildContext context, Lifecycle lifecycle) {
          return Center();
        },
      )
```