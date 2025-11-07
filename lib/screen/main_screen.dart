import 'package:auto_channel_market_publish/widget/append_channel_dialog_widget.dart';
import 'package:auto_channel_market_publish/widget/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../net/xiaomi_manager.dart';

///@Author jsji
///@Date 2025/8/21
///
///@Description

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  //note 导入配置
                },
                child: Text("配置导入"),
              ),
              ElevatedButton(
                onPressed: () {
                  //note 导出配置
                },
                child: Text("配置导出"),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("apk文件目录:"),
              ElevatedButton(
                onPressed: () {
                  //note 导入配置
                },
                child: Text("选择"),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("渠道配置:"),
              GestureDetector(
                onTap: () {
                  //note 新增
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AppendChannelDialogWidget();
                    },
                  );
                },
                child: Text("  新增  ", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          Text("渠道配置json"),
          ElevatedButton(
            onPressed: () {
              //note 验证
              XiaomiManager()
                  .queryApkConfig(packageName: "com.fungo.loveshow.tuhao", userName: "zhymmarket@126.com")
                  .then((v) {
                    print(v.toJson().toString());
                    //可用于查询是否上线成功   检查versionCode是否匹配
                  });
            },
            child: Text("验证"),
          ),
        ],
      ),
    );
  }
}
