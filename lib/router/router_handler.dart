import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:kkkanju_2/pages/collection_page.dart';
import 'package:kkkanju_2/pages/download_page.dart';
import 'package:kkkanju_2/pages/local_video_page.dart';
import 'package:kkkanju_2/pages/main_page.dart';
import 'package:kkkanju_2/pages/play_record_page.dart';
import 'package:kkkanju_2/pages/setting_page.dart';
import 'package:kkkanju_2/pages/source_manage_page.dart';
import 'package:kkkanju_2/pages/video_detail_page.dart';
import 'package:kkkanju_2/utils/fluro_convert_util.dart';
import 'package:kkkanju_2/views/demo.dart';
import 'package:kkkanju_2/views/not_found.dart';

Handler homeHandler = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return MainPage();
  }
);

Handler videoDetailHandler = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    String videoId = params['id']?.first;
    String api = params['api']?.first;
    if (api != null) {
      api = FluroConvertUtils.fluroCnParamsDecode(api);
    }
    return VideoDetailPage(videoId: videoId, api: api);
  }
);

Handler sourceManageHandle = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return SourceManagePage();
  }
);

Handler demoHandler = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return DemoPage();
  }
);

Handler settingHandle = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return SettingPage();
  }
);

Handler downloadHandle = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return DownloadPage();
  }
);

Handler localVideoHandle = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    String url = params['url']?.first;
    String name = params['name']?.first;
    return LocalVideoPage(url: FluroConvertUtils.fluroCnParamsDecode(url), name: FluroConvertUtils.fluroCnParamsDecode(name),);
  }
);

Handler collectionHandle = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return CollectionPage();
  }
);

Handler playRecordHandle = Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return PlayRecordPage();
  }
);

Handler notFoundHandler =  Handler(
  handlerFunc: (BuildContext context, Map<String, List<String>> params) {
    return NotFoundPage();
  }
);
