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