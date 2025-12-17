import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:auto_channel_market_publish/net/honor_manager.dart';
import 'package:auto_channel_market_publish/net/huawei_manager.dart';
import 'package:auto_channel_market_publish/net/oppo_manager.dart';
import 'package:auto_channel_market_publish/net/tencent_manager.dart';
import 'package:auto_channel_market_publish/net/vivo_manager.dart';
import 'package:auto_channel_market_publish/net/xiaomi_manager.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:auto_channel_market_publish/model/enums.dart';

part 'channel_config.g.dart';

///@Author jsji
///@Date 2025/10/11
///
///@Description 所有渠道所需配置

@JsonSerializable()
class UpdateConfig {
  UpdateConfig({this.versionCode = 0, this.updateDesc = ""});
  int versionCode;
  // String desc;
  // String brief;
  String updateDesc;

  bool isComplete() {
    if (versionCode == 0) {
      SmartDialog.showToast("versionCode不能为0");
      return false;
    }

    return true;
  }

  factory UpdateConfig.fromJson(Map<String, dynamic> json) => _$UpdateConfigFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateConfigToJson(this);
}

@JsonSerializable()
class ProjectConfig {
  ProjectConfig({
    this.id = 0,
    this.appName = "",
    this.packageName = "",
    this.apkDir = "",
    required this.updateConfig,
    required this.xiaomiConfig,
    required this.huaweiConfig,
    required this.vivoConfig,
    required this.oppoConfig,
    required this.tencentConfig,
    required this.honorConfig,
  });

  static ProjectConfig defaultProjectConfig() {
    return ProjectConfig(
      updateConfig: UpdateConfig(),
      xiaomiConfig: XiaomiConfig(packageName: "", userName: "", publicPem: "", privateKey: ""),
      huaweiConfig: HuaweiConfig(packageName: "", appId: "", clientId: "", clientSecret: ""),
      honorConfig: HonorConfig(packageName: "", appId: "", clientId: "", clientSecret: ""),
      vivoConfig: VivoConfig(packageName: "", access_key: "", accessSecret: ""),
      oppoConfig: OppoConfig(packageName: "", client_id: "", client_secret: ""),
      tencentConfig: TencentConfig(packageName: "", appId: "", userId: "", secretKey: ""),
    );
  }

  void defaultPackageName() {
    if (xiaomiConfig.packageName.isEmpty) {
      xiaomiConfig.packageName = packageName;
    }
    if (huaweiConfig.packageName.isEmpty) {
      huaweiConfig.packageName = packageName;
    }
    if (honorConfig.packageName.isEmpty) {
      honorConfig.packageName = packageName;
    }
    if (vivoConfig.packageName.isEmpty) {
      vivoConfig.packageName = packageName;
    }
    if (oppoConfig.packageName.isEmpty) {
      oppoConfig.packageName = packageName;
    }
    if (tencentConfig.packageName.isEmpty) {
      tencentConfig.packageName = packageName;
    }
  }

  int id;
  String appName;
  String packageName;
  String apkDir;
  UpdateConfig updateConfig;

  XiaomiConfig xiaomiConfig;
  HuaweiConfig huaweiConfig;
  HonorConfig honorConfig;
  VivoConfig vivoConfig;
  OppoConfig oppoConfig;
  TencentConfig tencentConfig;

  List<BaseChannelConfig> allChannelConfigs() {
    var list = <BaseChannelConfig>[];
    if (xiaomiConfig.isEnable && xiaomiConfig.isComplete) {
      list.add(xiaomiConfig);
    }
    if (huaweiConfig.isEnable && huaweiConfig.isComplete) {
      list.add(huaweiConfig);
    }
    if (honorConfig.isEnable && honorConfig.isComplete) {
      list.add(honorConfig);
    }
    if (vivoConfig.isEnable && vivoConfig.isComplete) {
      list.add(vivoConfig);
    }
    if (oppoConfig.isEnable && oppoConfig.isComplete) {
      list.add(oppoConfig);
    }
    if (tencentConfig.isEnable && tencentConfig.isComplete) {
      list.add(tencentConfig);
    }
    return list;
  }

  bool isComplete() {
    if (appName.isEmpty) {
      SmartDialog.showToast("项目名称不能为空");
      return false;
    }
    if (packageName.isEmpty) {
      SmartDialog.showToast("包名不能为空");
      return false;
    }
    if (apkDir.isEmpty) {
      SmartDialog.showToast("apk目录不能为空");
      return false;
    }

    return true;
  }

  factory ProjectConfig.fromJson(Map<String, dynamic> json) => _$ProjectConfigFromJson(json);
  Map<String, dynamic> toJson() => {
    'id': id,
    'appName': appName,
    'packageName': packageName,
    'apkDir': apkDir,
    'updateConfig': updateConfig.toJson(),
    'xiaomiConfig': xiaomiConfig.toJson(),
    'huaweiConfig': huaweiConfig.toJson(),
    'honorConfig': honorConfig.toJson(),
    'vivoConfig': vivoConfig.toJson(),
    'oppoConfig': oppoConfig.toJson(),
    'tencentConfig': tencentConfig.toJson(),
  };
}

@JsonSerializable()
class XiaomiConfig extends BaseChannelConfig {
  XiaomiConfig({
    required this.userName,
    required this.publicPem,
    required this.privateKey,
    super.packageName,
    super.channel = ChannelEnum.xiaomi,
    super.noteUrl = "https://dev.mi.com/xiaomihyperos/documentation/detail?pId=1134",
  });

  String userName;
  String publicPem;
  String privateKey;

  @override
  bool get isComplete =>
      packageName.isNotEmpty && userName.isNotEmpty && publicPem.isNotEmpty && privateKey.isNotEmpty;

  @override
  BasicChannelManager get bindManager => XiaomiManager();

  @override
  String toString() {
    return 'XiaomiConfig(packageName: $packageName, userName: $userName, publicPem: $publicPem, privateKey: $privateKey)';
  }

  factory XiaomiConfig.fromJson(Map<String, dynamic> json) => _$XiaomiConfigFromJson(json);
  Map<String, dynamic> toJson() => _$XiaomiConfigToJson(this)..["auditInfo"] = auditInfo?.toJson() ?? {};
}

@JsonSerializable()
class HonorConfig extends BaseChannelConfig {
  HonorConfig({
    required this.appId,
    required this.clientId,
    required this.clientSecret,
    this.accessToken = "",
    this.expiresAt = 0,
    super.packageName,
    super.channel = ChannelEnum.honor,
    super.noteUrl = "https://developer.honor.com/cn/doc/guides/101359",
  });
  String clientId;
  String clientSecret;
  String appId;
  String accessToken;
  int expiresAt;

  @override
  bool get isComplete => clientId.isNotEmpty && clientSecret.isNotEmpty && appId.isNotEmpty;

  @override
  BasicChannelManager get bindManager => HonorManager();

  factory HonorConfig.fromJson(Map<String, dynamic> json) => _$HonorConfigFromJson(json);
  Map<String, dynamic> toJson() => _$HonorConfigToJson(this)..["auditInfo"] = auditInfo?.toJson() ?? {};
}

@JsonSerializable()
class HuaweiConfig extends BaseChannelConfig {
  HuaweiConfig({
    required this.appId,
    required this.clientId,
    required this.clientSecret,
    this.accessToken = "",
    this.expiresAt = 0,
    super.packageName,
    super.channel = ChannelEnum.huawei,
    super.noteUrl =
        "https://developer.huawei.com/consumer/cn/doc/app/agc-help-connect-api-obtain-server-auth-0000002271134661",
  });
  String clientId;
  String clientSecret;
  String appId;
  String accessToken;
  int expiresAt;

  @override
  bool get isComplete => clientId.isNotEmpty && clientSecret.isNotEmpty && appId.isNotEmpty;

  @override
  BasicChannelManager get bindManager => HuaweiManager();

  factory HuaweiConfig.fromJson(Map<String, dynamic> json) => _$HuaweiConfigFromJson(json);
  Map<String, dynamic> toJson() => _$HuaweiConfigToJson(this)..["auditInfo"] = auditInfo?.toJson() ?? {};
}

@JsonSerializable()
class VivoConfig extends BaseChannelConfig {
  VivoConfig({
    required this.access_key,
    required this.accessSecret,
    super.packageName,
    super.channel = ChannelEnum.vivo,
    super.noteUrl = "https://dev.vivo.com.cn/documentCenter/doc/326",
  });

  String access_key;
  String accessSecret;

  @override
  bool get isComplete => access_key.isNotEmpty && accessSecret.isNotEmpty && packageName.isNotEmpty;

  @override
  BasicChannelManager get bindManager => VivoManager();

  factory VivoConfig.fromJson(Map<String, dynamic> json) => _$VivoConfigFromJson(json);
  Map<String, dynamic> toJson() => _$VivoConfigToJson(this)..["auditInfo"] = auditInfo?.toJson() ?? {};
}

@JsonSerializable()
class OppoConfig extends BaseChannelConfig {
  OppoConfig({
    this.access_token = "",
    this.expires_at = 0,
    required this.client_id,
    required this.client_secret,
    super.packageName,
    super.channel = ChannelEnum.oppo,
    super.noteUrl = "https://open.oppomobile.com/documentation/page/info?id=10998",
  });
  String access_token;
  int expires_at;
  String client_id;
  String client_secret;

  @override
  bool get isComplete => client_id.isNotEmpty && client_secret.isNotEmpty && packageName.isNotEmpty;

  @override
  BasicChannelManager get bindManager => OppoManager();

  factory OppoConfig.fromJson(Map<String, dynamic> json) => _$OppoConfigFromJson(json);
  Map<String, dynamic> toJson() => _$OppoConfigToJson(this)..["auditInfo"] = auditInfo?.toJson() ?? {};
}

@JsonSerializable()
class TencentConfig extends BaseChannelConfig {
  TencentConfig({
    required this.appId,
    required this.userId,
    required this.secretKey,
    super.packageName,
    super.channel = ChannelEnum.tencent,
    super.noteUrl = "https://wikinew.open.qq.com/index.html#/iwiki/4015262492",
  });
  String appId;
  String userId;
  String secretKey;

  @override
  bool get isComplete => appId.isNotEmpty && userId.isNotEmpty && packageName.isNotEmpty;

  @override
  BasicChannelManager get bindManager => TencentManager();

  factory TencentConfig.fromJson(Map<String, dynamic> json) => _$TencentConfigFromJson(json);
  Map<String, dynamic> toJson() => _$TencentConfigToJson(this)..["auditInfo"] = auditInfo?.toJson() ?? {};
}

abstract class BaseChannelConfig {
  BaseChannelConfig({
    required this.channel,
    this.packageName = "",
    this.isEnable = false,
    this.noteUrl = "",
    this.auditInfo,
    this.uploadApkInfo,
  });
  ChannelEnum channel;
  String packageName;

  //是否启用
  bool isEnable;

  //配置是否可用 null未检查  true可用 false不可用
  bool? isSuccess;

  //文档地址
  String noteUrl;

  @JsonKey(includeToJson: true, includeFromJson: false)
  UploadApkInfo? uploadApkInfo;
  AuditInfo? auditInfo;

  //是否填写完整
  bool get isComplete;

  BasicChannelManager get bindManager;
}

@JsonSerializable()
class UploadApkInfo {
  UploadApkInfo({this.apkPath = "", this.apkPath32 = "", this.apkPath64 = ""});
  String apkPath;
  String apkPath32;
  String apkPath64;

  factory UploadApkInfo.fromJson(Map<String, dynamic> json) => _$UploadApkInfoFromJson(json);
  Map<String, dynamic> toJson() => _$UploadApkInfoToJson(this);
}

//审核状态
@JsonSerializable()
class AuditInfo {
  AuditInfo({
    this.releaseVersionCode = 0,
    this.versionCode = 0,
    this.auditStatus = AuditStatus.known,
    this.auditReason = "",
  });
  int releaseVersionCode;
  int versionCode;
  AuditStatus auditStatus;
  //审核意见
  String auditReason;

  factory AuditInfo.fromJson(Map<String, dynamic> json) => _$AuditInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AuditInfoToJson(this);
}
