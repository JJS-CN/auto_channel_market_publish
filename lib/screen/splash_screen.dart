import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../const/screen_const.dart';

///@Author jsji
///@Date 2025/8/21
///
///@Description

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1)).then((v) {
      GoRouter.of(context).go(ScreenConst.main);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("启动页"), centerTitle: true),
      body: Column(children: []),
    );
  }
}
