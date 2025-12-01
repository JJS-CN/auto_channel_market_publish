import 'package:auto_channel_market_publish/manager/channel_config_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/net/xiaomi_manager.dart';
import 'package:auto_channel_market_publish/widget/simple_button.dart';
import 'package:flutter/material.dart';

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
  late ChannelConfigs tempChannelConfigs;
  @override
  void initState() {
    super.initState();
    print("channelConfigs:${ChannelConfigManager().channelConfigs.toJson()}");
    tempChannelConfigs = ChannelConfigs.fromJson(ChannelConfigManager().channelConfigs.toJson());
    print("tempChannelConfigs:${tempChannelConfigs.toJson()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("编辑渠道配置")),
      body: ListView(
        shrinkWrap: true,
        children: [
          buildXiaomiCard(),
          SimpleButton("确认", () {
            //note 确认
            var originChannelConfigs = ChannelConfigManager().channelConfigs;
            if (originChannelConfigs.xiaomiConfig.toJson() != tempChannelConfigs.xiaomiConfig.toJson() &&
                tempChannelConfigs.xiaomiConfig.isComplete) {
              XiaomiManager()
                  .queryApkConfig(
                    xiaomiConfig: tempChannelConfigs.xiaomiConfig,
                  )
                  .then((value) {
                    tempChannelConfigs.xiaomiConfig.queryApkResult = value;
                    tempChannelConfigs.xiaomiConfig.errorMessage = "";
                    tempChannelConfigs.xiaomiConfig.lastCheckSuccessTime =
                        DateTime.now().millisecondsSinceEpoch;
                    ChannelConfigManager().channelConfigs.xiaomiConfig = tempChannelConfigs.xiaomiConfig;
                    ChannelConfigManager().saveLocalConfig();
                    setState(() {});
                  })
                  .onError((e, s) {
                    tempChannelConfigs.xiaomiConfig.errorMessage = e.toString();
                    setState(() {});
                  });
              //XiaomiManager().queryCategory().then((v) {});
            }
          }),
        ],
      ),
    );
  }

  ///小米
  Widget buildXiaomiCard() {
    return _buildChannelCard(
      tempConfigs: tempChannelConfigs.xiaomiConfig,
      originConfigs: ChannelConfigManager().channelConfigs.xiaomiConfig,
      children: [
        _buildInputRow(
          label: "用户名",
          hintText: "请输入开发者账号(邮箱)",
          initialValue: tempChannelConfigs.xiaomiConfig.userName,
          onChanged: (value) {
            tempChannelConfigs.xiaomiConfig.userName = value;
          },
        ),
        _buildInputRow(
          label: "包名",
          initialValue: tempChannelConfigs.xiaomiConfig.packageName,
          onChanged: (value) {
            tempChannelConfigs.xiaomiConfig.packageName = value;
          },
        ),
        _buildInputRow(
          label: "公钥",
          hintText: "请保持换行",
          initialValue: tempChannelConfigs.xiaomiConfig.publicPem,
          onChanged: (value) {
            tempChannelConfigs.xiaomiConfig.publicPem = value;
          },
        ),
        _buildInputRow(
          label: "私钥",
          initialValue: tempChannelConfigs.xiaomiConfig.privateKey,
          onChanged: (value) {
            tempChannelConfigs.xiaomiConfig.privateKey = value;
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
      channelChildren.addAll(children);
    }
    return _buildCardPage(children: channelChildren);
  }

  ///通用输入框组件
  Widget _buildInputRow({
    String label = "",
    String initialValue = "",
    String hintText = "",
    required Function(String) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Text(label + ":", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              hintText.isNotEmpty
                  ? Container(
                      margin: EdgeInsets.only(bottom: 3),
                      child: Text(hintText, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    )
                  : Container(),
              Container(
                width: 400,
                constraints: BoxConstraints(minHeight: 30, maxHeight: 80),
                child: TextField(
                  minLines: 1,
                  maxLines: null,
                  style: TextStyle(fontSize: 12),
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
        ],
      ),
    );
  }

  ///通用标题组件
  Widget _buildTitleRow(BaseChannelConfig tempConfigs, BaseChannelConfig originConfigs) {
    return Row(
      children: [
        Text(tempConfigs.channelName, style: TextStyle(fontSize: 15)),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
          child: Text(
            !tempConfigs.isComplete
                ? "未配置"
                : tempConfigs.toString() != originConfigs.toString() || tempConfigs.queryApkResult == null
                ? "未验证"
                : "验证成功",
            style: TextStyle(fontSize: 10),
          ),
        ),
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
        Expanded(
          child: Text(
            tempConfigs.queryApkResult?.toJson().toString() ?? tempConfigs.errorMessage,
            style: TextStyle(
              fontSize: 10,
              color: tempConfigs.queryApkResult?.toJson().toString() == null ? Colors.red : Colors.green,
            ),
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
