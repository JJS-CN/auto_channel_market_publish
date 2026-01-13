import 'package:auto_channel_market_publish/model/channel_config.dart';

abstract class BasicChannelManager<T extends BaseChannelConfig> {
  late T _initConfig;

  void init(T config) {
    _initConfig = config;
  }

  T get initConfig => _initConfig;

  ///检查渠道配置是否成功
  Future<bool> checkAuditStats();

  ///开始发布
  Future<bool> startPublish(UpdateConfig updateConfig);
}
