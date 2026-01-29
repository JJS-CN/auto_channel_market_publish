import 'dart:convert';
import 'dart:io';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
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
    print("VivoManager queryAppInfo data: $data");
    int versionCode = int.parse(data["versionCode"]);
    //String versionName = data["versionName"];
    //上架状态 0:待上架 1:已上架 2:已下架
    //int saleStatus = data["saleStatus"];
    //审核状态 1:草稿 2:审核中 3:审核通过 4:审核不通过 5:撤销审核
    int status = data["status"];
    //审核不通过原因
    String unPassReason = data["unPassReason"] ?? "";
    //note 通过网页接口查询线上版本号
    var appstoreResult = await Dio(
      BaseOptions(headers: {"Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"}),
    ).post("https://h5-api.appstore.vivo.com.cn/detailInfo", data: {"appId": initConfig.appId});
    var appstoreData = appstoreResult.data;
    var releaseVersionCode = int.parse(appstoreData["version_code"]);
    //var releaseVersionName = appstoreData["version_name"];
    initConfig.auditInfo = AuditInfo(
      releaseVersionCode: releaseVersionCode,
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
  uploadFile({required String filePath, required VivoUploadFileType type}) async {
    _dio.options.contentType = "multipart/form-data";
    var requestData = {
      "method": type.method,
      "packageName": initConfig.packageName,
      "file": MultipartFile.fromFileSync(filePath),
    };
    if (type == VivoUploadFileType.apk) {
      var digest = await compute(md5.convert, File(filePath).readAsBytesSync());
      var fileMd5 = digest.toString();
      requestData["fileMd5"] = fileMd5;
    }
    print("VivoManager uploadFile start: $filePath");
    var result = await _dio.post(
      "",
      data: FormData.fromMap(requestData),
      onSendProgress: (int sent, int total) {
        var progress = sent / total * 100;
        if (progress % 20 == 0) {
          print("uploadFile progress: $progress%");
        }
      },
    );
    var data = result.data;
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
    String icon = "",
    List<String> screenshots = const [],
  }) async {
    _dio.options.contentType = "application/x-www-form-urlencoded;charset=UTF-8";
    var requestData = {
      "method": "app.sync.update.app",
      "packageName": initConfig.packageName,
      "apk": serialnumber,
      "fileMd5": fileMd5,
      "versionCode": versionCode,
      "onlineType": onlineType,
      "updateDesc": updateDesc,
    };
    if (icon.isNotEmpty) {
      requestData["icon"] = icon;
    }
    if (screenshots.isNotEmpty) {
      requestData["screenshot"] = screenshots.join(",");
    }
    var _ = await _dio.post("", data: requestData);
  }

  @override
  Future<bool> checkAuditStats() async {
    try {
      await queryAppInfo();
      initConfig.isSuccess = true;
      return true;
    } catch (e) {
      print("VivoManager checkAuditStats error: $e");
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
    //icon文件上传返回的流水号
    String iconSerialnumber = "";
    if (updateConfig.iconPath.isNotEmpty) {
      //上传图标
      var uploadData = await uploadFile(filePath: updateConfig.iconPath, type: VivoUploadFileType.icon);
      iconSerialnumber = uploadData["serialnumber"];
    }

    List<String> screenshotSerialnumbers = [];
    if (updateConfig.screenshotPaths.isNotEmpty) {
      //上传截图
      for (var screenshotPath in updateConfig.screenshotPaths) {
        var uploadData = await uploadFile(filePath: screenshotPath, type: VivoUploadFileType.screenshot);
        screenshotSerialnumbers.add(uploadData["serialnumber"]);
      }
    }
    var uploadData = await uploadFile(filePath: apkPath!, type: VivoUploadFileType.apk);
    var serialnumber = uploadData["serialnumber"];
    var versionCode = int.parse(uploadData["versionCode"]);
    var fileMd5 = uploadData["fileMd5"];
    var _ = await publishApp(
      serialnumber: serialnumber,
      fileMd5: fileMd5,
      versionCode: versionCode,
      updateDesc: updateConfig.updateDesc,
      icon: iconSerialnumber,
      screenshots: screenshotSerialnumbers,
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

enum VivoUploadFileType {
  icon("app.upload.icon"),
  screenshot("app.upload.screenshot"),
  apk("app.upload.apk.app");

  final String method;
  const VivoUploadFileType(this.method);
}
