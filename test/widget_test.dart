// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/net/huawei_manager.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main()  async {
 HuaweiManager manager = HuaweiManager();
 manager.init(HuaweiConfig.fromJson(json.decode('{"channel":"huawei","packageName":"com.fungo.aigirl","isEnable":true,"isSuccess":true,"noteUrl":"https://developer.huawei.com/consumer/cn/doc/app/agc-help-connect-api-obtain-server-auth-0000002271134661","uploadApkInfo":null,"auditInfo":{"releaseVersionCode":204000,"versionCode":204000,"auditStatus":"auditSuccess","auditReason":"应用审核意见：    通过    测试环境：Wi-Fi联网、HarmonyOS 4.2.0(Mate60)、中文环境。"},"clientId":"1839329100804679360","clientSecret":"0C284FBE39BD02B711868F271BF070FC0A68921604FA1DB6781FC97B509CC1CB","appId":"110891381","accessToken":"eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxODM5MzI5MTAwODA0Njc5MzYwIiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjkwNjg0MjYsImlhdCI6MTc2ODg5NTYyNn0.ED9azPwDedYoNltD1tGsjxQ5YmIJuQrhBBil7cWy8qs","expiresAt":1769068425867}')));
 await manager.checkAuditStats();
}
