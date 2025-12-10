import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class HuaweiManager {
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
  getToken({required String clientId, required String clientSecret}) async {
    var data = {"client_id": clientId, "client_secret": clientSecret, "grant_type": "client_credentials"};
    var result = await _dio.post("/oauth2/v1/token", data: data);
    print(result.data.toString());
    //{"access_token":"eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxNDUxNTQyMzM1MTY1ODU2MDY0IiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjQ3NTY2NzIsImlhdCI6MTc2NDU4Mzg3Mn0.xtwd7XoeJGd2mDyOrndLre5o219bh4yB77lKyI0km9I","expires_in":172799}
    var accessToken = result.data["access_token"];
    var expiresIn = result.data["expires_in"];
    var now = DateTime.now();
    var expiresAt = now.add(Duration(seconds: expiresIn));
    print("accessToken: $accessToken, expiresAt: $expiresAt");
    return result.data;
  }

  ///查询应用信息
  queryApkInfo({required String clientId, required String accessToken, required String appId}) async {
    _dio.options.headers["client_id"] = clientId;
    _dio.options.headers["Authorization"] = "Bearer $accessToken";
    var result = await _dio.get("/publish/v2/app-info", queryParameters: {"appId": appId});
    //审核状态
    var appInfo = result.data["appInfo"];
    var releaseState = HuaweiReleaseState.fromValue(appInfo["releaseState"]);
    var updateTime = appInfo["updateTime"];
    var versionNumber = appInfo["versionNumber"];
    var versionCode = appInfo["versionCode"];
    var onShelfVersionNumber = appInfo["onShelfVersionNumber"];
    var onShelfVersionCode = appInfo["onShelfVersionCode"];
    //审核意见
    var auditOpinion = result.data["auditInfo"]["auditOpinion"];
    print("releaseState: $releaseState, auditOpinion: $auditOpinion");
  }

  ///更新应用语言信息
  publishLanguageInfo({
    required String clientId,
    required String accessToken,
    required String appId,
    int releaseType = 1,
    String lang = "zh-CN",
    String? appDesc,
    String? newFeatures,
    String? briefInfo,
  }) async {
    _dio.options.headers["client_id"] = clientId;
    _dio.options.headers["Authorization"] = "Bearer $accessToken";
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
      queryParameters: {"releaseType": releaseType, "appId": appId},
      data: data,
    );
    print(result.data.toString());
  }

  ///获取上传链接
  Future<HuaweiUploadUrlOptions> getUploadOptions({
    required String clientId,
    required String accessToken,
    required String appId,
    required String fileName,
    required int contentLength,
  }) async {
    _dio.options.headers["client_id"] = clientId;
    _dio.options.headers["Authorization"] = "Bearer $accessToken";
    var result = await _dio.get(
      "/publish/v2/upload-url/for-obs",
      queryParameters: {"appId": appId, "fileName": fileName, "contentLength": contentLength},
    );
    var urlInfo = result.data["urlInfo"];
    String url = urlInfo["url"];
    String objectId = urlInfo["objectId"];
    String method = urlInfo["method"];
    Map<String, dynamic> headers = urlInfo["headers"];

    print(result.data.toString());
    //{"ret":{"code":0,"msg":"success"},"urlInfo":{"objectId":"CN/2025120111/1764589669963-d0cab5d5-46c0-417b-a14f-428fe0542c41.apk","url":"https://nsp-appgallery-agcfs-drcn.obs.cn-north-2.myhuaweicloud.cn/CN/2025120111/1764589669963-d0cab5d5-46c0-417b-a14f-428fe0542c41.apk","method":"PUT","headers":{"Authorization":"AWS4-HMAC-SHA256 Credential=HPUAD4DHWFBMSLSTBETK/20251201/cn-north-2/s3/aws4_request, SignedHeaders=content-length;content-type;host;x-amz-content-sha256;x-amz-date, Signature=7ba8cfde7297821bed4aaff571be6550c9f637c26a5dd6e689791163420b106b","x-amz-content-sha256":"UNSIGNED-PAYLOAD","x-amz-date":"20251201T114749Z","Host":"nsp-appgallery-agcfs-drcn.obs.cn-north-2.myhuaweicloud.cn","user-agent":"Apache-HttpClient/4.5.14 (Java/1.8.0_402)","Content-Type":"application/octet-stream"}}}
    return HuaweiUploadUrlOptions(url: url, method: method, headers: headers);
  }

  /// 执行文件上传
  Future<void> uploadFile({
    required String filePath,
    required String url,
    required int contentLength,
    required String clientId,
    required String accessToken,
    required Map<String, dynamic> headers,
  }) async {
    print("uploadFile: $filePath, $url, $headers");
    var tempDio = Dio();
    tempDio.interceptors.add(LogInterceptor(requestBody: false, responseBody: true));
    tempDio.options.contentType = "application/octet-stream";
    headers.forEach((key, value) {
      tempDio.options.headers[key] = value;
    });
    tempDio.options.headers["Content-Length"] = contentLength;
    var result = await tempDio.put(
      url,
      data: File(filePath).openRead(),
      onSendProgress: (int sent, int total) {
        print("uploadFile progress: $sent, $total  ${sent / total * 100}%");
      },
    );
    print(result.data.toString());
  }

  publishAppFileInfo({
    required String clientId,
    required String accessToken,
    required String appId,
    int releaseType = 1,
    required int fileType,
    required String fileName,
    required String fileDestUrl,
  }) async {
    _dio.options.headers["client_id"] = clientId;
    _dio.options.headers["Authorization"] = "Bearer $accessToken";
    var result = await _dio.put(
      "/publish/v2/app-file-info",
      queryParameters: {"releaseType": releaseType, "appId": appId},
      data: {
        "fileType": fileType,
        "files": [
          {"fileName": fileName, "fileDestUrl": fileDestUrl},
        ],
      },
    );
    List<String> pkgVersion = result.data["pkgVersion"];
    print("pkgVersion: $pkgVersion");
    print(result.data.toString());
  }

  publishApp({
    required String clientId,
    required String accessToken,
    required String appId,
    int releaseType = 1,
  }) async {
    _dio.options.headers["client_id"] = clientId;
    _dio.options.headers["Authorization"] = "Bearer $accessToken";
    var result = await _dio.post(
      "/publish/v2/app-submit",
      queryParameters: {"releaseType": releaseType, "appId": appId},
    );
    print(result.data.toString());
  }

  test() {
    // HuaweiManager().getToken(
    //   clientId: "1451542335165856064",
    //   clientSecret: "92CD75915E460511DDE91A56C1864BAF4EFE0C014582491093DFD06771EE70DD",
    // );

    // HuaweiManager().queryApkInfo(
    //   clientId: "1451542335165856064",
    //   accessToken:
    //       "eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxNDUxNTQyMzM1MTY1ODU2MDY0IiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjQ3NTY5NDIsImlhdCI6MTc2NDU4NDE0Mn0.liJVf1OIkZg715sJn0a9s0UkyTA7-1rDwFgISk4Vj7E",
    //   appId: "100016277",
    // );

    // HuaweiManager().publishLanguageInfo(
    //   clientId: "1451542335165856064",
    //   accessToken:
    //       "eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxNDUxNTQyMzM1MTY1ODU2MDY0IiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjQ3NTY5NDIsImlhdCI6MTc2NDU4NDE0Mn0.liJVf1OIkZg715sJn0a9s0UkyTA7-1rDwFgISk4Vj7E",
    //   appId: "100016277",
    //   newFeatures: "已知问题修复",
    // );

    // FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['apk']).then((value) {
    //   if (value != null) {
    //     var file = value.files.first;
    //     var fileName = file.name;
    //     var contentLength = file.size;
    //     HuaweiManager()
    //         .getUploadOptions(
    //           clientId: "1451542335165856064",
    //           accessToken:
    //               "eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxNDUxNTQyMzM1MTY1ODU2MDY0IiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjQ3NTY5NDIsImlhdCI6MTc2NDU4NDE0Mn0.liJVf1OIkZg715sJn0a9s0UkyTA7-1rDwFgISk4Vj7E",
    //           appId: "100016277",
    //           fileName: fileName,
    //           contentLength: contentLength,
    //         )
    //         .then((value) {
    //           var url = value.url;
    //           var method = value.method;
    //           var headers = value.headers;
    //           HuaweiManager().uploadFile(
    //             clientId: "1451542335165856064",
    //             accessToken:
    //                 "eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxNDUxNTQyMzM1MTY1ODU2MDY0IiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjQ3NTY5NDIsImlhdCI6MTc2NDU4NDE0Mn0.liJVf1OIkZg715sJn0a9s0UkyTA7-1rDwFgISk4Vj7E",
    //             filePath: file.path!,
    //             url: url,
    //             contentLength: contentLength,
    //             headers: headers,
    //           );
    //         });
    //   }
    // });

    // HuaweiManager().publishAppFileInfo(
    //   clientId: "1451542335165856064",
    //   accessToken:
    //       "eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxNDUxNTQyMzM1MTY1ODU2MDY0IiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjQ3NTY5NDIsImlhdCI6MTc2NDU4NDE0Mn0.liJVf1OIkZg715sJn0a9s0UkyTA7-1rDwFgISk4Vj7E",
    //   appId: "100016277",
    //   fileType: 5,
    //   fileDestUrl: "CN/2025120112/1764591598792-b567295a-22b8-44ae-b55c-b9928ee67fde.apk",
    //   fileName: "1764591598792-b567295a-22b8-44ae-b55c-b9928ee67fde.apk",
    // );

    HuaweiManager().publishApp(
      clientId: "1451542335165856064",
      accessToken:
          "eyJraWQiOiJJbnBuMjNUaUJZbnJCb1RiYzJwSDhMaHdTMFdwUUFLViIsInR5cCI6IkpXVCIsImFsZyI6IkhTMjU2In0.eyJzdWIiOiIxNDUxNTQyMzM1MTY1ODU2MDY0IiwiZG4iOjEsImNsaWVudF90eXBlIjoxLCJleHAiOjE3NjQ3NTY5NDIsImlhdCI6MTc2NDU4NDE0Mn0.liJVf1OIkZg715sJn0a9s0UkyTA7-1rDwFgISk4Vj7E",
      appId: "100016277",
    );
  }
}

class HuaweiInterceptor extends Interceptor {
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
  HuaweiUploadUrlOptions({required this.url, required this.method, required this.headers});
  String url;
  String method;
  Map<String, dynamic> headers;
}
