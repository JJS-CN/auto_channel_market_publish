import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

///@Author jsji
///@Date 2025/10/11
///
///@Description
class XiaomiHelper {

  // 长参数分段加密
  static Future<String> encodeSIG(String publicPem,Map para) async {
    // 设置加密对象
    RSAPublicKey publicKey = RSAKeyParser().parse(publicPem) as RSAPublicKey;
    final encrypter = Encrypter(RSA(publicKey: publicKey));
    // map转成json字符串
    final jsonStr = json.encode(para);
    // 原始json转成字节数组
    List<int> sourceByts = utf8.encode(jsonStr);
    // 数据长度
    int inputLen = sourceByts.length;
    // 加密最大长度
    int maxLen = 117;
    // 存放加密后的字节数组
    List<int> totalByts = [];
    // 分段加密 步长为117
    for (var i = 0; i < inputLen; i += maxLen) {
      // 还剩多少字节长度
      int endLen = inputLen - i;
      List<int> item;
      if (endLen > maxLen) {
        item = sourceByts.sublist(i, i + maxLen);
      } else {
        item = sourceByts.sublist(i, i + endLen);
      }
      // 加密后的对象转换成字节数组再存放到容器
      totalByts.addAll(encrypter.encryptBytes(item).bytes);
    }
    // 加密后的字节数组转换成base64编码并返回
    return totalByts
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('');
  }
}

class XiaomiInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    var result = response.data["result"];
    if (result == 0) {
      print("小米请求成功");
      handler.next(response);
    } else {
      print("小米请求失败");
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
