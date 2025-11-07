import 'package:auto_channel_market_publish/const/app_enums.dart';

///@Author jsji
///@Date 2025/10/11
///
///@Description 小米渠道所需配置

class XiaomiConfig {
  XiaomiConfig({
    this.packageName = "",
    this.userName = "",
    this.publicPem = "",
    this.privateKey = "",
    this.isSuccess = false,
  });

  String packageName;
  String userName;
  String publicPem;
  String privateKey;
  bool isSuccess;
  factory XiaomiConfig.fromJson(Map<String, dynamic> json) {
    return XiaomiConfig(
      packageName: json['packageName'],
      userName: json['userName'],
      publicPem: json['publicPem'],
      privateKey: json['privateKey'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'userName': userName,
      'publicPem': publicPem,
      'privateKey': privateKey,
    };
  }
}

class ChannelConfig {
  ChannelConfig({
    this.channelEnum = ChannelEnum.xiaomi,
    this.config = const {},
  });
  ChannelEnum channelEnum;
  Map<String, dynamic> config;
  factory ChannelConfig.fromJson(Map<String, dynamic> json) {
    return ChannelConfig(
      channelEnum: ChannelEnum.values.firstWhere((e) => e.name == json['channelEnum']),
      config: json['config'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'channelEnum': channelEnum.name,
      'config': config,
    };
  }
}
