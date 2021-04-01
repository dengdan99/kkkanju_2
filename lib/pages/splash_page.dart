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
  
  @override
  void initState() {
    super.initState();
    _initAsync();
  }
  
  void _initAsync() async {
    await SpHelper.getInstance();
    String colorKey = SpHelper.getString(Constant.key_theme_color, defValue: Constant.default_theme_color);
    // 初始化主题颜色
    context.read<AppInfoProvider>().setTheme(colorKey);
    Map<String, dynamic> source = SpHelper.getObject(Constant.key_current_source);
    if (source == null) {
      String sourceJson = await DefaultAssetBundle.of(context).loadString('assets/data/source.json');
      List<dynamic> jsonList = json.decode(sourceJson);
      List<SourceModel> list = jsonList.map((e) => SourceModel.fromJson(e)).toList();
      await _db.insertBatchSource(list);
      list = await _db.getSourceList();
      context.read<SourceProvider>().setCurrentSource(list[2], context);
    } else {
      context.read<SourceProvider>().setCurrentSource(SourceModel.fromJson(source), context);
    }
//    删除30天以前的播放记录
    _db.deleteAgoRecord(DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch);

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
    Application.router.navigateTo(context, Routers.homePage, clearStack: true, transition: TransitionType.fadeIn);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Image.asset(
            'assets/image/splash-bg.jpg',
            width: double.infinity,
            fit: BoxFit.fitWidth,
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
                  '$_count 跳转',
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