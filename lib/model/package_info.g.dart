// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageInfo _$PackageInfoFromJson(Map<String, dynamic> json) => PackageInfo(
  appName: json['appName'] as String? ?? "",
  packageName: json['packageName'] as String? ?? "",
  versionName: json['versionName'] as String? ?? "",
  versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
  onlineVersionCode: (json['onlineVersionCode'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PackageInfoToJson(PackageInfo instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'packageName': instance.packageName,
      'versionName': instance.versionName,
      'onlineVersionCode': instance.onlineVersionCode,
      'versionCode': instance.versionCode,
    };
