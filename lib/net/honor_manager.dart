import 'dart:io';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class HonorManager extends BasicChannelManager<HonorConfig> {
  factory HonorManager() => _instance;
  static final HonorManager _instance = HonorManager._internal();
  HonorManager._internal() {
    _dio.options.baseUrl = "https://appmarket-openapi-drcn.cloud.honor.com/openapi";
    _dio.options.contentType = "application/json;charset=UTF-8";
    _dio.interceptors.add(HonorInterceptor());
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  final _dio = Dio();
  String? _accessToken;
  int? _expiresAt;

  ///获取token
  getToken() async {
    var tempDio = Dio();
    tempDio.options.contentType = "application/x-www-form-urlencoded";
    tempDio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    var result = await tempDio.post(
      "https://iam.developer.honor.com/auth/token",
      data: {
        "grant_type": "client_credentials",
        "client_id": initConfig.clientId,
        "client_secret": initConfig.clientSecret,
      },
    );
    _accessToken = result.data["access_token"];
    int expiresIn = result.data["expires_in"];
    DateTime now = DateTime.now();
    _expiresAt = now.add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
    _dio.options.headers["Authorization"] = "Bearer $_accessToken";
    return result.data;
  }

  _checkAccessToken() async {
    if (_accessToken == null || _expiresAt == null || DateTime.now().millisecondsSinceEpoch > _expiresAt!) {
      await getToken();
    }
  }

  /// 获取应用ID  这一步可以直接从管理后台查看
  Future<int> getAppId() async {
    await _checkAccessToken();
    var result = await _dio.get(
      "/v1/publish/get-app-id",
      queryParameters: {"pkgName": initConfig.packageName},
    );
    print(result.data.toString());
    List<dynamic> dataList = result.data["data"];
    if (dataList.isNotEmpty) {
      Map<String, dynamic> data = dataList.first;
      int appId = data["appId"];
      print("appId: $appId");
      return appId;
    }
    return 0;
  }

  Future<Map<String, dynamic>> getAppInfo() async {
    await _checkAccessToken();
    var result = await _dio.get("/v1/publish/get-app-detail", queryParameters: {"appId": initConfig.appId});
    //引用基础信息
    var data = result.data["data"];
    var basicInfo = data["basicInfo"];
    String packageName = basicInfo["packageName"];
    int appCategoryId = basicInfo["appCategoryId"];
    var releaseInfo = data["releaseInfo"];
    //线上版本信息
    String releaseVersionName = releaseInfo["versionName"] ?? "";
    int releaseVersionCode = releaseInfo["versionCode"] ?? 0;

    var auditResultData = await getAppAuditResult();
    //0-审核中 1-审核通过 2-审核不通过 3-其他非审核状态 4-编辑中，未提交审核
    int auditResult = auditResultData["auditResult"];
    int versionCode = auditResultData["versionCode"];
    String auditMessage = auditResultData["auditMessage"] ?? "";
    initConfig.auditInfo = AuditInfo(
      releaseVersionCode: releaseVersionCode,
      versionCode: versionCode,
      auditStatus: auditResult == 0
          ? AuditStatus.auditing
          : auditResult == 1
          ? AuditStatus.auditSuccess
          : auditResult == 2
          ? AuditStatus.auditFailed
          : AuditStatus.known,
      auditReason: auditMessage,
    );
    return data;
  }

  Future<int> getFileUploadOption({required String filePath, required int fileType}) async {
    await _checkAccessToken();
    var fileName = filePath.split("/").last;
    var fileSize = File(filePath).lengthSync();
    var fileSha256 = (await sha256.bind(File(filePath).openRead()).first).toString();

    //最多20个
    var uploadFiles = [];
    //1:应用图标 100:应用apk  参照https://developer.honor.com/cn/doc/guides/101359#h2-1712482613369
    uploadFiles.add({
      "fileName": fileName,
      "fileType": fileType,
      "fileSize": fileSize,
      "fileSha256": fileSha256,
    });
    var result = await _dio.post(
      "/v1/publish/get-file-upload-url",
      queryParameters: {"appId": initConfig.appId},
      data: uploadFiles,
    );
    print(result.data.toString());
    var dataList = result.data["data"];
    var uploadOption = dataList.first;
    var objectId = uploadOption["objectId"];
    var expireTime = uploadOption["expireTime"];
    var uploadUrl = uploadOption["uploadUrl"];
    return objectId;
  }

  uploadFile({required String filePath, required int fileType}) async {
    var objectId = await getFileUploadOption(filePath: filePath, fileType: fileType);
    await _checkAccessToken();
    var tempDio = Dio();
    tempDio.options.headers["Authorization"] = "Bearer $_accessToken";
    tempDio.interceptors.add(LogInterceptor(requestBody: false, responseBody: true));
    tempDio.options.contentType = "multipart/form-data";

    var result = await tempDio.post(
      "https://appmarket-openapi-drcn.cloud.honor.com/openapi/v1/publish/file-upload",
      queryParameters: {"appId": initConfig.appId, "objectId": objectId},
      data: FormData.fromMap({"file": MultipartFile.fromFileSync(filePath)}),
      onSendProgress: (int sent, int total) {
        print("uploadFile progress: $sent, $total  ${sent / total * 100}%");
      },
    );
   await updateFileInfo(objectId: objectId);
  }

  updateFileInfo({required int objectId}) async {
    await _checkAccessToken();
    var bindingFiles = [];
    bindingFiles.add({"objectId": objectId});
    var result = await _dio.post(
      "/v1/publish/update-file-info",
      queryParameters: {"appId": initConfig.appId},
      data: {"bindingFileList": bindingFiles},
    );
    print(result.data.toString());
  }

  /// 更新应用语言信息
  /// appName和intro等参数必填,需要从getAppInfo接口获取后缓存,用于后续更新
  updateLanguageInfo({
    String languageId = "zh-CN",
    required String appName,
    required String intro,
    required String briefIntro,
    required String newFeature,
  }) async {
    await _checkAccessToken();
    var languageInfo = {
      "languageId": languageId,
      "appName": appName,
      "intro": intro,
      "briefIntro": briefIntro,
      "newFeature": newFeature,
    };
    var reqBody = <String, dynamic>{
      "languageInfoList": [languageInfo],
    };
    var result = await _dio.post(
      "/v1/publish/update-language-info",
      queryParameters: {"appId": initConfig.appId},
      data: reqBody,
    );
    print(result.data.toString());
  }

  ///提交审核
  ///[releaseType] 1-全网发布 2-指定时间发布3-分阶段发布
  publishApp({int releaseType = 1}) async {
    await _checkAccessToken();
    var result = await _dio.post(
      "/v1/publish/submit-audit",
      queryParameters: {"appId": initConfig.appId},
      data: {"releaseType": releaseType},
    );
    String auditId = result.data["data"];
    print(result.data.toString());
  }

  ///获取审核结果 需要缓存发布接口返回的id, 需要3小时只能查询一次
  Future<Map<String, dynamic>> getAppAuditResult() async {
    await _checkAccessToken();
    var result = await _dio.get(
      "/v1/publish/get-app-current-release",
      queryParameters: {"appId": initConfig.appId},
    );
    var data = result.data["data"];
    int auditResult = data["auditResult"];
    int versionCode = data["versionCode"];
    return data;
  }

  @override
  Future<bool> checkChannelSuccess() async {
    try {
      await getAppInfo();
      initConfig.isSuccess = true;
      return true;
    } catch (e) {
      print("HonorManager checkChannelSuccess error: $e");
      initConfig.isSuccess = false;
      return false;
    }
  }

  @override
  Future<bool> startPublish(UpdateConfig updateConfig) async {
    var appInfo = await getAppInfo();
    appInfo["languageInfo"].forEach((languageInfo) async {
      String appName = languageInfo["appName"];
      String intro = languageInfo["intro"];
      String briefIntro = languageInfo["briefIntro"];
      String newFeature = languageInfo["newFeature"];
      if (updateConfig.updateDesc.isNotEmpty) {
        newFeature = updateConfig.updateDesc;
      }
      await updateLanguageInfo(
        appName: appName,
        intro: intro,
        briefIntro: briefIntro,
        newFeature: newFeature,
      );
    });
    var filePath = initConfig.uploadApkInfo?.apkPath;
    var uploadApkObjectId = await uploadFile(filePath: filePath!, fileType: 100);
    var publishResult = await publishApp(releaseType: 1);
    return true;
  }
}

class HonorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    var ret = response.data["ret"];
    if (ret == null || ret["code"] == 0) {
      print("荣耀请求成功");
      handler.next(response);
    } else {
      print("荣耀请求失败");
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
