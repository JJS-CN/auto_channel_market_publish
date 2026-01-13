import 'package:auto_channel_market_publish/manager/config_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/widget/simple_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

///@Author jsji
///@Date 2025/11/7
///
///@Description

class EditChannelConfigScreen extends StatefulWidget {
  const EditChannelConfigScreen({super.key});

  @override
  State<EditChannelConfigScreen> createState() => _EditChannelConfigScreenState();
}

class _EditChannelConfigScreenState extends State<EditChannelConfigScreen> {
  late ProjectConfig tempProjectConfig;
  late ProjectConfig originProjectConfig;
  @override
  void initState() {
    super.initState();
    tempProjectConfig = ProjectConfig.fromJson(ConfigManager().getCurrentProject().toJson());
    originProjectConfig = ProjectConfig.fromJson(ConfigManager().getCurrentProject().toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("编辑渠道配置")),
      body: ListView(
        shrinkWrap: true,
        children: [
          buildXiaomiCard(),
          buildHuaweiCard(),
          buildHonorCard(),
          buildVivoCard(),
          buildOppoCard(),
          buildTencentCard(),
          SimpleButton("确认", () {
            //note 确认
            print("tempProjectConfig: ${tempProjectConfig.toJson()}");
            ConfigManager().autoSaveProject(tempProjectConfig);
            GoRouter.of(context).pop();
          }),
        ],
      ),
    );
  }

  ///华为
  Widget buildHuaweiCard() {
    var huaweiConfig = tempProjectConfig.huaweiConfig;
    var originHuaweiConfig = originProjectConfig.huaweiConfig;
    return _buildChannelCard(
      tempConfigs: huaweiConfig,
      originConfigs: originHuaweiConfig,
      children: [
        _buildInputRow(
          label: "ClientId",
          initialValue: huaweiConfig.clientId,
          onChanged: (value) {
            huaweiConfig.clientId = value;
          },
        ),
        _buildInputRow(
          label: "ClientSecret",
          initialValue: huaweiConfig.clientSecret,
          onChanged: (value) {
            huaweiConfig.clientSecret = value;
          },
        ),
        _buildInputRow(
          label: "AppId",
          initialValue: huaweiConfig.appId,
          onChanged: (value) {
            huaweiConfig.appId = value;
          },
        ),
      ],
    );
  }

  ///荣耀
  Widget buildHonorCard() {
    var honorConfig = tempProjectConfig.honorConfig;
    var originHonorConfig = originProjectConfig.honorConfig;
    return _buildChannelCard(
      tempConfigs: honorConfig,
      originConfigs: originHonorConfig,
      children: [
        _buildInputRow(
          label: "AppId",
          initialValue: honorConfig.appId,
          onChanged: (value) {
            honorConfig.appId = value;
          },
        ),
        _buildInputRow(
          label: "ClientId",
          initialValue: honorConfig.clientId,
          onChanged: (value) {
            honorConfig.clientId = value;
          },
        ),
        _buildInputRow(
          label: "ClientSecret",
          initialValue: honorConfig.clientSecret,
          onChanged: (value) {
            honorConfig.clientSecret = value;
          },
        ),
      ],
    );
  }

  ///vivo
  Widget buildVivoCard() {
    var vivoConfig = tempProjectConfig.vivoConfig;
    var originVivoConfig = originProjectConfig.vivoConfig;
    return _buildChannelCard(
      tempConfigs: vivoConfig,
      originConfigs: originVivoConfig,
      children: [
        _buildInputRow(
          label: "AccessKey",
          initialValue: vivoConfig.access_key,
          onChanged: (value) {
            vivoConfig.access_key = value;
          },
        ),
        _buildInputRow(
          label: "AccessSecret",
          initialValue: vivoConfig.accessSecret,
          onChanged: (value) {
            vivoConfig.accessSecret = value;
          },
        ),
        _buildInputRow(
          label: "AppId",
          initialValue: vivoConfig.appId,
          onChanged: (value) {
            vivoConfig.appId = value;
          },
        ),
      ],
    );
  }

  ///oppo
  Widget buildOppoCard() {
    var oppoConfig = tempProjectConfig.oppoConfig;
    var originOppoConfig = originProjectConfig.oppoConfig;
    return _buildChannelCard(
      tempConfigs: oppoConfig,
      originConfigs: originOppoConfig,
      children: [
        _buildInputRow(
          label: "ClientId",
          initialValue: oppoConfig.client_id,
          onChanged: (value) {
            oppoConfig.client_id = value;
          },
        ),
        _buildInputRow(
          label: "ClientSecret",
          initialValue: oppoConfig.client_secret,
          onChanged: (value) {
            oppoConfig.client_secret = value;
          },
        ),
      ],
    );
  }

  ///tencent
  Widget buildTencentCard() {
    var tencentConfig = tempProjectConfig.tencentConfig;
    var originTencentConfig = originProjectConfig.tencentConfig;
    return _buildChannelCard(
      tempConfigs: tencentConfig,
      originConfigs: originTencentConfig,
      children: [
        _buildInputRow(
          label: "AppId",
          initialValue: tencentConfig.appId,
          onChanged: (value) {
            tencentConfig.appId = value;
          },
        ),
        _buildInputRow(
          label: "UserId",
          initialValue: tencentConfig.userId,
          onChanged: (value) {
            tencentConfig.userId = value;
          },
        ),
        _buildInputRow(
          label: "SecretKey",
          initialValue: tencentConfig.secretKey,
          onChanged: (value) {
            tencentConfig.secretKey = value;
          },
        ),
        _buildInputRow(
          label: "线上版本号",
          hintText: "当线上版本号与配置不一致时修改",
          keyboardType: TextInputType.number,
          initialValue: tencentConfig.auditInfo?.releaseVersionCode.toString() ?? "-1",
          onChanged: (value) {
            tencentConfig.auditInfo ??= AuditInfo();
            if (value.isNotEmpty) {
              tencentConfig.auditInfo?.releaseVersionCode = int.parse(value);
            } else {
              tencentConfig.auditInfo?.releaseVersionCode = -1;
            }
          },
        ),
      ],
    );
  }

  ///小米
  Widget buildXiaomiCard() {
    var xiaomiConfig = tempProjectConfig.xiaomiConfig;
    var originXiaomiConfig = originProjectConfig.xiaomiConfig;
    return _buildChannelCard(
      tempConfigs: xiaomiConfig,
      originConfigs: originXiaomiConfig,
      children: [
        _buildInputRow(
          label: "用户名",
          hintText: "开发者账号(邮箱)",
          initialValue: xiaomiConfig.userName,
          onChanged: (value) {
            xiaomiConfig.userName = value;
          },
        ),
        _buildInputRow(
          label: "公钥",
          hintText: "将下载的cer证书转换为pem格式,复制全部",
          initialValue: xiaomiConfig.publicPem,
          onChanged: (value) {
            xiaomiConfig.publicPem = value;
          },
        ),
        _buildInputRow(
          label: "私钥",
          initialValue: xiaomiConfig.privateKey,
          onChanged: (value) {
            xiaomiConfig.privateKey = value;
          },
        ),
      ],
    );
  }

  ///渠道卡片组件
  Widget _buildChannelCard({
    required BaseChannelConfig tempConfigs,
    required BaseChannelConfig originConfigs,
    required List<Widget> children,
  }) {
    List<Widget> channelChildren = [];
    channelChildren.add(_buildTitleRow(tempConfigs, originConfigs));
    if (tempConfigs.isEnable) {
      channelChildren.addAll(
        children..add(
          _buildInputRow(
            label: "包名",
            initialValue: tempConfigs.packageName,
            onChanged: (value) {
              tempConfigs.packageName = value;
            },
          ),
        ),
      );
    }
    return _buildCardPage(children: channelChildren);
  }

  ///通用输入框组件
  Widget _buildInputRow({
    String label = "",
    String initialValue = "",
    String hintText = "",
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 70,
            child: Text(label + ":", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                hintText.isNotEmpty
                    ? Container(
                        margin: EdgeInsets.only(bottom: 3),
                        child: Text(hintText, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                      )
                    : Container(),
                Container(
                  constraints: BoxConstraints(minHeight: 30, maxHeight: 80, minWidth: 100, maxWidth: 550),
                  child: TextField(
                    minLines: 1,
                    maxLines: null,
                    style: TextStyle(fontSize: 12),
                    keyboardType: keyboardType,
                    controller: TextEditingController(text: initialValue),
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade100,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade200),
                        gapPadding: 0,
                      ),
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      filled: true,
                      isDense: true,
                    ),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ///通用标题组件
  Widget _buildTitleRow(BaseChannelConfig tempConfigs, BaseChannelConfig originConfigs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(tempConfigs.channel.name, style: TextStyle(fontSize: 15)),

            SizedBox(width: 10),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: tempConfigs.isEnable,
                onChanged: (v) {
                  tempConfigs.isEnable = v;
                  setState(() {});
                },
              ),
            ),
            // Expanded(
            //   child: Text(
            //     "1222222222222",
            //     style: TextStyle(fontSize: 10, color: true ? Colors.red : Colors.green),
            //   ),
            // ),
          ],
        ),
        if (tempConfigs.isEnable)
          GestureDetector(
            onTap: () {
              launchUrl(Uri.parse(tempConfigs.noteUrl), mode: LaunchMode.externalApplication);
            },
            child: Row(
              children: [
                Text("文档: ", style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                Expanded(
                  child: Text(tempConfigs.noteUrl, style: TextStyle(fontSize: 10, color: Colors.blue)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  ///通用卡片组件
  Widget _buildCardPage({required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
