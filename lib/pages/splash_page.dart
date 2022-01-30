import 'dart:async';
import 'dart:convert';

import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/provider/app_info.dart';
import 'package:kkkanju_2/provider/source.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';
import 'package:kkkanju_2/utils/ColorsUtil.dart';
import 'package:kkkanju_2/utils/analytics_utils.dart';
import 'package:kkkanju_2/utils/db_helper.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  DBHelper _db = DBHelper();
  Timer _timer;
  int _count = 3;
  bool inited = false;
  
  @override
  void initState() {
    AnalyticsUtils.openAppEvent();
    super.initState();
    _initAsync();
  }

  @override
  void dispose() {
    if (_timer != null) _timer.cancel();
    super.dispose();
  }
  
  void _initAsync() async {
    SpHelper.remove(Constant.key_home_page_data_cache);
    // 检查更新
    await SpHelper.getInstance();
    String colorKey = SpHelper.getString(Constant.key_theme_color, defValue: Constant.default_theme_color);
    // 初始化主题颜色
    context.read<AppInfoProvider>().setTheme(colorKey);
    // 获取资源配置
    String sourceJson = await DefaultAssetBundle.of(context).loadString('assets/data/source.json');
    Map json = jsonDecode(sourceJson);
    SourceModel _sm = SourceModel.fromJson(json);
    context.read<SourceProvider>().setCurrentSource(_sm, context);
    // 删除60天以前的播放记录
    _db.deleteAgoRecord(DateTime.now().subtract(Duration(days: 60)).millisecondsSinceEpoch);
    // 检查版本
    await context.read<SourceProvider>().checkVersion(context);
    inited = true;
    // 预加载一些数据
    context.read<SourceProvider>().preloadData(context);
//    倒计时
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_count <= 1) {
          _timer.cancel();
          _timer = null;
          _goMain();
        } else {
          _count -= 1;
        }
      });
    });
  }

  // 跳转主页
  void _goMain() {
    if (inited) {
      Application.router.navigateTo(context, Routers.homePage, clearStack: true, transition: TransitionType.fadeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorsUtil.hexColor(0x121117),
      child: Stack(
        children: [
          Image.asset(
            'assets/image/splash-bg.jpg',
            width: double.infinity,
            fit: BoxFit.cover,
            height: double.infinity,
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: GestureDetector(
              onTap: () {
                _goMain();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '$_count 跳过',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                decoration: BoxDecoration(
                  color: Color(0x66000000),
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  border: Border.all(width: 0.33, color: Colors.grey),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}