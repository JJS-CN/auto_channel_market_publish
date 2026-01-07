import 'dart:convert';
import 'dart:io';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:auto_channel_market_publish/screen/main_screen.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class OppoManager extends BasicChannelManager<OppoConfig> {
  factory OppoManager() => _instance;
  static final OppoManager _instance = OppoManager._internal();
  OppoManager._internal() {
    _dio.options.baseUrl = "https://oop-openapi-cn.heytapmobi.com";
    _dio.options.contentType = "application/x-www-form-urlencoded;charset=UTF-8";
    _dio.interceptors.add(OppoInterceptor());
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  final _dio = Dio();

  ///获取token
  getToken({required String clientId, required String clientSecret}) async {
    var result = await Dio().get(
      "https://oop-openapi-cn.heytapmobi.com/developer/v1/token",
      queryParameters: {"client_id": clientId, "client_secret": clientSecret},
    );
    initConfig.access_token = result.data["data"]["access_token"];
    initConfig.expires_at = result.data["data"]["expire_in"];
    return result.data;
  }

  queryAppInfo() async {
    var result = await _dio.get(
      "/resource/v1/app/info",
      queryParameters: {"pkg_name": initConfig.packageName},
    );
    //审核状态 1审核中 2审核通过 3审核不通过
    int audit_status = int.parse(result.data["audit_status"]);
    //审核状态描述
    String audit_status_name = result.data["audit_status_name"];
    //更新资料审核状态 0:不在审核中 1:审核中
    int update_info_check = result.data["update_info_check"];
    //打回附件链接
    String refuse_file = result.data["refuse_file"];
    int versionCode = int.parse(result.data["version_code"]);
    initConfig.auditInfo = AuditInfo(
      releaseVersionCode: versionCode,
      versionCode: versionCode,
      auditStatus: audit_status == 1
          ? AuditStatus.auditing
          : audit_status == 2 || audit_status == 111
          ? AuditStatus.auditSuccess
          : audit_status == 3 || audit_status == 444
          ? AuditStatus.auditFailed
          : AuditStatus.known,
      auditReason: refuse_file,
    );
    var data = result.data;
    data["audit_status"] = int.parse(data["audit_status"]);
    return data;
  }

  ///上传文件
  ///[requestUrl] 请求url
  ///[type] 文件类型，包括照片、APK 包、其它，值是：photo、apk、resource
  uploadFile({required String filePath, String type = "apk"}) async {
    var upload_options = await _getUploadOptions();
    var upload_url = upload_options["upload_url"];
    var sign = upload_options["sign"];
    var tempDio = Dio();
    tempDio.options.contentType = "multipart/form-data";
    var result = await tempDio.post(
      upload_url,
      data: FormData.fromMap({"type": type, "sign": sign, "file": MultipartFile.fromFileSync(filePath)}),
      onSendProgress: (int sent, int total) {
        print("uploadFile progress: $sent, $total  ${sent / total * 100}%");
      },
    );
    //{errno: 0, data: {url: http://storedl1.nearme.com.cn/apk/tmp_apk/202512/11/432d87b9d1e36deb834e74c7ea72c55e.apk, uri_path: /apk/tmp_apk/202512/11/432d87b9d1e36deb834e74c7ea72c55e.apk, md5: a6b0a941f15f2496f30d71dce88e3b66, file_size: 163388885, file_extension: apk, width: 0, height: 0, id: e53935b8-c847-435c-a948-751fe138c1e2, sign: 1e69883fc54e0c1354a0c8209b20598a}, logid: e53935b8-c847-435c-a948-751fe138c1e2}
    if (result.data["errno"] == 0) {
      var data = result.data["data"];
      data["fileMd5"] = (await compute(md5.convert, File(filePath).readAsBytesSync())).toString();
      return data;
    } else {
      throw Exception("OppoManager uploadFile error: ${result.data["errno"]}");
    }
  }

  _getUploadOptions() async {
    var result = await _dio.get("/resource/v1/upload/get-upload-url");
    var upload_url = result.data["upload_url"];
    var sign = result.data["sign"];
    //{"upload_url":"https://api.open.oppomobile.com/api/utility/upload","sign":"fff63a0864cef2bf2c480bc9dc20e41d"}
    return result.data;
  }

  ///发布应用
  ///[online_type] 1:立即发布 2:定时发布
  publishApp({
    required dynamic oldAppInfo,
    required dynamic apkInfo,
    required int version_code,
    String? update_desc,
    int online_type = 1,
  }) async {
    var newAppInfo = json.decode(json.encode(oldAppInfo));
    newAppInfo["apk_url"] = json.encode([
      {"url": apkInfo["url"], "md5": apkInfo["md5"], "cpu_code": apkInfo["cpu_code"]},
    ]);
    //清理数据为空的情况
    newAppInfo.removeWhere((key, value) => value == null);
    var result = await _dio.post(
      "/resource/v1/app/upd",
      data: {
        "pkg_name": newAppInfo["pkg_name"],
        "version_code": version_code,
        "online_type": online_type,
        "apk_url": newAppInfo["apk_url"],
        "app_name": newAppInfo["app_name"],
        "second_category_id": newAppInfo["second_category_id"],
        "third_category_id": newAppInfo["third_category_id"],
        "summary": newAppInfo["summary"],
        "detail_desc": newAppInfo["detail_desc"],
        "update_desc": update_desc ?? newAppInfo["update_desc"],
        "privacy_source_url": newAppInfo["privacy_source_url"],
        "icon_url": newAppInfo["icon_url"],
        "pic_url": newAppInfo["pic_url"],
        "test_desc": newAppInfo["test_desc"],
        "copyright_url": newAppInfo["copyright_url"],
        "icp_url": newAppInfo["icp_url"],
        "special_url": newAppInfo["special_url"],
        "special_file_url": newAppInfo["special_file_url"],
        "business_username": newAppInfo["business_username"],
        "business_email": newAppInfo["business_email"],
        "business_mobile": newAppInfo["business_mobile"],
      },
    );
    return result.data;
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
    var app_info = await queryAppInfo();
    if (app_info["audit_status"] != 1) {
      SmartDialog.showToast("审核中", displayType: SmartToastType.onlyRefresh);
      return false;
    }

    //当前只适配了apk上传
    var uploadData = await uploadFile(filePath: apkPath!);
    uploadData["cpu_code"] = 0;
    var result = await publishApp(
      oldAppInfo: app_info,
      apkInfo: uploadData,
      version_code: updateConfig.versionCode,
      update_desc: updateConfig.updateDesc,
      online_type: 1,
    );
    return true;
  }
}

class OppoInterceptor extends Interceptor {
  _checkAccessToken() async {
    var initConfig = OppoManager().initConfig;
    if (initConfig.access_token == "" ||
        initConfig.expires_at == 0 ||
        DateTime.now().millisecondsSinceEpoch ~/ 1000 > initConfig.expires_at) {
      await OppoManager().getToken(clientId: initConfig.client_id, clientSecret: initConfig.client_secret);
    }
  }

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _checkAccessToken();
    //当前秒
    var now = DateTime.now().millisecondsSinceEpoch;
    var timestamp = now ~/ 1000;

    var requestData = <String, dynamic>{};
    requestData["timestamp"] = timestamp.toString();
    requestData["access_token"] = OppoManager().initConfig.access_token;
    if (options.data != null) {
      requestData.addAll(options.data);
    }
    requestData.addAll(options.queryParameters);

    //清空value为null的数据
    requestData.removeWhere((key, value) => value == null);

    //按照ASCII升序排序
    var sortedRequestData = requestData.entries.toList();
    sortedRequestData.sort((a, b) => a.key.compareTo(b.key));
    //开始进行签名计算
    String signString = "";
    sortedRequestData.forEach((entry) {
      signString += "${entry.key}=${entry.value}&";
    });
    //去掉最后一个&
    signString = signString.substring(0, signString.length - 1);
    //进行HmacSHA256计算
    var hmacSHA256 = Hmac(sha256, utf8.encode(OppoManager().initConfig.client_secret));
    var sign = hmacSHA256.convert(utf8.encode(signString));
    //字节数组转换为十六进制
    requestData["api_sign"] = sign.toString().toLowerCase();
    if (options.method == "POST") {
      options.data = requestData;
    } else {
      options.queryParameters = requestData;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data["errno"] == 0) {
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
