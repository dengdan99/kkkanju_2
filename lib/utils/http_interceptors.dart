import 'package:dio/dio.dart';
import 'package:kkkanju_2/utils/log_util.dart';

class HttpInterceptors extends InterceptorsWrapper {
  int milliseconds;

  @override
  Future onRequest(RequestOptions options) {
    milliseconds = DateTime.now().millisecondsSinceEpoch;
//    print("请求baseUrl：${options.baseUrl}");
//    print("请求url：${options.path}");
//    print('请求头: ${options.headers.toString()}');
//    if (options.data != null) {
//      print('请求参数: ${options.data.toString()}');
//    }
    // TODO: implement onRequest
    return super.onRequest(options);
  }

  @override
  Future onResponse(Response response) {
    LogUtil.debug("请求地址：${response.request.path} -- ${DateTime.now().millisecondsSinceEpoch - milliseconds} ms -- ${response.request.queryParameters}");
    // TODO: implement onResponse
    return super.onResponse(response);
  }

  @override
  Future onError(DioError err) {
    LogUtil.error('请求异常: ${err.toString()}');
    LogUtil.error('请求异常信息: ${err.response?.toString() ?? ""}');
    // TODO: implement onError
    return super.onError(err);
  }
}