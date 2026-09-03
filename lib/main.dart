import 'package:flutter/material.dart';

import 'package:tracking_app/app_navigation.dart';
import 'package:tracking_app/helper_methods/authentication/auth_helpers.dart';
import 'package:tracking_app/pages/credential_home_screen.dart';
import 'package:tracking_app/pages/login.dart';
import 'package:tracking_app/pages/register.dart';
import 'package:tracking_app/pages/weather_page.dart';
import 'package:tracking_app/pages/map_widget.dart';
import 'dio/config.dart';

void main() {
  final dio = DIOConfig().dio;

  final authHelpers = AuthHelpers(dio: dio);

  runApp(MyApp(authHelpers: authHelpers));
}

class MyApp extends StatelessWidget {
  final AuthHelpers authHelpers;

  const MyApp({super.key, required this.authHelpers});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Tracking App',
      initialRoute: "/",
      routes: {
        "/": (context) => CredentialHomeScreen(authHelpers: authHelpers),
        "/login": (context) => LoginPage(authHelpers: authHelpers),
        "/register": (context) => const RegisterPage(),
        "/home": (context) => HomePage(authHelpers: authHelpers),
        "/map": (context) => const MapWidget(),
        "/weather": (context) => const WeatherPage(),
      },
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          centerTitle: true,
        ),
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.white, primary: Colors.blue),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final AuthHelpers authHelpers;

  const HomePage({super.key, required this.authHelpers});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  static final List<Widget> _pages = <Widget>[
    const MapWidget(),
    const WeatherPage(),
  ];

  static final List<String> _titles = <String>[
    'Map',
    'Weather',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    // return Scaffold(
    //   appBar: AppBar(
    //     // Here we take the value from the MyHomePage object that was created by
    //     // the App.build method, and use it to set our appbar title.
    //     title: Text(_titles[selectedPageIndex]),
    //     key: _scaffoldKey,
    //     centerTitle: true,
    //     actions: [
    //       Flex(
    //         direction: Axis.horizontal,
    //         mainAxisAlignment: MainAxisAlignment.end,
    //         children: [
    //           TextButton(
    //               child: const Text("Logout"),
    //               onPressed: () {
    //                 LoginMethods.logout(context);
    //               }),
    //         ],
    //       )
    //     ],
    //   ),
    //   body: Center(
    //     // Center is a layout widget. It takes a single child and positions it
    //     // in the middle of the parent.
    //     child: Column(
    //       // Column is also a layout widget. It takes a list of children and
    //       // arranges them vertically. By default, it sizes itself to fit its
    //       // children horizontally, and tries to be as tall as its parent.
    //       //
    //       // Invoke "debug painting" (press "p" in the console, choose the
    //       // "Toggle Debug Paint" action from the Flutter Inspector in Android
    //       // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
    //       // to see the wireframe for each widget.
    //       //
    //       // Column has various properties to control how it sizes itself and
    //       // how it positions its children. Here we use mainAxisAlignment to
    //       // center the children vertically; the main axis here is the vertical
    //       // axis because Columns are vertical (the cross axis would be
    //       // horizontal).
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: <Widget>[
    //         _pages[selectedPageIndex],
    //       ],
    //     ),
    //   ),
    //   bottomNavigationBar: BottomNavigationBar(
    //     items: const <BottomNavigationBarItem>[
    //       BottomNavigationBarItem(
    //           icon: Icon(Icons.map_sharp), label: 'Map', tooltip: "Map Page"),
    //       BottomNavigationBarItem(
    //           icon: Icon(Icons.cloud),
    //           label: 'Weather',
    //           tooltip: "Weather Page"),
    //       BottomNavigationBarItem(
    //           icon: Icon(Icons.location_on_sharp),
    //           label: "Tracker",
    //           tooltip: "Tracker Page"),
    //     ],
    //     currentIndex: selectedPageIndex,
    //     selectedItemColor: Colors.blue,
    //     onTap: changePage,
    //   ), // This trailing comma makes auto-formatting nicer for build methods.
    // );
    return AppScreen(
        key: const Key('mainAppScreen'),
        pages: _pages,
        titles: _titles,
        navBarItems: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.map_sharp), label: 'Map', tooltip: "Map Page"),
          BottomNavigationBarItem(
              icon: Icon(Icons.cloud),
              label: 'Weather',
              tooltip: "Weather Page"),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.location_on_sharp),
          //     label: "Tracker",
          //     tooltip: "Tracker Page"),
        ],
        actions: [
          Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  child: const Text("Logout"),
                  onPressed: () async {
                    final result = await widget.authHelpers.logout();

                    if (result == 200 && context.mounted) {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 30.00,
                            ),
                            content: const Text(
                              "Logged out successfully",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Close"),
                              ),
                            ],
                          );
                        },
                      );

                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) =>
                                CredentialHomeScreen(
                                    authHelpers: widget.authHelpers),
                          ),
                              (_) => false,
                        );
                      }
                    }
                  })
            ],
          )
        ]);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
