import 'package:json_annotation/json_annotation.dart';
part 'package_info.g.dart';


///@Author jsji
///@Date 2025/10/11
///
///@Description

@JsonSerializable()
class PackageInfo {
  PackageInfo({
    this.appName = "",
    this.packageName = "",
    this.versionName = "",
    this.versionCode = 0,
    this.onlineVersionCode = 0,
  });

  String appName;
  String packageName;

  String versionName;
  int onlineVersionCode;
  int versionCode;

  factory PackageInfo.fromJson(Map<String, dynamic> json) => _$PackageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PackageInfoToJson(this);
}
