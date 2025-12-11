import 'dart:convert';
import 'dart:io';

import 'package:auto_channel_market_publish/const/screen_const.dart';
import 'package:auto_channel_market_publish/manager/channel_config_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/net/honor_manager.dart';
import 'package:auto_channel_market_publish/net/huawei_manager.dart';
import 'package:auto_channel_market_publish/net/tencent_manager.dart';
import 'package:auto_channel_market_publish/net/xiaomi_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';

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
  UpdateConfig updateConfig = UpdateConfig();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("渠道配置:"),
              Container(
                height: 40,
                child: Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      var item = ChannelConfigManager().getChannelsState()[index];
                      return Container(
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: item.value ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(item.key.toString()),
                          ],
                        ),
                      );
                    },
                    itemCount: ChannelConfigManager().getChannelsState().length,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  //note 导入配置
                  Clipboard.getData(Clipboard.kTextPlain).then((value) {
                    try {
                      if (value != null) {
                        ChannelConfigManager().channelConfigs = ChannelConfigs.fromJson(
                          json.decode(value.text!),
                        );
                        ChannelConfigManager().saveLocalConfig();
                        SmartDialog.showToast("导入配置成功");
                        setState(() {});
                      }
                    } catch (e) {
                      print("剪贴板内容格式错误:${e.toString()}");
                      SmartDialog.showToast("剪贴板内容格式错误:${e.toString()}");
                    }
                  });
                },
                child: Text("从剪贴板导入配置"),
              ),
              SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  //note 导出配置 输出到剪贴板
                  Clipboard.setData(
                    ClipboardData(text: json.encode(ChannelConfigManager().channelConfigs.toJson())),
                  );
                },
                child: Text("复制配置到剪贴板"),
              ),
              SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  //note 编辑配置
                  GoRouter.of(context).push(ScreenConst.editChannelConfig);
                },
                child: Text("编辑配置"),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("appLogo:"),
              updateConfig.iconPath.isNotEmpty
                  ? Container(
                      width: 50,
                      height: 50,
                      child: Image.file(File(updateConfig.iconPath), width: 50, height: 50),
                    )
                  : Text("未选择"),
              ElevatedButton(
                onPressed: () {
                  //note
                  FilePicker.platform.pickFileAndDirectoryPaths(type: FileType.image).then((value) {
                    if (value != null) {
                      updateConfig.iconPath = value.first;
                      setState(() {});
                    }
                  });
                },
                child: Text("选择icon"),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("apk:"),
              Text(updateConfig.apkPath),
              ElevatedButton(
                onPressed: () {
                  //note
                  FilePicker.platform
                      .pickFileAndDirectoryPaths(type: FileType.custom, allowedExtensions: ['apk'])
                      .then((value) {
                        if (value != null) {
                          updateConfig.apkPath = value.first;
                          setState(() {});
                        }
                      });
                },
                child: Text("选择apk"),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("appName:"),
              Container(
                width: 200,
                child: TextField(
                  controller: TextEditingController(text: updateConfig.appName),
                  onChanged: (value) {
                    updateConfig.appName = value;
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("更新说明:"),
              Container(
                width: 200,
                child: TextField(
                  controller: TextEditingController(text: updateConfig.updateDesc),
                  onChanged: (value) {
                    updateConfig.updateDesc = value;
                  },
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              //note 更新
              // XiaomiManager().publish(
              //   synchroType: XiaomiSynchroType.apkUpdate,
              //   xiaomiConfig: ChannelConfigManager().channelConfigs.xiaomiConfig,
              //   appName: updateConfig.appName,
              //   apkPath: updateConfig.apkPath,
              //   iconPath: updateConfig.iconPath,
              //   updateDesc: updateConfig.updateDesc,
              // );
              
              //TencentManager().test();
            },
            child: Text("立即更新"),
          ),
        ],
      ),
    );
  }
}

class UpdateConfig {
  UpdateConfig({
    this.appName = "",
    this.iconPath = "",
    this.apkPath = "",
    this.desc = "",
    this.brief = "",
    this.updateDesc = "",
  });
  String appName;
  String iconPath;
  String apkPath;
  String desc;
  String brief;
  String updateDesc;
}
