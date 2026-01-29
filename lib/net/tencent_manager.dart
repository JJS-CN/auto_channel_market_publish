import 'dart:convert';
import 'dart:io';

import 'package:auto_channel_market_publish/model/channel_config.dart';
import 'package:auto_channel_market_publish/model/enums.dart';
import 'package:auto_channel_market_publish/net/basic_channel_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
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

  ///上传文件 [file_type] img, apk, pdf, video, txt
  Future<Map<String, dynamic>> uploadFile({
    required String file_name,
    required TencentUploadFileType file_type,
    required String file_path,
    required String file_md5,
  }) async {
    var upload_options = await _getUploadOptions(
      pkg_name: initConfig.packageName,
      app_id: initConfig.appId,
      file_name: file_name,
      file_type: file_type.name,
    );
    var pre_sign_url = upload_options["pre_sign_url"];
    var tempDio = Dio();
    tempDio.options.contentType = "application/octet-stream";
    print("TencentManager uploadFile 开始上传: $file_path");
    var _ = await tempDio.put(
      pre_sign_url,
      data: File(file_path).readAsBytesSync(),
      onSendProgress: (int sent, int total) {
        var progress = sent / total * 100;
        if (progress % 20 == 0) {
          print("TencentManager uploadFile progress: $progress%");
        }
      },
    );
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
    String icon_file_serial_number = "",
    String snapshots_file_serial_number = "",
    int deploy_type = 1,
  }) async {
    var data = {
      "pkg_name": initConfig.packageName,
      "app_id": initConfig.appId,
      "apk32_file_serial_number": apk32_file_serial_number,
      "apk32_file_md5": apk32_file_md5,
      "feature": feature,
      "deploy_type": deploy_type,
    };
    if (icon_file_serial_number.isNotEmpty) {
      data["icon_file_serial_number"] = icon_file_serial_number;
    }
    if (snapshots_file_serial_number.isNotEmpty) {
      data["snapshots_file_serial_number"] = snapshots_file_serial_number;
    }
    var result = await _dio.post("/update_app", data: data);
    return result.data;
  }

  queryApkUpdateStatus() async {
    var result = await _dio.post(
      "/query_app_update_status",
      data: {"pkg_name": initConfig.packageName, "app_id": initConfig.appId},
    );
    //audit_status 审核状态（1:审核中,2:审核驳回,3:审核通过,8:开发者主动撤销）
    //audit_reason 审核驳回原因
    int audit_status = result.data["audit_status"];
    String audit_reason = result.data["audit_reason"];
    var auditInfo = initConfig.auditInfo ?? AuditInfo();
    auditInfo.auditStatus = audit_status == 1
        ? AuditStatus.auditing
        : audit_status == 2
        ? AuditStatus.auditFailed
        : audit_status == 3
        ? AuditStatus.auditSuccess
        : AuditStatus.known;
    auditInfo.auditReason = audit_reason;
    if (auditInfo.auditStatus == AuditStatus.auditSuccess) {
      if (auditInfo.releaseVersionCode < auditInfo.versionCode) {
        auditInfo.releaseVersionCode = auditInfo.versionCode;
      }
    }

    initConfig.auditInfo = auditInfo;
    return result.data;
  }

  @override
  Future<bool> checkAuditStats() async {
    try {
      await queryApkUpdateStatus();
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
    var _ = await queryApkConfig();
    if (filePath == null) {
      return false;
    }
    var fileName = filePath.split("/").last;
    var fileMd5 = (await compute(md5.convert, File(filePath).readAsBytesSync())).toString();
    var upload_options = await uploadFile(
      file_name: fileName,
      file_type: TencentUploadFileType.apk,
      file_path: filePath,
      file_md5: fileMd5,
    );
    // /icon_file_serial_number
    //应用图标文件上传流水号（1张512*512像素200KB以内的PNG格式直角图标）  备注：不变更则不填
    //snapshots_file_serial_number
    //应用截图文件上传流水号（支持多张，以竖线分隔，请上传4-5张。建议尺寸1080*1920px，最小不低于320*480px；所有图片宽高一致；JPG/PNG格式，单张图片不超过1M）
    var iconFileSerialNumber = "";
    if (updateConfig.iconPath.isNotEmpty) {
      var iconFilePath = updateConfig.iconPath;
      var iconFileName = iconFilePath.split("/").last;
      var iconFileMd5 = (await compute(md5.convert, File(iconFilePath).readAsBytesSync())).toString();
      var iconUploadOptions = await uploadFile(
        file_name: iconFileName,
        file_type: TencentUploadFileType.img,
        file_path: iconFilePath,
        file_md5: iconFileMd5,
      );
      iconFileSerialNumber = iconUploadOptions["serial_number"];
    }

    var snapshotsFileSerialNumber = "";
    if (updateConfig.screenshotPaths.isNotEmpty) {
      for (var screenshotPath in updateConfig.screenshotPaths) {
        var screenshotFileName = screenshotPath.split("/").last;
        var screenshotFileMd5 = (await compute(
          md5.convert,
          File(screenshotPath).readAsBytesSync(),
        )).toString();
        var screenshotUploadOptions = await uploadFile(
          file_name: screenshotFileName,
          file_type: TencentUploadFileType.img,
          file_path: screenshotPath,
          file_md5: screenshotFileMd5,
        );
        var nowSerialNumber = screenshotUploadOptions["serial_number"];
        if (snapshotsFileSerialNumber.isNotEmpty) {
          snapshotsFileSerialNumber += "|";
        }
        snapshotsFileSerialNumber += nowSerialNumber;
      }
    }
    var _ = await publishApp(
      apk32_file_serial_number: upload_options["serial_number"],
      apk32_file_md5: upload_options["file_md5"],
      feature: updateConfig.updateDesc,
      deploy_type: 1,
      icon_file_serial_number: iconFileSerialNumber,
      snapshots_file_serial_number: snapshotsFileSerialNumber,
    );
    var auditInfo = initConfig.auditInfo ?? AuditInfo();
    auditInfo.auditStatus = AuditStatus.auditing;
    auditInfo.versionCode = updateConfig.versionCode;
    initConfig.auditInfo = auditInfo;
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
    if (response.data["ret"] == 0) {
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

enum TencentUploadFileType { img, apk, pdf, video, txt }
