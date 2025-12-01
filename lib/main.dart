import 'package:auto_channel_market_publish/screen/edit_channel_config_screen.dart';
import 'package:auto_channel_market_publish/screen/main_screen.dart';
import 'package:auto_channel_market_publish/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

import 'const/screen_const.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: AppBarTheme(backgroundColor: Colors.white),
      ),
      routerConfig: _router,
      builder: FlutterSmartDialog.init(),
    );
  }

  final GoRouter _router = GoRouter(
    observers: [FlutterSmartDialog.observer],
    routes: <RouteBase>[
      GoRoute(
        path: ScreenConst.splash,
        builder: (BuildContext context, GoRouterState state) {
          return SplashScreen();
        },
      ),
      GoRoute(
        path: ScreenConst.main,
        builder: (BuildContext context, GoRouterState state) {
          return MainScreen();
        },
      ),
      GoRoute(
        path: ScreenConst.editChannelConfig,
        builder: (BuildContext context, GoRouterState state) {
          return EditChannelConfigScreen();
        },
      ),
    ],
  );
}
