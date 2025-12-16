import 'package:auto_channel_market_publish/net/vivo_manager.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
