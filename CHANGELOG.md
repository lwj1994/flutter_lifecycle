## 1.1.0
* support visibleThreshold

```dart
          LifecycleAware(
            visibleThreshold: 0.3,
            observer: LifecycleObserver(onCreate: (l) {
              print("onCreate $_keyWrapper");
            }, onVisible: (l) {
              print("onVisible");
            }
            builder: (BuildContext context, Lifecycle lifecycle) {
              return Padding(
                padding: EdgeInsets.all(10),
                child: Container(
                  width: 300,
                  height: 600,
                  color: Colors.amberAccent,
                ),
              );
            },
          )

```

## 1.0.0
* support lifecycle callback 
```dart
  final Function(Lifecycle lifecycle)? onCreate;
  final Function(Lifecycle lifecycle)? onVisible;
  final Function(Lifecycle lifecycle)? onInvisible;
  final Function(Lifecycle lifecycle)? onDispose;
  final Function(Lifecycle lifecycle)? onBackground;
  final Function(Lifecycle lifecycle)? onForeground;
```