import 'package:auto_channel_market_publish/model/channel_config.dart';

enum ChannelEnum {
  xiaomi,
  ;

  Map<String, dynamic> getConfigData() {
    switch (this) {
      case ChannelEnum.xiaomi:
        return XiaomiConfig().toJson();
    }
  }
}
