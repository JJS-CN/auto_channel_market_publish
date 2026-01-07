import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:auto_channel_market_publish/manager/sp_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/net/huawei_manager.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class ConfigManager {
  factory ConfigManager() => _instance;
  static final ConfigManager _instance = ConfigManager._internal();
  ConfigManager._internal() {}

  StreamController<List<ProjectConfig>> projectConfigStream =
      StreamController<List<ProjectConfig>>.broadcast();

  StreamController<bool> isPublishReadyStream = StreamController<bool>.broadcast();

  List<ProjectConfig> projectConfigs = <ProjectConfig>[];

  ProjectConfig _curProject = ProjectConfig.defaultProjectConfig();

  ///加载本地所有配置
  loadLocalConfig() async {
    var value = SpManager.getStringList("projectConfigs");
    projectConfigs = value.map((e) => ProjectConfig.fromJson(json.decode(e))).toList();
    _curProject = projectConfigs.firstOrNull ?? ProjectConfig.defaultProjectConfig();
    checkAllAuditStatus();
  }

  ///从外部导入文件:并保存到本地
  saveLocalConfigForDisk(String value) {
    var list = json.decode(value) as List<dynamic>;
    projectConfigs = list.map((e) => ProjectConfig.fromJson(e)).toList();
    _curProject = projectConfigs.firstOrNull ?? ProjectConfig.defaultProjectConfig();
    saveToDisk();
    checkAllAuditStatus();
  }

  ///保存当前项目到磁盘
  saveToDisk() {
    var list = projectConfigs.map((e) => e.toJson()).toList();
    SpManager.setStringList("projectConfigs", list.map((e) => json.encode(e)).toList());
    //通知所有监听者
    projectConfigStream.sink.add(projectConfigs);
  }

  ///新增项目
  addProject(ProjectConfig projectConfig) {
    var maxId = projectConfigs.isEmpty ? 0 : projectConfigs.map((e) => e.id).reduce((a, b) => a > b ? a : b);
    projectConfig.id = maxId + 1;
    projectConfigs.add(projectConfig);
    saveToDisk();
  }

  ///删除项目
  deleteProject(ProjectConfig projectConfig) {
    projectConfigs.removeWhere((element) => element.id == projectConfig.id);
    _curProject = projectConfigs.firstOrNull ?? ProjectConfig.defaultProjectConfig();
    saveToDisk();
  }

  ///更新项目
  updateProject(ProjectConfig projectConfig) {
    var index = projectConfigs.indexWhere((element) => element.id == projectConfig.id);
    if (index == -1) {
      return;
    }
    projectConfigs[index] = projectConfig;
    saveToDisk();
  }

  ///保存当前项目
  autoSaveProject(ProjectConfig projectConfig) {
    if (projectConfig.id <= 0) {
      //新增
      addProject(projectConfig);
    } else {
      //更新
      updateProject(projectConfig);
    }
  }

  ProjectConfig getCurrentProject() {
    return _curProject;
  }

  setCurrentProjectForClick(ProjectConfig projectConfig) {
    _curProject = projectConfig;
  }

  ///所有渠道网络是否通畅
  bool allChannelNetworkSuccess() {
    var isAllSuccess = true;
    var channelConfigs = _curProject.allChannelConfigs();
    for (var channelConfig in channelConfigs) {
      channelConfig.bindManager.init(channelConfig);
      var isSuccess = channelConfig.isSuccess;
      if (isSuccess != true) {
        isAllSuccess = false;
      }
    }
    return isAllSuccess;
  }

  ///检查单个渠道
  Future<bool> checkAuditStatus(BaseChannelConfig channelConfig) async {
    channelConfig.bindManager.init(channelConfig);
    projectConfigStream.sink.add(projectConfigs);
    await channelConfig.bindManager.checkAuditStats();
    projectConfigStream.sink.add(projectConfigs);
    return true;
  }

  ///检查所有渠道审核状态
  Future<bool> checkAllAuditStatus() async {
    var channelConfigs = _curProject.allChannelConfigs();
    _resetInitConfigs(configs: channelConfigs);

    for (var channelConfig in channelConfigs) {
      channelConfig.isSuccess = null;
      projectConfigStream.sink.add(projectConfigs);
      await channelConfig.bindManager.checkAuditStats();
      projectConfigStream.sink.add(projectConfigs);
    }
    saveToDisk();
    return true;
  }

  ///执行apk更新发布
  Future<bool> startApkPublish(Function(BaseChannelConfig channelConfig) onPublishNotify) async {
    var allChannelConfigs = _curProject.allChannelConfigs();
    //剔除线上>=本次版本号渠道
    allChannelConfigs.removeWhere(
      (channelConfig) =>
          (channelConfig.auditInfo?.releaseVersionCode ?? 0) >= _curProject.updateConfig.versionCode,
    );
    //剔除正在审核中的渠道
    allChannelConfigs.removeWhere(
      (channelConfig) => channelConfig.auditInfo?.auditStatus == AuditStatus.auditing,
    );
    print("allChannelConfigs: ${allChannelConfigs.length}");
    print("allChannelConfigs: ${allChannelConfigs.map((e) => e.channel.name).join(",")}");

    await Future.wait(
      allChannelConfigs.map((channelConfig) async {
        await channelConfig.bindManager.startPublish(_curProject.updateConfig);
        onPublishNotify.call(channelConfig);
        return Future.value(true);
      }),
    );
    return true;
  }

  ///检查是否可以执行
  Future<bool> checkStartReady() async {
    //检查更新信息是否完整
    if (_curProject.updateConfig.isComplete() != true) {
      SmartDialog.showToast("更新信息不完整,请检查");
      return false;
    }
    //检查渠道网络状态
    var allNetworkSuccess = allChannelNetworkSuccess();
    if (allNetworkSuccess != true) {
      SmartDialog.showToast("渠道网络不通畅,请检查配置或网络");
      return false;
    }
    //检查更新版本号是否与线上版本号相同
    var allChannelConfigs = _curProject.allChannelConfigs();
    //剔除线上>=本次版本号渠道
    allChannelConfigs.removeWhere(
      (channelConfig) =>
          (channelConfig.auditInfo?.releaseVersionCode ?? 0) >= _curProject.updateConfig.versionCode,
    );
    //剔除正在审核中的渠道
    allChannelConfigs.removeWhere(
      (channelConfig) => channelConfig.auditInfo?.auditStatus == AuditStatus.auditing,
    );
    //检查剩余渠道数量
    if (allChannelConfigs.isEmpty) {
      SmartDialog.showToast("没有需要更新的渠道");
      return false;
    }
    //查询更新所需的apk包
    allChannelConfigs.forEach((channelConfig) {
      channelConfig.uploadApkInfo = UploadApkInfo();
    });

    Directory apkDir = Directory(_curProject.apkDir);
    apkDir.listSync().forEach((element) {
      allChannelConfigs.forEach((channelConfig) {
        if (element.path.contains(channelConfig.channel.name) &&
            element.path.contains(channelConfig.packageName) &&
            element.path.contains(_curProject.updateConfig.versionCode.toString())) {
          //渠道号匹配上,说明是这个渠道包的
          if (element.path.endsWith(".apk")) {
            if (element.path.contains("armeabi_v7a|arm64_v8a")) {
              channelConfig.uploadApkInfo?.apkPath = element.path;
            } else if (element.path.contains("armeabi_v7a")) {
              channelConfig.uploadApkInfo?.apkPath32 = element.path;
            } else if (element.path.contains("arm64_v8a")) {
              channelConfig.uploadApkInfo?.apkPath64 = element.path;
            } else {
              channelConfig.uploadApkInfo?.apkPath = element.path;
            }
          } else if (element.path.endsWith(".aab")) {
            //google市场
          } else if (element.path.endsWith(".hap")) {
            //华为市场
          }
        }
      });
    });
    // 方案A: 从目录筛选渠道包
    var hasApkAllEmpty =
        allChannelConfigs
            .where((channelConfig) => channelConfig.uploadApkInfo?.isAllEmpty == true)
            .toList()
            .length >
        0;
    if (hasApkAllEmpty) {
      return false;
    }
    //检查线上
    return true;
  }

  ///重置渠道管理器初始化配置(项目切换,项目删除,项目新增,渠道修改后需要重置)
  ///因为太多位置,所以在使用接口相关功能时调用一次比较好
  _resetInitConfigs({List<BaseChannelConfig>? configs}) {
    List<BaseChannelConfig> channelConfigs = configs ?? _curProject.allChannelConfigs();
    for (var channelConfig in channelConfigs) {
      channelConfig.bindManager.init(channelConfig);
    }
  }
}
