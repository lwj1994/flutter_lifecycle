import 'package:flutter/material.dart';
import 'package:widget_lifecycle/widget_lifecycle.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return LifecycleListExample();
  }
}

class LifecycleExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<LifecycleExample> {
  final logs = <String>[];
  GlobalKey _keyWrapper = GlobalKey();
  ValueKey _key = ValueKey("FIX");
  GlobalKey _keyContent = GlobalKey();
  final LifecycleController controller = LifecycleController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
      ),
      body: Column(
        key: _keyWrapper,
        children: [
          FilledButton(
              onPressed: () {
                controller.trigger();
              },
              child: Text("change key")),
          LifecycleAware(
            key: _key,
            onCreate: () {
              print("\n");
              print("onCreate $_keyWrapper");
              // print("old = ${l.previousState.name}");
              // print(l.currentState.name);
            },
            controller: controller,
            onShow: () {
              print("\n");
              print("onVisible $_keyWrapper");
              // print("old = ${l.previousState.name}");
              // print(l.currentState.name);
            },
            onHide: () {
              print("\n");
              print("onInvisible $_keyWrapper");
              // print("old = ${l.previousState.name}");
              // print(l.currentState.name);
            },
            onDestroy: () {
              print("\n");
              print("onDestroy $_keyWrapper");
              // print("old = ${l.previousState.name}");
              // print(l.currentState.name);
            },
            onAppResume: () {
              print("\n");
              print("onForeground $_keyWrapper");
              // print("old = ${l.previousState.name}");
              // print(l.currentState.name);
            },
            onAppPause: () {
              print("\n");
              print("onBackground $_keyWrapper");
              // print("old = ${l.previousState.name}");
              // print(l.currentState.name);
            },
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Container(
                width: 300,
                height: 600,
                color: Colors.amberAccent,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class LifecycleListExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ListState();
  }
}

class _ListState extends State<LifecycleListExample> {
  final logs = <String>[];
  GlobalKey _keyWrapper = GlobalKey();
  GlobalKey _key = GlobalKey();
  GlobalKey _keyContent = GlobalKey();
  final LifecycleController controller = LifecycleController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
      ),
      body: Column(
        key: _keyWrapper,
        children: [
          FilledButton(
              onPressed: () {
                controller.trigger();
              },
              child: Text("change key")),
          LifecycleAware(
            controller: controller,
            key: ValueKey("FIXed"),
            onShow: () {
              debugPrint("\n");
              debugPrint("onVisible FIXed");
            },
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Container(
                height: 100,
                alignment: Alignment.center,
                color: Colors.blueAccent,
                child: Text(
                  "FIXed",
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemBuilder: (c, i) {
                return LifecycleAware(
                  key: ValueKey(i),
                  showVisibilityThreshold: 0.5,
                  hideVisibilityThreshold: 0.2,
                  onShow: () {
                    debugPrint("onShow $i");
                  },
                  onHide: () {
                    debugPrint("onHide $i");
                  },
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Container(
                      height: 100,
                      alignment: Alignment.bottomCenter,
                      color: Colors.blueAccent,
                      child: Container(
                        height: 100 * 0.2,
                        color: Colors.amber,
                        child: Text(
                          i.toString(),
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                );
              },
              itemCount: 20,
            ),
          ),
        ],
      ),
    );
  }
}
