import 'dart:io';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:auto_channel_market_publish/screen/main_screen.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class HuaweiManager extends BasicChannelManager<HuaweiConfig> {
  factory HuaweiManager() => _instance;
  static final HuaweiManager _instance = HuaweiManager._internal();
  HuaweiManager._internal() {
    _dio.options.baseUrl = "https://connect-api.cloud.huawei.com/api";
    _dio.options.contentType = "application/json;charset=UTF-8";
    _dio.interceptors.add(HuaweiInterceptor());
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  final _dio = Dio();

  ///获取token
  getToken() async {
    var data = {
      "client_id": initConfig.clientId,
      "client_secret": initConfig.clientSecret,
      "grant_type": "client_credentials",
    };
    var _tempDio = Dio();
    _tempDio.options.contentType = "application/json;charset=UTF-8";
    _tempDio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    var result = await _tempDio.post("https://connect-api.cloud.huawei.com/api/oauth2/v1/token", data: data);
    //{"access_token":"eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxNDUxNTQyMzM1MTY1ODU2MDY0IiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjQ3NTY2NzIsImlhdCI6MTc2NDU4Mzg3Mn0.xtwd7XoeJGd2mDyOrndLre5o219bh4yB77lKyI0km9I","expires_in":172799}
    var accessToken = result.data["access_token"];
    var expiresIn = result.data["expires_in"];
    var now = DateTime.now();
    var expiresAt = now.add(Duration(seconds: expiresIn));
    initConfig.accessToken = accessToken;
    initConfig.expiresAt = expiresAt.millisecondsSinceEpoch;
    return result.data;
  }

  ///查询应用信息 appid可以直接从后台获取
  queryApkInfo() async {
    var result = await _dio.get("/publish/v2/app-info", queryParameters: {"appId": initConfig.appId});
    //审核状态
    var appInfo = result.data["appInfo"];
    var releaseState = HuaweiReleaseState.fromValue(appInfo["releaseState"]);
    var updateTime = appInfo["updateTime"];
    var versionNumber = appInfo["versionNumber"];
    var versionCode = appInfo["versionCode"] ?? 0;
    var onShelfVersionNumber = appInfo["onShelfVersionNumber"];
    var onShelfVersionCode = appInfo["onShelfVersionCode"] ?? 0;
    //审核意见
    String auditOpinion = result.data["auditInfo"]["auditOpinion"] ?? "";

    initConfig.auditInfo = AuditInfo(
      releaseVersionCode: onShelfVersionCode,
      versionCode: versionCode,
      auditStatus: releaseState == HuaweiReleaseState.audit || releaseState == HuaweiReleaseState.upgradeAudit
          ? AuditStatus.auditing
          : releaseState == HuaweiReleaseState.upgradeAuditFailed
          ? AuditStatus.auditFailed
          : releaseState == HuaweiReleaseState.released
          ? AuditStatus.auditSuccess
          : AuditStatus.known,
      auditReason: auditOpinion,
    );
    return {
      "releaseState": releaseState,
      "updateTime": updateTime,
      "versionNumber": versionNumber,
      "versionCode": versionCode,
      "onShelfVersionNumber": onShelfVersionNumber,
      "onShelfVersionCode": onShelfVersionCode,
      "auditOpinion": auditOpinion,
    };
  }

  ///更新应用语言信息
  publishLanguageInfo({
    int releaseType = 1,
    String lang = "zh-CN",
    String? appDesc,
    String? newFeatures,
    String? briefInfo,
  }) async {
    if ((appDesc == null || appDesc.isEmpty) &&
        (newFeatures == null || newFeatures.isEmpty) &&
        (briefInfo == null || briefInfo.isEmpty)) {
      return;
    }
    var data = {"lang": lang};
    if (appDesc != null) {
      data["appDesc"] = appDesc;
    }
    if (newFeatures != null) {
      data["newFeatures"] = newFeatures;
    }
    if (briefInfo != null) {
      data["briefInfo"] = briefInfo;
    }

    var result = await _dio.put(
      "/publish/v2/app-language-info",
      queryParameters: {"releaseType": releaseType, "appId": initConfig.appId},
      data: data,
    );
    print(result.data.toString());
  }

  ///获取上传链接
  Future<HuaweiUploadUrlOptions> getUploadOptions({
    required String fileName,
    required int contentLength,
  }) async {
    var result = await _dio.get(
      "/publish/v2/upload-url/for-obs",
      queryParameters: {"appId": initConfig.appId, "fileName": fileName, "contentLength": contentLength},
    );
    var urlInfo = result.data["urlInfo"];
    String url = urlInfo["url"];
    String objectId = urlInfo["objectId"];
    String method = urlInfo["method"];
    Map<String, dynamic> headers = urlInfo["headers"];

    print(result.data.toString());
    //{"ret":{"code":0,"msg":"success"},"urlInfo":{"objectId":"CN/2025120111/1764589669963-d0cab5d5-46c0-417b-a14f-428fe0542c41.apk","url":"https://nsp-appgallery-agcfs-drcn.obs.cn-north-2.myhuaweicloud.cn/CN/2025120111/1764589669963-d0cab5d5-46c0-417b-a14f-428fe0542c41.apk","method":"PUT","headers":{"Authorization":"AWS4-HMAC-SHA256 Credential=HPUAD4DHWFBMSLSTBETK/20251201/cn-north-2/s3/aws4_request, SignedHeaders=content-length;content-type;host;x-amz-content-sha256;x-amz-date, Signature=7ba8cfde7297821bed4aaff571be6550c9f637c26a5dd6e689791163420b106b","x-amz-content-sha256":"UNSIGNED-PAYLOAD","x-amz-date":"20251201T114749Z","Host":"nsp-appgallery-agcfs-drcn.obs.cn-north-2.myhuaweicloud.cn","user-agent":"Apache-HttpClient/4.5.14 (Java/1.8.0_402)","Content-Type":"application/octet-stream"}}}
    return HuaweiUploadUrlOptions(objectId: objectId, url: url, method: method, headers: headers);
  }

  /// 执行文件上传
  Future<String> uploadFile({required String filePath}) async {
    var fileName = File(filePath).path.split("/").last;
    var contentLength = File(filePath).lengthSync();
    var uploadOptions = await getUploadOptions(fileName: fileName, contentLength: contentLength);
    var tempDio = Dio();
    tempDio.interceptors.add(LogInterceptor(requestBody: false, responseBody: true));
    tempDio.options.contentType = "application/octet-stream";
    uploadOptions.headers.forEach((key, value) {
      tempDio.options.headers[key] = value;
    });
    tempDio.options.headers["Content-Length"] = File(filePath).lengthSync();
    var result = await tempDio.put(
      uploadOptions.url,
      data: File(filePath).openRead(),
      onSendProgress: (int sent, int total) {
        print("uploadFile progress: $sent, $total  ${sent / total * 100}%");
      },
    );
    print(result.data.toString());
    return uploadOptions.objectId;
  }

  ///更新文件信息
  publishFileInfo({
    int releaseType = 1,
    required int fileType,
    required String filePath,
    required String objectId,
  }) async {
    var fileName = filePath.split("/").last;
    var result = await _dio.put(
      "/publish/v2/app-file-info",
      queryParameters: {"releaseType": releaseType, "appId": initConfig.appId},
      data: {
        "fileType": fileType,
        "files": [
          {"fileName": fileName, "fileDestUrl": objectId},
        ],
      },
    );
    List<String> pkgVersion = result.data["pkgVersion"];
    print("pkgVersion: $pkgVersion");
  }

  publishApp({int releaseType = 1}) async {
    var result = await _dio.post(
      "/publish/v2/app-submit",
      queryParameters: {"releaseType": releaseType, "appId": initConfig.appId},
    );
    print(result.data.toString());
  }

  @override
  Future<bool> checkAuditStats() async {
    try {
      await queryApkInfo();
      initConfig.isSuccess = true;
      return true;
    } catch (e) {
      print("HuaweiManager checkChannelSuccess error: $e");
      initConfig.isSuccess = false;
      return false;
    }
  }

  @override
  Future<bool> startPublish(UpdateConfig updateConfig) async {
    publishLanguageInfo(newFeatures: updateConfig.updateDesc);
    var filePath = initConfig.uploadApkInfo?.apkPath;
    var appInfo = await queryApkInfo();
    if (appInfo["releaseState"] == HuaweiReleaseState.audit ||
        appInfo["releaseState"] == HuaweiReleaseState.upgradeAudit) {
      SmartDialog.showToast("审核中", displayType: SmartToastType.onlyRefresh);
      return false;
    }

    var uploadApkObjectId = await uploadFile(filePath: filePath!);

    await publishFileInfo(fileType: 5, filePath: filePath, objectId: uploadApkObjectId);
    var publishResult = await publishApp(releaseType: 1);

    return true;
  }
}

class HuaweiInterceptor extends Interceptor {
  _checkAccessToken() async {
    if (HuaweiManager().initConfig.accessToken == "" ||
        HuaweiManager().initConfig.expiresAt <= 0 ||
        DateTime.now().millisecondsSinceEpoch > HuaweiManager().initConfig.expiresAt) {
      await HuaweiManager().getToken();
    }
  }

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _checkAccessToken();
    options.headers["Authorization"] = "Bearer ${HuaweiManager().initConfig.accessToken}";
    options.headers["client_id"] = HuaweiManager().initConfig.clientId;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    var ret = response.data["ret"];
    if (ret == null || ret["code"] == 0) {
      print("华为请求成功");
      handler.next(response);
    } else {
      print("华为请求失败");
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

enum HuaweiReleaseState {
  released(0, "已上架"),
  notReleased(1, "上架审核不通过"),
  offline(2, "已下架（含强制下架）"),
  pending(3, "待上架，预约上架"),
  audit(4, "审核中"),
  upgradeAudit(5, "升级审核中"),
  applyOffline(6, "申请下架"),
  draft(7, "草稿"),
  upgradeAuditFailed(8, "升级审核不通过"),
  offlineAuditFailed(9, "下架审核不通过"),
  developerOffline(10, "应用被开发者下架"),
  revokeRelease(11, "撤销上架"),
  pendingAudit(12, "预审中"),
  pendingAuditFailed(13, "预审不通过");

  final int _value;
  final String _name;

  static HuaweiReleaseState fromValue(int value) {
    return HuaweiReleaseState.values.firstWhere(
      (element) => element._value == value,
      orElse: () => HuaweiReleaseState.released,
    );
  }

  int get releaseState => _value;

  const HuaweiReleaseState(this._value, this._name);
}

class HuaweiUploadInfo {
  HuaweiUploadInfo({required this.fileDestUrl, required this.fileName});
  //文件在文件服务器中的对象ID
  String fileDestUrl;
  String fileName;
}

class HuaweiUploadUrlOptions {
  HuaweiUploadUrlOptions({
    required this.objectId,
    required this.url,
    required this.method,
    required this.headers,
  });
  String objectId;
  String url;
  String method;
  Map<String, dynamic> headers;
}
