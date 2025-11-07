import 'dart:convert';

import 'package:auto_channel_market_publish/model/query_apk_result.dart';
import 'package:auto_channel_market_publish/net/xiaomi_helper.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

///@Author jsji
///@Date 2025/10/11
///
///@Description

class XiaomiManager {
  factory XiaomiManager() => _instance;
  static final XiaomiManager _instance = XiaomiManager._internal();

  XiaomiManager._internal() {
    _dio.options.baseUrl = "https://api.developer.xiaomi.com/devupload";
    _dio.options.contentType = "multipart/form-data;";
    _dio.interceptors.add(XiaomiInterceptor());
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  final _dio = Dio();

  Future<QueryApkResult> queryApkConfig({
    required String packageName,
    required String userName,
  }) async {
    var requestData = {"packageName": packageName, "userName": userName};
    Map<String, dynamic> sigData = {
      "password": XiaomiHelper.privateKey,
      "sig": [
        {
          "name": "RequestData",
          "hash": md5.convert(utf8.encode(json.encode(requestData))).toString(),
        },
      ],
    };
    var encrypted = await XiaomiHelper.encodeSIG(sigData);
    var fromData = {"RequestData": json.encode(requestData), "SIG": encrypted};
    var result = await _dio.post(
      "/dev/query",
      data: FormData.fromMap(fromData),
    );
    return QueryApkResult.fromJson(result.data);
  }

  publish() {
    _dio.post("/dev/push");
  }
}
