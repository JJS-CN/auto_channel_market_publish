import 'dart:convert';

import 'package:auto_channel_market_publish/manager/sp_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/net/xiaomi_manager.dart';

class ChannelConfigManager {
  factory ChannelConfigManager() => _instance;
  static final ChannelConfigManager _instance = ChannelConfigManager._internal();
  ChannelConfigManager._internal() {}

  ChannelConfigs channelConfigs = ChannelConfigs(xiaomiConfig: XiaomiConfig());

  loadLocalConfig() async {
    var value = await SpManager.getString("channelConfigs");
    channelConfigs = ChannelConfigs.fromJson(json.decode(value));
  }

  saveLocalConfig() {
    SpManager.setString("channelConfigs", json.encode(channelConfigs.toJson()));
  }

  List<MapEntry<String, bool>> getChannelsState() {
    List<MapEntry<String, bool>> list = <MapEntry<String, bool>>[];
    list.add(MapEntry("xiaomi", channelConfigs.xiaomiConfig.queryApkResult?.updateVersion ?? false));
    return list;
  }

  checkChannelState() async {
    if (channelConfigs.xiaomiConfig.isComplete) {
      await XiaomiManager().queryApkConfig(xiaomiConfig: channelConfigs.xiaomiConfig).then((v) {
        //channelConfigs.xiaomiConfig.isSuccess = v.updateVersion;
      });
    }
  }
}
