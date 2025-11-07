///@Author jsji
///@Date 2025/10/11
///
///@Description

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

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      appName: json['appName'],
      packageName: json['packageName'],
      versionName: json['versionName'],
      versionCode: json['versionCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'versionName': versionName,
      'versionCode': versionCode,
    };
  }
}
