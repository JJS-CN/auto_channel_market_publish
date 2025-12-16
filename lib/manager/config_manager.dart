import 'dart:async';
import 'dart:convert';

import 'package:auto_channel_market_publish/manager/sp_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';

class ConfigManager {
  factory ConfigManager() => _instance;
  static final ConfigManager _instance = ConfigManager._internal();
  ConfigManager._internal() {}

  StreamController<ProjectConfig> projectConfigStream = StreamController<ProjectConfig>.broadcast();

  List<ProjectConfig> projectConfigs = <ProjectConfig>[];
  ProjectConfig? _currentProjectConfig;

  set currentProjectConfig(ProjectConfig projectConfig) {
    _currentProjectConfig = projectConfig;
  }

  ProjectConfig get currentProjectConfig => _currentProjectConfig ?? ProjectConfig.defaultProjectConfig();

  loadLocalConfig() async {
    var value = SpManager.getStringList("projectConfigs");
    projectConfigs = value.map((e) => ProjectConfig.fromJson(json.decode(e))).toList();
    _resetCurrentProjectConfig();
  }

  loadDiskConfig(String value) async {
    var list = json.decode(value) as List<dynamic>;
    projectConfigs = list.map((e) => ProjectConfig.fromJson(e)).toList();
    _resetCurrentProjectConfig();
    SpManager.setStringList("projectConfigs", projectConfigs.map((e) => json.encode(e.toJson())).toList());
  }

  saveCurrentProject() {
    if (_currentProjectConfig == null) {
      return;
    }
    saveLocalConfig(_currentProjectConfig!);
  }

  saveLocalConfig(ProjectConfig projectConfig) {
    if (projectConfig.id <= 0) {
      //新增
      var maxId = projectConfigs.isEmpty
          ? 0
          : projectConfigs.map((e) => e.id).reduce((a, b) => a > b ? a : b);
      projectConfig.id = maxId + 1;
    } else {
      //更新
      projectConfigs.removeWhere((element) => element.id == projectConfig.id);
    }
    projectConfig.defaultPackageName();
    projectConfigs.add(projectConfig);
    projectConfigs.sort((a, b) => a.id.compareTo(b.id));
    SpManager.setStringList("projectConfigs", projectConfigs.map((e) => json.encode(e.toJson())).toList());
    _resetCurrentProjectConfig();
  }

  deleteLocalConfig(ProjectConfig projectConfig) {
    projectConfigs.removeWhere((element) => element.id == projectConfig.id);
    SpManager.setStringList("projectConfigs", projectConfigs.map((e) => json.encode(e.toJson())).toList());
    _resetCurrentProjectConfig();
  }

  clearAllLocalConfig() {
    projectConfigs.clear();
    SpManager.setStringList("projectConfigs", []);
    _currentProjectConfig = ProjectConfig.defaultProjectConfig();
  }

  _resetCurrentProjectConfig() {
    var data = projectConfigs.where((element) => element.id == _currentProjectConfig?.id).firstOrNull;
    if (data == null) {
      _currentProjectConfig = projectConfigs.firstOrNull ?? ProjectConfig.defaultProjectConfig();
    } else {
      _currentProjectConfig = data;
    }
    projectConfigStream.sink.add(_currentProjectConfig!);
  }

  checkChannelParamsSuccess() async {
    var channelConfigs = currentProjectConfig.allChannelConfigs();
    var isAllSuccess = true;
    for (var channelConfig in channelConfigs) {
      channelConfig.bindManager.init(channelConfig);
      var isSuccess = await channelConfig.bindManager.checkChannelSuccess();
      if (!isSuccess) {
        isAllSuccess = false;
      }
      saveCurrentProject();
    }
    return isAllSuccess;
  }
}
