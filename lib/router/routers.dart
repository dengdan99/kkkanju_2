import 'package:fluro/fluro.dart';
import 'package:kkkanju_2/router/router_handler.dart';

class Routers {
  static String root = "/";
  static String demoPage = "/demo";
  static String homePage = "/home";
  static String detailPage = "/detail";
  static String sourceManagePage = '/sourceManage';
  static String settingPage = '/setting';
  static String downloadPage = '/download';
  static String localVideoPage = '/localVideo';
  static String collectionPage = '/collection';
  static String playRecordPage = '/playRecord';

  static void configureRoutes(FluroRouter router) {
    router.define(homePage, handler: homeHandler);
    router.define(detailPage, handler: videoDetailHandler);
    router.define(sourceManagePage, handler: sourceManageHandle);
    router.define(demoPage, handler: demoHandler);
    router.define(settingPage, handler: settingHandle);
    router.define(downloadPage, handler: downloadHandle);
    router.define(localVideoPage, handler: localVideoHandle);
    router.define(collectionPage, handler: collectionHandle);
    router.define(playRecordPage, handler: playRecordHandle);
    router.notFoundHandler = notFoundHandler;
  }
}