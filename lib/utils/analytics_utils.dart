import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:kkkanju_2/models/video_model.dart';

class AnalyticsUtils {
  static FirebaseAnalytics _analytics;
  static FirebaseAnalytics getAnalyticsInstance () {
    if (_analytics == null) {
      _analytics = FirebaseAnalytics();
    }
    return _analytics;
  }

  /// 搜索事件统计
  static searchEvent({String keywords}) async {
    if (keywords.isNotEmpty) {
      Map<String, dynamic> params = {
        'keywords': keywords
      };
      await sendAnalyticsEvent(eventName: 'kk_main_search', params: params);
    }
  }

  /// 打开app统计
  static openAppEvent() async {
    await sendAnalyticsEvent(eventName: 'kk_open_app');
  }

  /// 打开app统计
  static adLoadFail(String id) async {
    await sendAnalyticsEvent(eventName: 'kk_ad_load_fail', params: {id: id});
  }

  /// 打开播放页面统计
  static enterVideoPage(VideoModel videoModel) async {
    Map<String, dynamic> params = {
      'video_id': videoModel.id,
      'video_name': videoModel.name,
    };
    await sendAnalyticsEvent(eventName: 'kk_enter_video_page', params: params);
  }

  /// 播放事件统计
  static playVideo(VideoModel videoModel, {String sourceName, String anthologyName}) async {
    Map<String, dynamic> params = {
      'video_id': videoModel.id,
      'video_name': videoModel.name,
      'source_name': sourceName,
      'anthology_name': anthologyName,
    };
    await sendAnalyticsEvent(eventName: 'kk_play_video', params: params);
  }

  static sendAnalyticsEvent({String eventName, Map<String, dynamic> params}) async {
    if (_analytics == null) getAnalyticsInstance();
    await _analytics.logEvent(name: eventName, parameters: params);
  }
}
