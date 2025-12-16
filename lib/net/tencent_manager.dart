import 'dart:convert';
import 'dart:io';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:auto_channel_market_publish/screen/main_screen.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

///腾讯应用宝管理类
class TencentManager extends BasicChannelManager<TencentConfig> {
  factory TencentManager() => _instance;
  static final TencentManager _instance = TencentManager._internal();
  TencentManager._internal() {
    _dio.options.baseUrl = "https://p.open.qq.com/open_file/developer_api";
    _dio.options.contentType = "application/x-www-form-urlencoded";
    _dio.interceptors.add(TencentInterceptor());
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
  final _dio = Dio();

  ///查询应用配置
  queryApkConfig() async {
    var result = await _dio.post(
      "/query_app_detail",
      data: {"pkg_name": initConfig.packageName, "app_id": initConfig.appId},
    );
    print("TencentManager queryApkConfig: ${result.data}");
    return result.data;
  }

  ///获取上传配置 每个用户每天最多调用最多100次，即每个用户每天最多上传100个文件
  /// [file_type] img, apk, pdf, video, txt

  _getUploadOptions({
    required String pkg_name,
    required String app_id,
    required String file_name,
    String file_type = "apk",
  }) async {
    var result = await _dio.post(
      "/get_file_upload_info",
      data: {"pkg_name": pkg_name, "app_id": app_id, "file_name": file_name, "file_type": file_type},
    );

    var pre_sign_url = result.data["pre_sign_url"];
    var serial_number = result.data["serial_number"];
    return {"pre_sign_url": pre_sign_url, "serial_number": serial_number};
  }

  ///上传文件
  Future<Map<String, dynamic>> uploadFile({
    required String file_name,
    required String file_type,
    required String file_path,
    required String file_md5,
  }) async {
    var upload_options = await _getUploadOptions(
      pkg_name: initConfig.packageName,
      app_id: initConfig.appId,
      file_name: file_name,
      file_type: file_type,
    );
    print("TencentManager upload_options: $upload_options");
    var pre_sign_url = upload_options["pre_sign_url"];
    var tempDio = Dio();
    tempDio.options.contentType = "application/octet-stream";

    var result = await tempDio.put(
      pre_sign_url,
      data: File(file_path).readAsBytesSync(),
      onSendProgress: (int sent, int total) {
        print("TencentManager uploadFile progress: $sent, $total  ${sent / total * 100}%");
      },
    );
    print("TencentManager uploadFile result: ${result.data}");
    upload_options["file_md5"] = file_md5;
    return upload_options;
  }

  ///发布应用
  ///[feature] 版本特性说明
  ///[deploy_type] 审核通过后的发布类型（1:审核通过后立即发布，2:定时发布）
  publishApp({
    String? apk32_file_serial_number,
    String? apk32_file_md5,
    String? feature,
    int deploy_type = 1,
  }) async {
    var result = await _dio.post(
      "/update_app",
      data: {
        "pkg_name": initConfig.packageName,
        "app_id": initConfig.appId,
        "apk32_file_serial_number": apk32_file_serial_number,
        "apk32_file_md5": apk32_file_md5,
        "feature": feature,
        "deploy_type": deploy_type,
      },
    );
    print("TencentManager publishApp result: ${result.data}");
    return result.data;
  }

  queryApkUpdateStatus() async {
    var result = await _dio.post(
      "/query_app_update_status",
      data: {"pkg_name": initConfig.packageName, "app_id": initConfig.appId},
    );
    print("TencentManager queryApkUpdateStatus result: ${result.data}");
    //audit_status 审核状态（1:审核中,2:审核驳回,3:审核通过,8:开发者主动撤销）
    //audit_reason 审核驳回原因
    return result.data;
  }

  @override
  Future<bool> checkChannelSuccess() async {
    try {
      await queryApkConfig();
      initConfig.isSuccess = true;
      return true;
    } catch (e) {
      initConfig.isSuccess = false;
      return false;
    }
  }

  @override
  Future<bool> startPublish(UpdateConfig updateConfig) async {
    var updateStatus = await queryApkUpdateStatus();
    if (updateStatus["audit_status"] == 1) {
      SmartDialog.showToast("审核中", displayType: SmartToastType.onlyRefresh);
      return false;
    }
    var filePath = initConfig.uploadApkInfo?.apkPath;
    var app_info = await queryApkConfig();
    var apkFIle = File(filePath!);
    var fileName = filePath.split("/").last;
    var fileMd5 = (await compute(md5.convert, File(filePath).readAsBytesSync())).toString();
    var upload_options = await uploadFile(
      file_name: fileName,
      file_type: "apk",
      file_path: filePath,
      file_md5: fileMd5,
    );
    var result = await publishApp(
      apk32_file_serial_number: upload_options["serial_number"],
      apk32_file_md5: upload_options["file_md5"],
      feature: updateConfig.updateDesc,
      deploy_type: 1,
    );
    return true;
  }
}

class TencentInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    //super.onRequest(options, handler);

    //当前秒
    var now = DateTime.now().millisecondsSinceEpoch;
    var timestamp = now ~/ 1000;

    var requestData = <String, dynamic>{};
    requestData["timestamp"] = timestamp.toString();
    requestData["user_id"] = TencentManager().initConfig.userId;
    if (options.data != null) {
      requestData.addAll(options.data);
    }
    //按照ASCII升序排序
    var sortedRequestData = requestData.entries.toList();
    sortedRequestData.sort((a, b) => a.key.compareTo(b.key));
    //开始进行签名计算
    String signString = "";
    sortedRequestData.forEach((entry) {
      if (entry.value != null) {
        signString += "${entry.key}=${entry.value}&";
      }
    });
    //去掉最后一个&
    signString = signString.substring(0, signString.length - 1);
    //进行HmacSHA256计算
    var hmacSHA256 = Hmac(sha256, utf8.encode(TencentManager().initConfig.secretKey));
    var sign = hmacSHA256.convert(utf8.encode(signString));
    requestData["sign"] = sign.toString();
    options.data = requestData;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print("TencentManager response: ${response.data}");
    if (response.data["ret"] == 0) {
      print("TencentManager response success");
      handler.next(response);
    } else {
      print("TencentManager response error: ${response.data["ret"]}");
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
