import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class HonorManager {
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
  getToken({required String clientId, required String clientSecret}) async {
    var tempDio = Dio();
    tempDio.options.contentType = "application/x-www-form-urlencoded";
    tempDio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    var result = await tempDio.post(
      "https://iam.developer.honor.com/auth/token",
      data: {"grant_type": "client_credentials", "client_id": clientId, "client_secret": clientSecret},
    );
    _accessToken = result.data["access_token"];
    int expiresIn = result.data["expires_in"];
    DateTime now = DateTime.now();
    _expiresAt = now.add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
    _dio.options.headers["Authorization"] = "Bearer $_accessToken";
    print("accessToken: $_accessToken, expiresAt: $_expiresAt");
    return result.data;
  }

  _checkAccessToken({required String clientId, required String clientSecret}) async {
    if (_accessToken == null || _expiresAt == null || DateTime.now().millisecondsSinceEpoch > _expiresAt!) {
      await getToken(clientId: clientId, clientSecret: clientSecret);
    }
  }

  /// 获取应用ID  这一步可以直接从管理后台查看
  Future<int> getAppId({
    required String clientId,
    required String clientSecret,
    required String pkgName,
  }) async {
    await _checkAccessToken(clientId: clientId, clientSecret: clientSecret);
    var result = await _dio.get("/v1/publish/get-app-id", queryParameters: {"pkgName": pkgName});
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

  getAppInfo({required String clientId, required String clientSecret, required int appId}) async {
    await _checkAccessToken(clientId: clientId, clientSecret: clientSecret);
    var result = await _dio.get("/v1/publish/get-app-detail", queryParameters: {"appId": appId});
    print(result.data.toString());
    //引用基础信息
    var data = result.data["data"];
    var basicInfo = data["basicInfo"];
    String packageName = basicInfo["packageName"];
    int appCategoryId = basicInfo["appCategoryId"];
    var releaseInfo = data["releaseInfo"];
    //线上版本信息
    String releaseVersionName = releaseInfo["versionName"];
    int releaseVersionCode = releaseInfo["versionCode"];
  }

  Future<int> getFileUploadOption({
    required String clientId,
    required String clientSecret,
    required int appId,
    required String filePath,
    required int fileType,
    required String fileName,
    required int fileSize,
    required String fileSha256,
  }) async {
    await _checkAccessToken(clientId: clientId, clientSecret: clientSecret);
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
      queryParameters: {"appId": appId},
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

  uploadFile({
    required String clientId,
    required String clientSecret,
    required int appId,
    required String filePath,
    required int fileType,
    required String fileName,
    required int fileSize,
    required String fileSha256,
  }) async {
    var objectId = await getFileUploadOption(
      clientId: clientId,
      clientSecret: clientSecret,
      appId: appId,
      filePath: filePath,
      fileType: fileType,
      fileName: fileName,
      fileSize: fileSize,
      fileSha256: fileSha256,
    );
    await _checkAccessToken(clientId: clientId, clientSecret: clientSecret);
    var tempDio = Dio();
    tempDio.options.headers["Authorization"] = "Bearer $_accessToken";
    tempDio.interceptors.add(LogInterceptor(requestBody: false, responseBody: true));
    tempDio.options.contentType = "multipart/form-data";

    var result = await tempDio.post(
      "https://appmarket-openapi-drcn.cloud.honor.com/openapi/v1/publish/file-upload",
      queryParameters: {"appId": appId, "objectId": objectId},
      data: FormData.fromMap({"file": MultipartFile.fromFileSync(filePath)}),
      onSendProgress: (int sent, int total) {
        print("uploadFile progress: $sent, $total  ${sent / total * 100}%");
      },
    );
    print(result.data.toString());
    updateFileInfo(clientId: clientId, clientSecret: clientSecret, appId: appId, objectId: objectId);
  }

  updateFileInfo({
    required String clientId,
    required String clientSecret,
    required int appId,
    required int objectId,
  }) async {
    await _checkAccessToken(clientId: clientId, clientSecret: clientSecret);
    var bindingFiles = [];
    bindingFiles.add({"objectId": objectId});
    var result = await _dio.post(
      "/v1/publish/update-file-info",
      queryParameters: {"appId": appId},
      data: {"bindingFileList": bindingFiles},
    );
    print(result.data.toString());
  }

  /// 更新应用语言信息
  /// appName和intro等参数必填,需要从getAppInfo接口获取后缓存,用于后续更新
  updateLanguageInfo({
    required String clientId,
    required String clientSecret,
    required int appId,
    String languageId = "zh-CN",
    required String appName,
    required String intro,
    required String briefIntro,
    required String newFeature,
  }) async {
    await _checkAccessToken(clientId: clientId, clientSecret: clientSecret);
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
      queryParameters: {"appId": appId},
      data: reqBody,
    );
    print(result.data.toString());
  }

  ///提交审核
  ///[releaseType] 1-全网发布 2-指定时间发布3-分阶段发布
  publishApp({
    required String clientId,
    required String clientSecret,
    required int appId,
    int releaseType = 1,
  }) async {
    await _checkAccessToken(clientId: clientId, clientSecret: clientSecret);
    var result = await _dio.post(
      "/v1/publish/submit-audit",
      queryParameters: {"appId": appId},
      data: {"releaseType": releaseType},
    );
    String auditId = result.data["data"];
    print(result.data.toString());
  }

  ///获取审核结果 需要缓存发布接口返回的id, 需要3小时只能查询一次
  getAppAuditResult({
    required String clientId,
    required String clientSecret,
    required int appId,
    required String releaseId,
  }) async {
    await _checkAccessToken(clientId: clientId, clientSecret: clientSecret);
    var result = await _dio.post(
      "/v1/publish/get-audit-result",
      data: {
        "appId": [
          {"appId": appId, "releaseId": releaseId},
        ],
      },
    );
    var data = result.data["data"].first;
    //审核意见
    String auditMessage = data["auditMessage"];
    //审核意见附件，为url，可查看或下载
    List<String> auditAttachment = data["auditAttachment"];
    // 审核结果 0-审核中 1-审核通过 2-审核不通过 3-未提交审核或其他非审核状态
    var auditResult = data["auditResult"];
    var versionName = data["versionName"];
    var versionCode = data["versionCode"];

    print(result.data.toString());
  }

  test() {
    // getAppId(
    //   clientId: "86a171c5027045788fba550dfc4bd0fe",
    //   clientSecret: "NH4gOwuRIq6I4b0UKZMUHNEgRNKTaGFp",
    //   pkgName: "com.fungo.loveshow.tuhao",
    // ).then((appId) {
    //   print("then appId: $appId");
    //   //104469644
    // });

    // getAppInfo(
    //   clientId: "86a171c5027045788fba550dfc4bd0fe",
    //   clientSecret: "NH4gOwuRIq6I4b0UKZMUHNEgRNKTaGFp",
    //   appId: 104469644,
    // );

    // FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['apk']).then((value) async {
    //   if (value != null) {
    //     var file = value.files.first;
    //     var filePath = file.path;
    //     var fileName = file.name;
    //     var fileSize = file.size;
    //     var digest = await sha256.bind(File(filePath!).openRead()).first;
    //     var fileSha256 = digest.toString();
    //     print("fileSha256: $fileSha256");
    //     uploadFile(
    //       clientId: "86a171c5027045788fba550dfc4bd0fe",
    //       clientSecret: "NH4gOwuRIq6I4b0UKZMUHNEgRNKTaGFp",
    //       appId: 104469644,
    //       filePath: filePath!,
    //       fileType: 100,
    //       fileName: fileName,
    //       fileSize: fileSize,
    //       fileSha256: fileSha256,
    //     );
    //   }
    // });

    // publishApp(
    //   clientId: "86a171c5027045788fba550dfc4bd0fe",
    //   clientSecret: "NH4gOwuRIq6I4b0UKZMUHNEgRNKTaGFp",
    //   appId: 104469644,
    //   releaseType: 1,
    // );

    // getAppAuditResult(
    //   clientId: "86a171c5027045788fba550dfc4bd0fe",
    //   clientSecret: "NH4gOwuRIq6I4b0UKZMUHNEgRNKTaGFp",
    //   appId: 104469644,
    //   releaseId: "1998678679697362944",
    // );

    //     updateLanguageInfo(
    //       clientId: "86a171c5027045788fba550dfc4bd0fe",
    //       clientSecret: "NH4gOwuRIq6I4b0UKZMUHNEgRNKTaGFp",
    //       appId: 104469644,
    //       languageId: "zh-CN",
    //       appName: "小爱直播间",
    //       intro: '''小爱直播 — 高颜值直播交友软件

    // 附近高颜值主播才艺花样秀，惊艳视频直播，更多好玩有才艺的直播内容尽在小爱直播！
    // 【超高颜值】
    // 超多高颜值主播。甜心可爱、温婉淑女、风格百变，总有适合你的风格。【超多玩法】唱歌、跳舞、脱口秀、游戏、聊天互动应有尽有。还有映客、秀色、花椒直播、六间房、YY等高人气主播等你来直播交友。
    // 【全民直播】
    // 在线视频K歌、激烈PK排位赛。活动不停，守护你喜欢的主播，休闲娱乐的好去处！
    // 【附近交友】
    // 开启附近交友模式，发现身边有趣的人，邂逅心动的那个TA。
    // 【炫酷礼物】
    // 给心仪的人送奢华游轮、幸福摩天轮，一起徜徉在爱的海洋里！
    // 【AI智能体爱妮兔】
    // 免费使用免排队，提供更高效、智能的服务体验，助你轻松解决各类疑惑！

    // 随时随地聊天交友，随心所欲看直播！就在小爱直播！
    // 快来和人气主播直播互动、视频聊天吧！''',
    //       briefIntro: "热情高颜值美女直播交友软件",
    //       newFeature: "已知问题修复",
    //     );
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
