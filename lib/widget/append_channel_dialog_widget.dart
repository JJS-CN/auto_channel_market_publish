import 'package:auto_channel_market_publish/const/app_enums.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:flutter/material.dart';

class AppendChannelDialogWidget extends StatefulWidget {
  const AppendChannelDialogWidget({super.key, this.channelConfig});
  final ChannelConfig? channelConfig;
  @override
  State<StatefulWidget> createState() {
    return _AppendChannelDialogWidgetState();
  }
}

class _AppendChannelDialogWidgetState extends State<AppendChannelDialogWidget> {
  List<ChannelEnum> channelEnumList = [];
  ChannelConfig channelConfig = ChannelConfig();
  @override
  void initState() {
    super.initState();
    if (widget.channelConfig != null) {
      channelConfig = widget.channelConfig!;
      channelEnumList = [channelConfig.channelEnum];
    } else {
      channelEnumList = ChannelEnum.values.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(10),
        width: 300,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${widget.channelConfig != null ? "编辑" : "新增"}渠道配置"),
            Row(
              children: [
                Text("渠道类型:"),
                DropdownButton(
                  value: channelConfig.channelEnum,
                  items: channelEnumList.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                  onChanged: (value) {
                    //note 选择渠道类型
                    if (value == null) return;
                    setState(() {
                      channelConfig.channelEnum = value;
                      
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
