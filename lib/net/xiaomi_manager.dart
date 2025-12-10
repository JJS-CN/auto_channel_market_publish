import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_channel_market_publish/manager/channel_config_manager.dart';
import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/query_apk_result.dart';
import 'package:auto_channel_market_publish/net/xiaomi_helper.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

///@Author jsji
///@Date 2025/10/11
///
///@Description

class XiaomiManager {
  factory XiaomiManager() => _instance;
  static final XiaomiManager _instance = XiaomiManager._internal();

  XiaomiManager._internal() {
    _dio.options.baseUrl = "https://api.developer.xiaomi.com/devupload";
    _dio.options.contentType = "multipart/form-data;";
    _dio.interceptors.add(XiaomiInterceptor());
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  StreamController<double> _publishProgressController = StreamController<double>.broadcast();
  Stream<double> get publishProgressStream => _publishProgressController.stream;

  final _dio = Dio();

  ///查询apk配置
  Future<QueryApkResult> queryApkConfig({ XiaomiConfig? xiaomiConfig}) async {
    xiaomiConfig ??= ChannelConfigManager().channelConfigs.xiaomiConfig;
    var requestData = {"packageName": xiaomiConfig.packageName, "userName": xiaomiConfig.userName};
    Map<String, dynamic> sigData = {
      "password": xiaomiConfig.privateKey,
      "sig": [
        {"name": "RequestData", "hash": md5.convert(utf8.encode(json.encode(requestData))).toString()},
      ],
    };
    var encrypted = await XiaomiHelper.encodeSIG(xiaomiConfig.publicPem, sigData);
    var fromData = {"RequestData": json.encode(requestData), "SIG": encrypted};
    var result = await _dio.post("/dev/query", data: FormData.fromMap(fromData));
    return QueryApkResult.fromJson(result.data);
  }

  ///查询所有的应用类别(好像没用处)
  Future<dynamic> queryCategory(XiaomiConfig xiaomiConfig) async {
    var requestData = {};
    Map<String, dynamic> sigData = {
      "password": xiaomiConfig.privateKey,
      "sig": [
        {"name": "RequestData", "hash": md5.convert(utf8.encode(json.encode(requestData))).toString()},
      ],
    };
    var encrypted = await XiaomiHelper.encodeSIG(xiaomiConfig.publicPem, sigData);
    var fromData = {"RequestData": json.encode(requestData), "SIG": encrypted};
    var result = await _dio.post("/dev/category", data: FormData.fromMap(fromData));
    print(result.data.toString());
    return Future.value(true);
  }

  ///发布应用
  ///[synchroType] 更新类型(1:apk,2:信息)
  ///[xiaomiConfig] 小米配置
  ///[appName] 应用名称
  publish({
    required XiaomiSynchroType synchroType,
    required XiaomiConfig xiaomiConfig,
    required String appName,
    String? iconPath,
    String? apkPath,
    String? secondApkPath,
    String? updateDesc,
    List<String>? screenshotPaths,
  }) async {
    XiaomiAppInfo appInfo = XiaomiAppInfo(appName: appName, packageName: xiaomiConfig.packageName);
    if (updateDesc != null) {
      appInfo.updateDesc = updateDesc;
    }
    var requestData = {
      "userName": xiaomiConfig.userName,
      "synchroType": synchroType.synchroType,
      "appInfo": appInfo.toJson(),
    };
    Map<String, dynamic> sigData = {
      "password": xiaomiConfig.privateKey,
      "sig": [
        {"name": "RequestData", "hash": md5.convert(utf8.encode(json.encode(requestData))).toString()},
      ],
    };

    var fromData = <String, dynamic>{"RequestData": json.encode(requestData)};
    if (iconPath != null) {
      fromData["icon"] = MultipartFile.fromFileSync(iconPath);
      sigData["sig"].add({"name": "icon", "hash": md5.convert(File(iconPath).readAsBytesSync()).toString()});
    }
    if (apkPath != null) {
      fromData["apk"] = MultipartFile.fromFileSync(apkPath);
      sigData["sig"].add({"name": "apk", "hash": md5.convert(File(apkPath).readAsBytesSync()).toString()});
    }
    if (secondApkPath != null) {
      fromData["secondApk"] = MultipartFile.fromFileSync(secondApkPath);
      sigData["sig"].add({
        "name": "secondApk",
        "hash": md5.convert(File(secondApkPath).readAsBytesSync()).toString(),
      });
    }
    if (screenshotPaths != null && screenshotPaths.isNotEmpty) {
      for (int index = 0; index < screenshotPaths.length; index++) {
        var screenshotPath = screenshotPaths[index];
        fromData["screenshot_${index + 1}"] = MultipartFile.fromFileSync(screenshotPath);
        sigData["sig"].add({
          "name": "screenshot_${index + 1}",
          "hash": md5.convert(File(screenshotPath).readAsBytesSync()).toString(),
        });
      }
    }

    var encrypted = await XiaomiHelper.encodeSIG(xiaomiConfig.publicPem, sigData);
    fromData["SIG"] = encrypted;
    var result = await _dio.post(
      "/dev/push",
      data: FormData.fromMap(fromData),
      onSendProgress: (int sent, int total) {
        _publishProgressController.add(sent ~/ total * 100);
      },
    );
    print(result.data.toString());
    return Future.value(true);
  }
}

enum XiaomiSynchroType {
  // add(0, "新增"),
  apkUpdate(1, "应用包更新"),
  infoUpdate(2, "应用信息更新");

  final int _value;
  // ignore: unused_field
  final String _name;
  int get synchroType => _value;

  const XiaomiSynchroType(this._value, this._name);
}

class XiaomiAppInfo {
  XiaomiAppInfo({
    required this.appName,
    required this.packageName,
    this.desc = "",
    this.updateDesc = "",
    this.brief = "",
  });
  String appName;
  String packageName;

  /// 描述
  String desc;

  /// 更新说明(更新apk时必填)
  String updateDesc;

  /// 一句话简介
  String brief;

  ///tojson,但为空的不处理
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (appName.isNotEmpty) json["appName"] = appName;
    if (packageName.isNotEmpty) json["packageName"] = packageName;
    if (desc.isNotEmpty) json["desc"] = desc;
    if (updateDesc.isNotEmpty) json["updateDesc"] = updateDesc;
    if (brief.isNotEmpty) json["brief"] = brief;
    return json;
  }
}
