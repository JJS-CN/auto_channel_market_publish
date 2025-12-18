import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_channel_market_publish/const/screen_const.dart';
import 'package:auto_channel_market_publish/manager/config_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/widget/channel_input_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  final List<StreamSubscription> _subscriptions = [];
  @override
  void initState() {
    super.initState();
    var subscription = ConfigManager().projectConfigStream.stream.listen((event) {
      setState(() {});
    });
    _subscriptions.add(subscription);
    ConfigManager().loadLocalConfig().then((value) {
      setState(() {});
    });

    if (ConfigManager().currentProjectConfig
        .allChannelConfigs()
        .where((element) => element.isSuccess == null)
        .isNotEmpty) {
      ConfigManager().checkChannelParamsSuccess();
    }
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildTitleRow(),
          _buildProjectRow(),
          _buildChannelRow(),
          _buildChannelApkInfo(),
          _buildUpgradeInfo(),
          SizedBox(height: 20),
          _buildFilterActionInfo(),
          SizedBox(height: 10),
          _buildPublishButton(),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Container(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("安卓自动传包工具 v1.0.0", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              //note 跳转
              SmartDialog.show(
                builder: (context) {
                  return Container(
                    constraints: BoxConstraints(maxWidth: 600, minWidth: 200),
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("- 先新建项目,填写通用配置"),
                            Text("- 然后编辑渠道配置,填写渠道配置,首页按钮可点击立即检查渠道配置是否正确"),
                            Text("- 确认渠道包已经存放在指定目录下,将会按以下规则匹配文件名以查找渠道包:"),
                            Text(
                              "contains(包名)&&contains(渠道号)&&contains(versionCode)&&endsWith(.apk)",
                              style: TextStyle(fontSize: 13, color: Colors.blue),
                            ),
                            Text(
                              "- 32位和64位需要分包时,请在结尾添加-32.apk或-64.apk",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              "- 示例:fungo-oppo-204000-32.apk,fungo-oppo-204000-64.apk",
                              style: TextStyle(fontSize: 13, color: Colors.blue.shade200),
                            ),
                            Text("- 最后点击立即更新,工具会先检查各渠道状态,同步审核状态"),
                            Text("- 各审核状态无问题时,将执行上传渠道包到对应渠道"),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: Icon(Icons.info, size: 15, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  ///项目配置组件,下拉选择项目
  Widget _buildProjectRow() {
    return Container(
      height: 40,
      constraints: BoxConstraints(minWidth: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text("项目配置:", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1)),
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      //note 导入项目
                      SmartDialog.showToast("导入将会覆盖当前配置,请谨慎操作");
                      String? initialDirectory;
                      if (ConfigManager().currentProjectConfig.apkDir.isNotEmpty) {
                        initialDirectory = ConfigManager().currentProjectConfig.apkDir;
                      }
                      FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['config'],
                            initialDirectory: initialDirectory,
                          )
                          .then((value) {
                            if (value != null) {
                              File(value.files.first.path!).readAsString().then((value) {
                                ConfigManager().loadDiskConfig(value).then((value) {
                                  SmartDialog.showToast("导入成功");
                                });
                              });
                            }
                          });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      child: Icon(Icons.call_received, size: 15, color: Colors.black),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      //note 导出项目
                      FilePicker.platform
                          .saveFile(
                            initialDirectory: ConfigManager().currentProjectConfig.apkDir,
                            fileName: "auto_channel_market_publish_project.config",
                            allowedExtensions: ['config'],
                            type: FileType.custom,
                          )
                          .then((v) {
                            if (v != null) {
                              File(v).writeAsString(json.encode(ConfigManager().projectConfigs)).then((
                                value,
                              ) {
                                SmartDialog.showToast("导出成功");
                              });
                            }
                          });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      child: Icon(Icons.call_made, size: 15, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                var projectConfig = ConfigManager().projectConfigs[index];
                return GestureDetector(
                  onTap: () {
                    ConfigManager().currentProjectConfig = projectConfig;
                    setState(() {});
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Text(projectConfig.appName),
                    decoration: BoxDecoration(
                      color: projectConfig.id == ConfigManager().currentProjectConfig.id
                          ? Colors.blue.shade200
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                );
              },
              itemCount: ConfigManager().projectConfigs.length,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              //note 跳转编辑项目配置
              GoRouter.of(context)
                  .push(ScreenConst.editProjectConfig, extra: ConfigManager().currentProjectConfig)
                  .then((value) {
                    if (value != null) {
                      setState(() {});
                    }
                  });
            },
            child: Container(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.edit, size: 15, color: Colors.grey),
            ),
          ),
          //新增
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              //note 新增项目
              GoRouter.of(context).push(ScreenConst.editProjectConfig);
            },
            child: Container(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.add_box, size: 15, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  ///渠道配置组件
  Widget _buildChannelRow() {
    var channelConfigs = ConfigManager().currentProjectConfig.allChannelConfigs();
    return Container(
      height: 52,
      constraints: BoxConstraints(minWidth: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("渠道配置:", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1)),
          ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              var channel = channelConfigs[index];
              //根据状态 未配置,未启用,未验证,验证失败,验证成功,验证中 设置颜色
              var statusColor = Colors.grey;
              if (channel.isSuccess == null) {
                statusColor = Colors.grey;
              } else if (channel.isSuccess == true) {
                statusColor = Colors.green;
              } else if (channel.isSuccess == false) {
                statusColor = Colors.red;
              }

              var releaseVersionCode = channel.auditInfo?.releaseVersionCode ?? 0;
              var auditStatus = channel.auditInfo?.auditStatus ?? AuditStatus.known;

              var onlineColor = Colors.grey;
              if (releaseVersionCode < ConfigManager().currentProjectConfig.updateConfig.versionCode ||
                  releaseVersionCode <= 0) {
                onlineColor = Colors.orange;
              } else {
                onlineColor = Colors.green;
              }
              var auditStatusColor = auditStatus == AuditStatus.auditSuccess
                  ? Colors.grey
                  : auditStatus == AuditStatus.auditFailed
                  ? Colors.red
                  : auditStatus == AuditStatus.auditing
                  ? Colors.orange
                  : Colors.grey;
              return GestureDetector(
                onTap: () {
                  //审核情况
                  if (channel.auditInfo != null) {
                    SmartDialog.show(
                      builder: (context) {
                        return Container(
                          constraints: BoxConstraints(
                            maxWidth: 500,
                            minWidth: 200,
                            maxHeight: 500,
                            minHeight: 120,
                          ),
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              padding: EdgeInsets.all(10),
                              child: SelectableText(json.encode(channel.auditInfo!.toJson())),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Text(channel.channel.name),
                          SizedBox(width: 2),
                        ],
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: onlineColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Text(
                                " P:${releaseVersionCode}",
                                style: TextStyle(fontSize: 9, color: Colors.grey.shade600, height: 1),
                              ),
                            ],
                          ),
                          Text(
                            "${auditStatus.name}",
                            style: TextStyle(fontSize: 9, color: auditStatusColor, height: 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: channelConfigs.length,
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              //跳转编辑渠道配置
              GoRouter.of(context).push(ScreenConst.editChannelConfig).then((value) {
                setState(() {});
              });
            },
            child: Container(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.edit, size: 15, color: Colors.grey),
            ),
          ),
          //更新
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              //note 更新渠道配置
              ConfigManager().checkChannelParamsSuccess().then((value) {
                setState(() {});
              });
            },
            child: Container(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.refresh, size: 15, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelApkInfo() {
    var channelConfigs = ConfigManager().currentProjectConfig.allChannelConfigs();
    return Container(
      height: 52,
      constraints: BoxConstraints(minWidth: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("包体信息:", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1)),
          ListView.builder(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              var channel = channelConfigs[index];
              //根据状态 未配置,未启用,未验证,验证失败,验证成功,验证中 设置颜色
              var statusColor = Colors.transparent;
              if (channel.uploadApkInfo == null ||
                  channel.uploadApkInfo!.apkPath.isEmpty &&
                      channel.uploadApkInfo!.apkPath32.isEmpty &&
                      channel.uploadApkInfo!.apkPath64.isEmpty) {
                statusColor = Colors.red;
              } else if (channel.uploadApkInfo!.apkPath32.isNotEmpty &&
                  channel.uploadApkInfo!.apkPath64.isNotEmpty &&
                  channel.uploadApkInfo!.apkPath.isNotEmpty) {
                statusColor = Colors.green;
              } else if (channel.uploadApkInfo!.apkPath32.isNotEmpty &&
                      channel.uploadApkInfo!.apkPath64.isNotEmpty ||
                  channel.uploadApkInfo!.apkPath.isNotEmpty) {
                statusColor = Colors.orange;
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Text(channel.channel.name),
                        SizedBox(width: 2),
                      ],
                    ),
                    if (channel.uploadApkInfo != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (channel.uploadApkInfo!.apkPath.isNotEmpty)
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: EdgeInsets.symmetric(vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Text(
                                  "ALL ",
                                  style: TextStyle(fontSize: 8, color: Colors.grey.shade600, height: 1),
                                ),
                              ],
                            ),
                          if (channel.uploadApkInfo!.apkPath32.isNotEmpty)
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: EdgeInsets.symmetric(vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Text(
                                  "32 ",
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600, height: 1),
                                ),
                              ],
                            ),
                          if (channel.uploadApkInfo!.apkPath64.isNotEmpty)
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: EdgeInsets.symmetric(vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Text(
                                  "64",
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600, height: 1),
                                ),
                              ],
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
            itemCount: channelConfigs.length,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeInfo() {
    return Container(
      child: Column(
        children: [
          ChannelInputWidget(
            label: "版本号",
            hintText: "请输入版本号(VersionCode)",
            keyboardType: TextInputType.number,
            initialValue: ConfigManager().currentProjectConfig.updateConfig.versionCode.toString(),
            onChanged: (value) {
              if (value.isNotEmpty) {
                ConfigManager().currentProjectConfig.updateConfig.versionCode = int.parse(value);
              }
            },
          ),
          ChannelInputWidget(
            label: "更新说明",
            hintText: "请输入更新说明",
            initialValue: ConfigManager().currentProjectConfig.updateConfig.updateDesc,
            onChanged: (value) {
              if (value.isNotEmpty) {
                ConfigManager().currentProjectConfig.updateConfig.updateDesc = value;
              }
            },
          ),
        ],
      ),
    );
  }

  _buildFilterActionInfo() {
    return Container(
      child: Row(
        children: [Text("过滤操作:", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1))],
      ),
    );
  }

  _buildPublishButton() {
    return GestureDetector(
      onTap: () async {
        var projectConfig = ConfigManager().currentProjectConfig;
        if (!projectConfig.updateConfig.isComplete()) {
          SmartDialog.showToast("更新信息不完整,请检查");
          return;
        }
        var allChannelConfigs = projectConfig.allChannelConfigs();

        ///渠道包是否更新
        var isApkUpdate = false;
        //是否有渠道包
        var isChannelNoApk = false;
        for (var channelConfig in allChannelConfigs) {
          var originUploadApkInfoStr = channelConfig.uploadApkInfo?.toJson().toString();
          channelConfig.uploadApkInfo = UploadApkInfo();
          var dir = projectConfig.apkDir;
          var files = Directory(dir).listSync(recursive: true);
          for (var file in files) {
            if (file.path.contains(projectConfig.packageName) &&
                file.path.contains(projectConfig.updateConfig.versionCode.toString()) &&
                file.path.contains(channelConfig.channel.name) &&
                file.path.endsWith(".apk")) {
              if (file.path.endsWith("-32.apk")) {
                channelConfig.uploadApkInfo?.apkPath32 = file.path;
              } else if (file.path.endsWith("-64.apk")) {
                channelConfig.uploadApkInfo?.apkPath64 = file.path;
              } else {
                channelConfig.uploadApkInfo?.apkPath = file.path;
              }
            }
          }
          var newUploadApkInfoStr = channelConfig.uploadApkInfo?.toJson().toString();
          if (originUploadApkInfoStr != newUploadApkInfoStr) {
            isApkUpdate = true;
          }
          if (channelConfig.uploadApkInfo!.apkPath.isEmpty &&
              channelConfig.uploadApkInfo!.apkPath32.isEmpty &&
              channelConfig.uploadApkInfo!.apkPath64.isEmpty) {
            isChannelNoApk = true;
          }
        }
        if (isChannelNoApk) {
          SmartDialog.showToast("部分渠道包不存在,请确认");
          setState(() {});
          return;
        }
        if (isApkUpdate) {
          SmartDialog.showToast("渠道包有更新,请确认");
          setState(() {});
          return;
        }
        //更新渠道审核状态
        await ConfigManager().checkChannelParamsSuccess();
        //筛选需要执行更新的渠道:不在审核中,且线上版本号小于当前版本号
        var needUpdateChannels = allChannelConfigs
            .where(
              (element) =>
                  element.auditInfo?.auditStatus != AuditStatus.auditing &&
                  (element.auditInfo?.releaseVersionCode ?? 0) < projectConfig.updateConfig.versionCode,
            )
            .toList();
        //临时剔除tencent
        needUpdateChannels.removeWhere((element) => element.channel == ChannelEnum.tencent);
        print("needUpdateChannels: ${needUpdateChannels.map((e) => e.channel.name).join(",")}");
        for (var channelConfig in needUpdateChannels) {
          await channelConfig.bindManager.startPublish(projectConfig.updateConfig);
        }
        if (needUpdateChannels.isEmpty) {
          SmartDialog.showToast("没有需要更新的渠道");
          setState(() {});
          return;
        }
        SmartDialog.showToast("更新完成,请等待审核结果");
        setState(() {});
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(5)),
        child: Text("立即更新", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
