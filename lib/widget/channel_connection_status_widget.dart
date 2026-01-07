import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:flutter/material.dart';

///渠道连接状态组件
class ChannelConnectionStatusWidget extends StatelessWidget {
  const ChannelConnectionStatusWidget({super.key, required this.channelConfig});
  final BaseChannelConfig channelConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          channelConfig.isSuccess == false
              ? Icon(Icons.link_off, color: Colors.red, size: 16)
              : Icon(
                  Icons.link,
                  color: channelConfig.isSuccess == true ? Colors.green : Colors.grey,
                  size: 16,
                ),
          SizedBox(width: 5),
          Text(
            channelConfig.channel.name,
            style: TextStyle(
              fontSize: 14,
              color: channelConfig.isSuccess == true ? Colors.black : Colors.grey,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
