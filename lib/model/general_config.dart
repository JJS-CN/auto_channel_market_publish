///@Author jsji
///@Date 2025/10/11
///
///@Description 通用配置
class GeneralConfig {
  GeneralConfig({
    this.updateDesc = "",
    this.brief = "",
    this.screenshotDir = "",
    this.apkDir = "",
  });

  //更新说明
  String updateDesc;

  //一句话简介
  String brief;

  //市场图的文件夹地址(选择)
  String screenshotDir;

  //apk的文件夹地址(选择)
  String apkDir;
}
