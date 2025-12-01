import 'package:auto_channel_market_publish/model/package_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'query_apk_result.g.dart';
///@Author jsji
///@Date 2025/10/11
///
///@Description
@JsonSerializable()
class QueryApkResult {
  QueryApkResult({
    this.updateVersion = false,
    this.updateInfo = false,
    this.create = false,
    this.packageInfo,
  });

  //是否允许应用版本更新
  bool updateVersion;

  //是否允许应用信息更新
  bool updateInfo;

  //是否允许新增该包名的应用 无用
  bool create;
  PackageInfo? packageInfo;

  factory QueryApkResult.fromJson(Map<String, dynamic> json) => _$QueryApkResultFromJson(json);
  Map<String, dynamic> toJson() => _$QueryApkResultToJson(this);
}
