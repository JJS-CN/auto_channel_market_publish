// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_apk_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueryApkResult _$QueryApkResultFromJson(Map<String, dynamic> json) => QueryApkResult(
  updateVersion: json['updateVersion'] as bool? ?? false,
  updateInfo: json['updateInfo'] as bool? ?? false,
  create: json['create'] as bool? ?? false,
  packageInfo: json['packageInfo'] == null
      ? null
      : PackageInfo.fromJson(json['packageInfo'] as Map<String, dynamic>),
);

Map<String, dynamic> _$QueryApkResultToJson(QueryApkResult instance) => <String, dynamic>{
  'updateVersion': instance.updateVersion,
  'updateInfo': instance.updateInfo,
  'create': instance.create,
  'packageInfo': instance.packageInfo?.toJson(),
};
