import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/model/query_apk_result.dart';
import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:auto_channel_market_publish/net/xiaomi_helper.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

///@Author jsji
///@Date 2025/10/11
///
///@Description

class XiaomiManager extends BasicChannelManager<XiaomiConfig> {
  factory XiaomiManager() => _instance;
  static final XiaomiManager _instance = XiaomiManager._internal();

  XiaomiManager._internal() {
    _dio.options.baseUrl = "https://api.developer.xiaomi.com/devupload";
    _dio.options.contentType = "multipart/form-data;";
    _dio.interceptors.add(XiaomiInterceptor());
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  final _dio = Dio();

  ///查询apk配置
  Future<QueryApkResult> _queryApkConfig() async {
    var requestData = {"packageName": initConfig.packageName, "userName": initConfig.userName};
    Map<String, dynamic> sigData = {
      "password": initConfig.privateKey,
      "sig": [
        {"name": "RequestData", "hash": md5.convert(utf8.encode(json.encode(requestData))).toString()},
      ],
    };
    var encrypted = await XiaomiHelper.encodeSIG(initConfig.publicPem, sigData);
    var fromData = {"RequestData": json.encode(requestData), "SIG": encrypted};
    var result = await _dio.post("/dev/query", data: FormData.fromMap(fromData));
    //允许更新版本
    var updateVersion = result.data["updateVersion"];
    //允许更新信息
    var updateInfo = result.data["updateInfo"];
    //允许新增应用
    //var create = result.data["create"];
    //应用信息
    var packageInfo = result.data["packageInfo"];
    int onlineVersionCode = packageInfo["onlineVersionCode"];
    int versionCode = packageInfo["versionCode"];
    initConfig.auditInfo = AuditInfo(
      releaseVersionCode: onlineVersionCode,
      versionCode: versionCode,
      auditStatus: updateVersion && updateInfo ? AuditStatus.auditSuccess : AuditStatus.auditing,
    );
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
    var _ = await _dio.post("/dev/category", data: FormData.fromMap(fromData));
    return Future.value(true);
  }

  ///发布应用
  ///[synchroType] 更新类型(1:apk,2:信息)
  ///[xiaomiConfig] 小米配置
  ///[appName] 应用名称
  publish({
    required XiaomiSynchroType synchroType,
    required String appName,
    String? apkPath,
    String? secondApkPath,
    required UpdateConfig updateConfig,
  }) async {
    XiaomiAppInfo appInfo = XiaomiAppInfo(appName: appName, packageName: initConfig.packageName);
    if (updateConfig.updateDesc.isNotEmpty) {
      appInfo.updateDesc = updateConfig.updateDesc;
    }
    var requestData = {
      "userName": initConfig.userName,
      "synchroType": synchroType.synchroType,
      "appInfo": appInfo.toJson(),
    };
    Map<String, dynamic> sigData = {
      "password": initConfig.privateKey,
      "sig": [
        {"name": "RequestData", "hash": md5.convert(utf8.encode(json.encode(requestData))).toString()},
      ],
    };

    var fromData = <String, dynamic>{"RequestData": json.encode(requestData)};
    if (updateConfig.iconPath.isNotEmpty) {
      fromData["icon"] = MultipartFile.fromFileSync(updateConfig.iconPath);
      sigData["sig"].add({
        "name": "icon",
        "hash": md5.convert(File(updateConfig.iconPath).readAsBytesSync()).toString(),
      });
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
    if (updateConfig.screenshotPaths.isNotEmpty) {
      for (int index = 0; index < updateConfig.screenshotPaths.length; index++) {
        var screenshotPath = updateConfig.screenshotPaths[index];
        fromData["screenshot_${index + 1}"] = MultipartFile.fromFileSync(screenshotPath);
        sigData["sig"].add({
          "name": "screenshot_${index + 1}",
          "hash": md5.convert(File(screenshotPath).readAsBytesSync()).toString(),
        });
      }
    }

    var encrypted = await XiaomiHelper.encodeSIG(initConfig.publicPem, sigData);
    fromData["SIG"] = encrypted;
    var _ = await _dio.post(
      "/dev/push",
      data: FormData.fromMap(fromData),
      onSendProgress: (int sent, int total) {
        print("xiaomi publish progress: $sent, $total  ${sent / total * 100}%");
      },
    );
    return Future.value(true);
  }

  @override
  Future<bool> checkAuditStats() async {
    try {
      await _queryApkConfig();
      initConfig.isSuccess = true;
      return true;
    } catch (e) {
      initConfig.isSuccess = false;
      return false;
    }
  }

  @override
  Future<bool> startPublish(UpdateConfig updateConfig) async {
    var apkPath = initConfig.uploadApkInfo?.apkPath;
    var apkInfo = await _queryApkConfig();

    var _ = await publish(
      synchroType: XiaomiSynchroType.apkUpdate,
      appName: apkInfo.packageInfo!.appName,
      apkPath: apkPath,
      updateConfig: updateConfig,
    );

    return true;
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
