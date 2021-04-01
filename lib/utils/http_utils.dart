import 'package:bot_toast/bot_toast.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/models/category_model.dart';
import 'package:kkkanju_2/models/source_model.dart';
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

  static Future<List<CategoryModel>> getCategoryList() async {
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"ac": "list", "at": "xml"};
      Response response = await dio.get(currentSource.httpsApi, queryParameters: params);
      String xmlStr = response.data.toString();
      return XmlUtil.parseCategoryList(xmlStr);
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.error ?? e.toString());
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
      Response response = await dio.get(currentSource.httpsApi, queryParameters: params);
      String xmlStr = response.data.toString();
      videos = XmlUtil.parseVideoList(xmlStr);
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.error ?? e.toString());
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
      print(s);
      BotToast.showText(text: e.error ?? e.toString());
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
      Response response = await dio.get(currentSource.httpsApi, queryParameters: params);
      String xmlStr = response.data.toString();
      videos = XmlUtil.parseVideoList(xmlStr);
      if (videos.isNotEmpty) {
        // 再查找videolist, videolist数据比较全，比如图片
        params["ac"] = "videolist";
        params["at"] = "xml";
        params["ids"] = videos.map((e) => e.id).join(",");
        response = await dio.get(currentSource.httpsApi, queryParameters: params);
        xmlStr = response.data.toString();
        videos = XmlUtil.parseVideoList(xmlStr);
      }
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.error ?? e.toString());
    }

    return videos;
  }

  static Future<List<VideoModel>> getLevelVideo(int level) async {
    List<VideoModel> videos = [];
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"ac": "videolist","level": level, "at": "xml"};
      Response response = await dio.get(currentSource.httpsApi, queryParameters: params);
      String xmlStr = response.data.toString();
      videos = XmlUtil.parseVideoList(xmlStr);
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.error ?? e.toString());
    }
    return videos;
  }
}
