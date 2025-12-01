// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChannelConfigs _$ChannelConfigsFromJson(Map<String, dynamic> json) =>
    ChannelConfigs(
      xiaomiConfig: XiaomiConfig.fromJson(
        json['xiaomiConfig'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ChannelConfigsToJson(ChannelConfigs instance) =>
    <String, dynamic>{'xiaomiConfig': instance.xiaomiConfig.toJson()};

XiaomiConfig _$XiaomiConfigFromJson(Map<String, dynamic> json) => XiaomiConfig(
  packageName: json['packageName'] as String? ?? "",
  userName: json['userName'] as String? ?? "",
  publicPem: json['publicPem'] as String? ?? "",
  privateKey: json['privateKey'] as String? ?? "",
  channelName: json['channelName'] as String? ?? "小米",
  channelEnum:
      $enumDecodeNullable(_$ChannelEnumEnumMap, json['channelEnum']) ??
      ChannelEnum.xiaomi,
  isEnable: json['isEnable'] as bool? ?? false,
  lastCheckSuccessTime: (json['lastCheckSuccessTime'] as num?)?.toInt() ?? 0,
  errorMessage: json['errorMessage'] as String? ?? "",
  queryApkResult: json['queryApkResult'] == null
      ? null
      : QueryApkResult.fromJson(json['queryApkResult'] as Map<String, dynamic>),
);

Map<String, dynamic> _$XiaomiConfigToJson(XiaomiConfig instance) =>
    <String, dynamic>{
      'channelName': instance.channelName,
      'channelEnum': _$ChannelEnumEnumMap[instance.channelEnum]!,
      'isEnable': instance.isEnable,
      'queryApkResult': instance.queryApkResult?.toJson(),
      'lastCheckSuccessTime': instance.lastCheckSuccessTime,
      'errorMessage': instance.errorMessage,
      'packageName': instance.packageName,
      'userName': instance.userName,
      'publicPem': instance.publicPem,
      'privateKey': instance.privateKey,
    };

const _$ChannelEnumEnumMap = {ChannelEnum.xiaomi: 'xiaomi'};
