import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:auto_channel_market_publish/screen/main_screen.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class VivoManager extends BasicChannelManager<VivoConfig> {
  factory VivoManager() => _instance;
  static final VivoManager _instance = VivoManager._internal();
  VivoManager._internal() {
    //_dio.options.baseUrl = "https://sandbox-developer-api.vivo.com.cn/router/rest";
    _dio.options.baseUrl = "https://developer-api.vivo.com.cn/router/rest";
    _dio.options.contentType = "application/x-www-form-urlencoded;charset=UTF-8";
    _dio.interceptors.add(VivoInterceptor());
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  final _dio = Dio();

  Future<Map<String, dynamic>> queryAppInfo() async {
    _dio.options.contentType = "application/x-www-form-urlencoded;charset=UTF-8";
    var result = await _dio.post(
      "",
      data: {"method": "app.query.details", "packageName": initConfig.packageName},
    );
    var data = result.data;
    int versionCode = int.parse(data["versionCode"]);
    String versionName = data["versionName"];
    //上架状态 0:待上架 1:已上架 2:已下架
    int saleStatus = data["saleStatus"];
    //审核状态 1:草稿 2:审核中 3:审核通过 4:审核不通过 5:撤销审核
    int status = data["status"];
    //审核不通过原因
    String unPassReason = data["unPassReason"] ?? "";
    initConfig.auditInfo = AuditInfo(
      releaseVersionCode: versionCode,
      versionCode: versionCode,
      auditStatus: status == 3
          ? AuditStatus.auditSuccess
          : status == 4
          ? AuditStatus.auditFailed
          : status == 2
          ? AuditStatus.auditing
          : AuditStatus.known,
      auditReason: unPassReason,
    );
    return result.data;
  }

  ///上传文件
  uploadFile({required String filePath}) async {
    var digest = await compute(md5.convert, File(filePath).readAsBytesSync());
    var fileMd5 = digest.toString();
    _dio.options.contentType = "multipart/form-data";
    var result = await _dio.post(
      "",
      data: FormData.fromMap({
        "method": "app.upload.apk.app",
        "packageName": initConfig.packageName,
        "file": MultipartFile.fromFileSync(filePath),
        "fileMd5": fileMd5,
      }),
      onSendProgress: (int sent, int total) {
        print("uploadFile progress: $sent, $total  ${sent / total * 100}%");
      },
    );
    var data = result.data;
    data["versionCode"] = int.parse(data["versionCode"]);
    return data;
  }

  ///发布应用
  ///[onlineType] 1:立即发布 2:定时发布
  ///[serialnumber] 文件上传序列号
  publishApp({
    required String serialnumber,
    required String fileMd5,
    required int versionCode,
    String? updateDesc,
    int onlineType = 1,
  }) async {
    _dio.options.contentType = "application/x-www-form-urlencoded;charset=UTF-8";
    var result = await _dio.post(
      "",
      data: {
        "method": "app.sync.update.app",
        "packageName": initConfig.packageName,
        "apk": serialnumber,
        "fileMd5": fileMd5,
        "versionCode": versionCode,
        "onlineType": onlineType,
        "updateDesc": updateDesc,
      },
    );
  }

  @override
  Future<bool> checkAuditStats() async {
    try {
      await queryAppInfo();
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

    var appInfo = await queryAppInfo();
    var status = appInfo["status"];
    if (status == 2) {
      ///审核中
      SmartDialog.showToast("审核中", displayType: SmartToastType.onlyRefresh);
      return false;
    }
    var uploadData = await uploadFile(filePath: apkPath!);
    var serialnumber = uploadData["serialnumber"];
    var versionCode = uploadData["versionCode"];
    var fileMd5 = uploadData["fileMd5"];
    var result = await publishApp(
      serialnumber: serialnumber,
      fileMd5: fileMd5,
      versionCode: versionCode,
      updateDesc: updateConfig.updateDesc,
    );
    return true;
  }
}

class VivoInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    if (options.data is FormData) {
      options.data.fields.add(MapEntry("timestamp", timestamp.toString()));
      options.data.fields.add(MapEntry("access_key", VivoManager().initConfig.access_key));
      options.data.fields.add(MapEntry("format", "json"));
      options.data.fields.add(MapEntry("v", "1.0"));
      options.data.fields.add(MapEntry("sign_method", "HMAC-SHA256"));
      options.data.fields.add(MapEntry("target_app_key", "developer"));
    } else {
      options.data["timestamp"] = timestamp.toString();
      options.data["access_key"] = VivoManager().initConfig.access_key;
      options.data["format"] = "json";
      options.data["v"] = "1.0";
      options.data["sign_method"] = "HMAC-SHA256";
      options.data["target_app_key"] = "developer";
    }
    //先进行ascii码排序

    var sortedRequestData = [];
    if (options.data is FormData) {
      for (var entry in options.data.fields) {
        sortedRequestData.add(MapEntry(entry.key, entry.value));
      }
    } else {
      for (var entry in options.data.entries) {
        sortedRequestData.add(MapEntry(entry.key, entry.value));
      }
    }
    sortedRequestData.sort((a, b) => a.key.compareTo(b.key));

    //开始进行签名计算
    String signString = "";
    sortedRequestData.forEach((entry) {
      //排除file参数
      if (entry.key != "file") {
        signString += "${entry.key}=${entry.value}&";
      }
    });
    //去掉最后一个&
    signString = signString.substring(0, signString.length - 1);
    //进行HmacSHA256计算
    var hmacSHA256 = Hmac(sha256, utf8.encode(VivoManager().initConfig.accessSecret));
    var sign = hmacSHA256.convert(utf8.encode(signString));
    if (options.data is FormData) {
      options.data.fields.add(MapEntry("sign", sign.toString().toLowerCase()));
    } else {
      options.data["sign"] = sign.toString().toLowerCase();
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data["code"] == 0) {
      response.data = response.data["data"];
      handler.next(response);
    } else {
      handler.reject(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: response.requestOptions,
          message: response.data.toString(),
        ),
      );
    }
  }
}
