import 'dart:convert';

import 'package:auto_channel_market_publish/manager/sp_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';

class ChannelConfigManager {
  factory ChannelConfigManager() => _instance;
  static final ChannelConfigManager _instance = ChannelConfigManager._internal();
  ChannelConfigManager._internal() {}

  List<ChannelConfig> channelConfigList = [];

  loadLocalConfig() async{
    var value = await SpManager.getStringList("channelConfigList");
    channelConfigList =value.map((e) => ChannelConfig.fromJson(json.decode(e))).toList();
  }

  saveLocalConfig() {
    SpManager.setStringList("channelConfigList", channelConfigList.map((e) => e.toJson().toString()).toList());
  }
}
