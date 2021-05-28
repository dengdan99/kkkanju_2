import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:get_ip/get_ip.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/models/category_model.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/models/suggest_model.dart';
import 'package:kkkanju_2/models/version_model.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';
import 'package:kkkanju_2/utils/xml_util.dart';

class HttpUtils {
  static Dio _dio;
  static Dio getDioInstance () {
    if (_dio == null) {
      _dio = Dio();
      (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, post) {
          return true;
        };
      };
      return _dio;
    }
    return _dio;
  }
  static Dio get dio => getDioInstance();
  static String videoPath = "/provide/vod";
  static String versionPath = "/index/version";

  static void errorHandler(err) {
    DioError dioError;
    BotToast.closeAllLoading();
    if (err is DioError) {
      dioError = err;
      print('接口错误: ' + dioError.request.baseUrl + dioError.request.path + dioError.request.queryParameters.toString());
      print(dioError.toString());
      BotToast.showText(text: '网络异常');
    } else {
      BotToast.showText(text: err.toString());
    }
  }

  static Future<String> getLocalIp() async {
//    SpHelper.remove(Constant.key_local_ip);
    String ip = SpHelper.getString(Constant.key_local_ip);
    if (ip.isNotEmpty) return ip;
    try {
      ip = await GetIp.ipAddress;
    } on ProcessException {
      ip = 'Failed to get ipAddress.';
    }
    SpHelper.putString(Constant.key_local_ip, ip);
    return ip;
  }

  static Future<List<CategoryModel>> getCategoryList() async {
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"ac": "list", "at": "xml"};
      Response response = await dio.get(currentSource.httpsApi + videoPath, queryParameters: params);
      String xmlStr = response.data.toString();
      return XmlUtil.parseCategoryList(xmlStr);
    } catch (e, s) {
      errorHandler(e);
    }
    return [];
  }

  static Future<List<VideoModel>> getVideoList({int pageNum = 1, String type, String keyword, String ids, int hour}) async {
    List<VideoModel> videos = [];
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"ac": "videolist", "at": "xml"};

      if (pageNum != null) {
        params["pg"] = pageNum;
      }
      if (type != null && type.isNotEmpty) {
        params["t"] = type;
      }
      if (keyword != null) {
        params["wd"] = keyword;
      }
      if (ids != null) {
        params["ids"] = ids;
      }
      if (hour != null) {
        params["h"] = hour;
      }
      Response response = await dio.get(currentSource.httpsApi + videoPath, queryParameters: params);
      String xmlStr = response.data.toString();
      videos = XmlUtil.parseVideoList(xmlStr);
    } catch (e, s) {
      errorHandler(e);
    }
    return videos;
  }

  static Future<VideoModel> getVideoById(String baseUrl,  String id) async {
    VideoModel video;
    try {
      Map<String, dynamic> params = {"ac": "videolist", "at": "xml"};
      params["ids"] = id;
      Response response = await dio.get(baseUrl, queryParameters: params);
      String xmlStr = response.data.toString();
      video = XmlUtil.parseVideo(xmlStr);
    } catch (e, s) {
      errorHandler(e);
    }
    return video;
  }

  static Future<List<VideoModel>> searchVideo(String keyword) async {
    List<VideoModel> videos = [];
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);

      // 先查找list
      Map<String, dynamic> params = {"ac": "list", "at": "xml"};
      params["wd"] = keyword;
      Response response = await dio.get(currentSource.httpsApi + videoPath, queryParameters: params);
      String xmlStr = response.data.toString();
      videos = XmlUtil.parseVideoList(xmlStr);
      if (videos.isNotEmpty) {
        // 再查找videolist, videolist数据比较全，比如图片
        params["ac"] = "videolist";
        params["at"] = "xml";
        params["ids"] = videos.map((e) => e.id).join(",");
        response = await dio.get(currentSource.httpsApi + videoPath, queryParameters: params);
        xmlStr = response.data.toString();
        videos = XmlUtil.parseVideoList(xmlStr);
      }
    } catch (e, s) {
      errorHandler(e);
    }

    return videos;
  }

  static Future<List<VideoModel>> getLevelVideo(int level) async {
    List<VideoModel> videos = [];
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"ac": "videolist","level": level, "at": "xml"};
      Response response = await dio.get(currentSource.httpsApi + videoPath, queryParameters: params);
      String xmlStr = response.data.toString();
      videos = XmlUtil.parseVideoList(xmlStr);
    } catch (e, s) {
      errorHandler(e);
    }
    return videos;
  }

  static Future<VersionModel> getLastVersion() async {
    VersionModel version;
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"platform": Platform.isIOS ? "ios" : "android"};
      Response response = await dio.get(currentSource.httpsApi + versionPath, queryParameters: params);
      Map json = jsonDecode(response.data.toString());
      if (json['code'] == 1) {
        version = VersionModel.fromJson(json['info']);
      }
    }  catch (e, s) {
      errorHandler(e);
    }
    return version;
  }

  static Future<bool> postSuggest(SuggestModel report) async {
    bool result = false;
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Response response = await dio.post(currentSource.httpsApi + '/index/suggest', data: await report.toJson());
      Map json = jsonDecode(response.data.toString());
      result = json['code'] == 1;
    } catch (e, s) {
      errorHandler(e);
    }
    return result;
  }

  static Future<String> getRrmUrl(String key, String type, String orginUrl) async {
    String url = '';
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Response response = await dio.get(currentSource.httpsApi + '/index/rrm?key=$key&type=$type&url=$orginUrl');
      Map json = jsonDecode(response.data.toString());
      if (json['code'] == 1) {
        url = json['data']['url'];
      } else {
        print(json['msg']);
        BotToast.showText(text: '视频解析错误，请重启app');
      }
    } catch (e, s) {
      BotToast.showText(text: '网络错误，请重试一下');
      print(e.toString());
    }
    return url;
  }

  static Future<String> getSoupSoulText() async {
    String text = '';
    try {
      Response response = await dio.get('https://v1.alapi.cn/api/soul?format=text');
      text = response.data.toString();
    } catch (e, s) {
      print('接口错误: ' + e.request.baseUrl + e.request.path);
    }
    return text;
  }
}