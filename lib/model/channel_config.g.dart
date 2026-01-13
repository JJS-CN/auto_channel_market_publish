// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateConfig _$UpdateConfigFromJson(Map<String, dynamic> json) => UpdateConfig(
  versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
  updateDesc: json['updateDesc'] as String? ?? "",
);

Map<String, dynamic> _$UpdateConfigToJson(UpdateConfig instance) => <String, dynamic>{
  'versionCode': instance.versionCode,
  'updateDesc': instance.updateDesc,
};

ProjectConfig _$ProjectConfigFromJson(Map<String, dynamic> json) => ProjectConfig(
  id: (json['id'] as num?)?.toInt() ?? 0,
  appName: json['appName'] as String? ?? "",
  packageName: json['packageName'] as String? ?? "",
  apkDir: json['apkDir'] as String? ?? "",
  updateConfig: UpdateConfig.fromJson(json['updateConfig'] as Map<String, dynamic>),
  xiaomiConfig: XiaomiConfig.fromJson(json['xiaomiConfig'] as Map<String, dynamic>),
  huaweiConfig: HuaweiConfig.fromJson(json['huaweiConfig'] as Map<String, dynamic>),
  vivoConfig: VivoConfig.fromJson(json['vivoConfig'] as Map<String, dynamic>),
  oppoConfig: OppoConfig.fromJson(json['oppoConfig'] as Map<String, dynamic>),
  tencentConfig: TencentConfig.fromJson(json['tencentConfig'] as Map<String, dynamic>),
  honorConfig: HonorConfig.fromJson(json['honorConfig'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProjectConfigToJson(ProjectConfig instance) => <String, dynamic>{
  'id': instance.id,
  'appName': instance.appName,
  'packageName': instance.packageName,
  'apkDir': instance.apkDir,
  'updateConfig': instance.updateConfig,
  'xiaomiConfig': instance.xiaomiConfig,
  'huaweiConfig': instance.huaweiConfig,
  'honorConfig': instance.honorConfig,
  'vivoConfig': instance.vivoConfig,
  'oppoConfig': instance.oppoConfig,
  'tencentConfig': instance.tencentConfig,
};

XiaomiConfig _$XiaomiConfigFromJson(Map<String, dynamic> json) =>
    XiaomiConfig(
        userName: json['userName'] as String,
        publicPem: json['publicPem'] as String,
        privateKey: json['privateKey'] as String,
        packageName: json['packageName'] as String? ?? "",
        channel: $enumDecodeNullable(_$ChannelEnumEnumMap, json['channel']) ?? ChannelEnum.xiaomi,
        noteUrl:
            json['noteUrl'] as String? ?? "https://dev.mi.com/xiaomihyperos/documentation/detail?pId=1134",
      )
      ..isEnable = json['isEnable'] as bool
      ..isSuccess = json['isSuccess'] as bool?
      ..auditInfo = json['auditInfo'] == null
          ? null
          : AuditInfo.fromJson(json['auditInfo'] as Map<String, dynamic>);

Map<String, dynamic> _$XiaomiConfigToJson(XiaomiConfig instance) => <String, dynamic>{
  'channel': _$ChannelEnumEnumMap[instance.channel]!,
  'packageName': instance.packageName,
  'isEnable': instance.isEnable,
  'isSuccess': instance.isSuccess,
  'noteUrl': instance.noteUrl,
  'uploadApkInfo': instance.uploadApkInfo,
  'auditInfo': instance.auditInfo,
  'userName': instance.userName,
  'publicPem': instance.publicPem,
  'privateKey': instance.privateKey,
};

const _$ChannelEnumEnumMap = {
  ChannelEnum.xiaomi: 'xiaomi',
  ChannelEnum.tencent: 'tencent',
  ChannelEnum.huawei: 'huawei',
  ChannelEnum.honor: 'honor',
  ChannelEnum.oppo: 'oppo',
  ChannelEnum.vivo: 'vivo',
};

HonorConfig _$HonorConfigFromJson(Map<String, dynamic> json) =>
    HonorConfig(
        appId: json['appId'] as String,
        clientId: json['clientId'] as String,
        clientSecret: json['clientSecret'] as String,
        accessToken: json['accessToken'] as String? ?? "",
        expiresAt: (json['expiresAt'] as num?)?.toInt() ?? 0,
        packageName: json['packageName'] as String? ?? "",
        channel: $enumDecodeNullable(_$ChannelEnumEnumMap, json['channel']) ?? ChannelEnum.honor,
        noteUrl: json['noteUrl'] as String? ?? "https://developer.honor.com/cn/doc/guides/101359",
      )
      ..isEnable = json['isEnable'] as bool
      ..isSuccess = json['isSuccess'] as bool?
      ..auditInfo = json['auditInfo'] == null
          ? null
          : AuditInfo.fromJson(json['auditInfo'] as Map<String, dynamic>);

Map<String, dynamic> _$HonorConfigToJson(HonorConfig instance) => <String, dynamic>{
  'channel': _$ChannelEnumEnumMap[instance.channel]!,
  'packageName': instance.packageName,
  'isEnable': instance.isEnable,
  'isSuccess': instance.isSuccess,
  'noteUrl': instance.noteUrl,
  'uploadApkInfo': instance.uploadApkInfo,
  'auditInfo': instance.auditInfo,
  'clientId': instance.clientId,
  'clientSecret': instance.clientSecret,
  'appId': instance.appId,
  'accessToken': instance.accessToken,
  'expiresAt': instance.expiresAt,
};

HuaweiConfig _$HuaweiConfigFromJson(Map<String, dynamic> json) =>
    HuaweiConfig(
        appId: json['appId'] as String,
        clientId: json['clientId'] as String,
        clientSecret: json['clientSecret'] as String,
        accessToken: json['accessToken'] as String? ?? "",
        expiresAt: (json['expiresAt'] as num?)?.toInt() ?? 0,
        packageName: json['packageName'] as String? ?? "",
        channel: $enumDecodeNullable(_$ChannelEnumEnumMap, json['channel']) ?? ChannelEnum.huawei,
        noteUrl:
            json['noteUrl'] as String? ??
            "https://developer.huawei.com/consumer/cn/doc/app/agc-help-connect-api-obtain-server-auth-0000002271134661",
      )
      ..isEnable = json['isEnable'] as bool
      ..isSuccess = json['isSuccess'] as bool?
      ..auditInfo = json['auditInfo'] == null
          ? null
          : AuditInfo.fromJson(json['auditInfo'] as Map<String, dynamic>);

Map<String, dynamic> _$HuaweiConfigToJson(HuaweiConfig instance) => <String, dynamic>{
  'channel': _$ChannelEnumEnumMap[instance.channel]!,
  'packageName': instance.packageName,
  'isEnable': instance.isEnable,
  'isSuccess': instance.isSuccess,
  'noteUrl': instance.noteUrl,
  'uploadApkInfo': instance.uploadApkInfo,
  'auditInfo': instance.auditInfo,
  'clientId': instance.clientId,
  'clientSecret': instance.clientSecret,
  'appId': instance.appId,
  'accessToken': instance.accessToken,
  'expiresAt': instance.expiresAt,
};

VivoConfig _$VivoConfigFromJson(Map<String, dynamic> json) =>
    VivoConfig(
        access_key: json['access_key'] as String,
        accessSecret: json['accessSecret'] as String,
        appId: json['appId'] as String? ?? "",
        packageName: json['packageName'] as String? ?? "",
        channel: $enumDecodeNullable(_$ChannelEnumEnumMap, json['channel']) ?? ChannelEnum.vivo,
        noteUrl: json['noteUrl'] as String? ?? "https://dev.vivo.com.cn/documentCenter/doc/326",
      )
      ..isEnable = json['isEnable'] as bool
      ..isSuccess = json['isSuccess'] as bool?
      ..auditInfo = json['auditInfo'] == null
          ? null
          : AuditInfo.fromJson(json['auditInfo'] as Map<String, dynamic>);

Map<String, dynamic> _$VivoConfigToJson(VivoConfig instance) => <String, dynamic>{
  'channel': _$ChannelEnumEnumMap[instance.channel]!,
  'packageName': instance.packageName,
  'isEnable': instance.isEnable,
  'isSuccess': instance.isSuccess,
  'noteUrl': instance.noteUrl,
  'uploadApkInfo': instance.uploadApkInfo,
  'auditInfo': instance.auditInfo,
  'access_key': instance.access_key,
  'accessSecret': instance.accessSecret,
  'appId': instance.appId,
};

OppoConfig _$OppoConfigFromJson(Map<String, dynamic> json) =>
    OppoConfig(
        access_token: json['access_token'] as String? ?? "",
        expires_at: (json['expires_at'] as num?)?.toInt() ?? 0,
        client_id: json['client_id'] as String,
        client_secret: json['client_secret'] as String,
        packageName: json['packageName'] as String? ?? "",
        channel: $enumDecodeNullable(_$ChannelEnumEnumMap, json['channel']) ?? ChannelEnum.oppo,
        noteUrl: json['noteUrl'] as String? ?? "https://open.oppomobile.com/documentation/page/info?id=10998",
      )
      ..isEnable = json['isEnable'] as bool
      ..isSuccess = json['isSuccess'] as bool?
      ..auditInfo = json['auditInfo'] == null
          ? null
          : AuditInfo.fromJson(json['auditInfo'] as Map<String, dynamic>);

Map<String, dynamic> _$OppoConfigToJson(OppoConfig instance) => <String, dynamic>{
  'channel': _$ChannelEnumEnumMap[instance.channel]!,
  'packageName': instance.packageName,
  'isEnable': instance.isEnable,
  'isSuccess': instance.isSuccess,
  'noteUrl': instance.noteUrl,
  'uploadApkInfo': instance.uploadApkInfo,
  'auditInfo': instance.auditInfo,
  'access_token': instance.access_token,
  'expires_at': instance.expires_at,
  'client_id': instance.client_id,
  'client_secret': instance.client_secret,
};

TencentConfig _$TencentConfigFromJson(Map<String, dynamic> json) =>
    TencentConfig(
        appId: json['appId'] as String,
        userId: json['userId'] as String,
        secretKey: json['secretKey'] as String,
        packageName: json['packageName'] as String? ?? "",
        channel: $enumDecodeNullable(_$ChannelEnumEnumMap, json['channel']) ?? ChannelEnum.tencent,
        noteUrl: json['noteUrl'] as String? ?? "https://wikinew.open.qq.com/index.html#/iwiki/4015262492",
      )
      ..isEnable = json['isEnable'] as bool
      ..isSuccess = json['isSuccess'] as bool?
      ..auditInfo = json['auditInfo'] == null
          ? null
          : AuditInfo.fromJson(json['auditInfo'] as Map<String, dynamic>);

Map<String, dynamic> _$TencentConfigToJson(TencentConfig instance) => <String, dynamic>{
  'channel': _$ChannelEnumEnumMap[instance.channel]!,
  'packageName': instance.packageName,
  'isEnable': instance.isEnable,
  'isSuccess': instance.isSuccess,
  'noteUrl': instance.noteUrl,
  'uploadApkInfo': instance.uploadApkInfo,
  'auditInfo': instance.auditInfo,
  'appId': instance.appId,
  'userId': instance.userId,
  'secretKey': instance.secretKey,
};

UploadApkInfo _$UploadApkInfoFromJson(Map<String, dynamic> json) => UploadApkInfo(
  apkPath: json['apkPath'] as String? ?? "",
  apkPath32: json['apkPath32'] as String? ?? "",
  apkPath64: json['apkPath64'] as String? ?? "",
);

Map<String, dynamic> _$UploadApkInfoToJson(UploadApkInfo instance) => <String, dynamic>{
  'apkPath': instance.apkPath,
  'apkPath32': instance.apkPath32,
  'apkPath64': instance.apkPath64,
};

AuditInfo _$AuditInfoFromJson(Map<String, dynamic> json) => AuditInfo(
  releaseVersionCode: (json['releaseVersionCode'] as num?)?.toInt() ?? 0,
  versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
  auditStatus: $enumDecodeNullable(_$AuditStatusEnumMap, json['auditStatus']) ?? AuditStatus.known,
  auditReason: json['auditReason'] as String? ?? "",
);

Map<String, dynamic> _$AuditInfoToJson(AuditInfo instance) => <String, dynamic>{
  'releaseVersionCode': instance.releaseVersionCode,
  'versionCode': instance.versionCode,
  'auditStatus': _$AuditStatusEnumMap[instance.auditStatus]!,
  'auditReason': instance.auditReason,
};

const _$AuditStatusEnumMap = {
  AuditStatus.known: 'known',
  AuditStatus.auditing: 'auditing',
  AuditStatus.auditFailed: 'auditFailed',
  AuditStatus.auditSuccess: 'auditSuccess',
};
