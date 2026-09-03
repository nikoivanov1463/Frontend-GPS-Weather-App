import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  WebViewController webViewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(
      onProgress: (int progress) {},
      onHttpError: (HttpResponseError httpError) {},
      onWebResourceError: (WebResourceError webError) {},
      // onNavigationRequest: (NavigationRequest request) {
      //   if (request.url.contains("https://google.com")) {
      //     return NavigationDecision.navigate;
      //   } else {
      //     return NavigationDecision.prevent;
      //   }
      // },
    ))
    ..loadRequest(Uri.parse("https://www.geotrack24.com/bg"));

  // Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    // _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    //   checkSession();
    // });
  }

  // Future<bool> checkSession() async {
  //   String sessionValid = await LoginMethods.checkSessionStatus();
  //
  //   if (sessionValid != "Session is valid.") {
  //     if (mounted) {
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(
  //           builder: (BuildContext context) => const CredentialHomeScreen(),
  //         ),
  //             (Route<dynamic> route) => false,
  //       );
  //     }
  //
  //     return false;
  //   } else {
  //     return true;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Flexible(
        child: WebViewWidget(
          controller: webViewController,
        ),
      ),
    ]);
    // return const Center(
    //   child: Text(
    //     'Tracker Page',
    //     style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
    //   ),
    // );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
