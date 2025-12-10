import 'package:auto_channel_market_publish/model/query_apk_result.dart';
import 'package:json_annotation/json_annotation.dart';

part 'channel_config.g.dart';

///@Author jsji
///@Date 2025/10/11
///
///@Description 所有渠道所需配置

@JsonSerializable()
class ChannelConfigs {
  ChannelConfigs({required this.xiaomiConfig});
  XiaomiConfig xiaomiConfig;

  factory ChannelConfigs.fromJson(Map<String, dynamic> json) => _$ChannelConfigsFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelConfigsToJson(this);
}

@JsonSerializable()
class XiaomiConfig extends BaseChannelConfig {
  XiaomiConfig({
    this.packageName = "",
    this.userName = "",
    this.publicPem = "",
    this.privateKey = "",
    super.channelName = "小米",
    super.channelEnum = ChannelEnum.xiaomi,
    super.isEnable = false,
    super.lastCheckSuccessTime = 0,
    super.errorMessage = "",
    super.queryApkResult,
  });

  String packageName;
  String userName;
  String publicPem;
  String privateKey;

  @override
  bool get isComplete =>
      packageName.isNotEmpty && userName.isNotEmpty && publicPem.isNotEmpty && privateKey.isNotEmpty;

  factory XiaomiConfig.fromJson(Map<String, dynamic> json) => _$XiaomiConfigFromJson(json);
  Map<String, dynamic> toJson() => _$XiaomiConfigToJson(this);

  @override
  String toString() {
    return 'XiaomiConfig(packageName: $packageName, userName: $userName, publicPem: $publicPem, privateKey: $privateKey)';
  }
}

class HuaweiConfig extends BaseChannelConfig {
  HuaweiConfig({
    this.appId = "",
    this.clientId = "",
    this.clientSecret = "",
    super.channelName = "华为",
    super.channelEnum = ChannelEnum.huawei,
    super.isEnable = false,
    super.lastCheckSuccessTime = 0,
    super.errorMessage = "",
    super.queryApkResult,
  });
  String clientId;
  String clientSecret;
  String appId;

  @override
  bool get isComplete => clientId.isNotEmpty && clientSecret.isNotEmpty && appId.isNotEmpty;
}

abstract class BaseChannelConfig {
  BaseChannelConfig({
    required this.channelName,
    required this.channelEnum,
    this.isEnable = false,
    this.lastCheckSuccessTime = 0,
    this.errorMessage = "",
    this.queryApkResult,
  });
  //渠道名称
  String channelName;
  ChannelEnum channelEnum;
  //是否启用
  bool isEnable;
  //是否成功
  QueryApkResult? queryApkResult;
  //上次检查状态时间点
  int lastCheckSuccessTime;
  String errorMessage;

  //是否填写完整
  bool get isComplete;
}

enum ChannelEnum { xiaomi, huawei, honor }
