import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';

class AboutPage extends StatefulWidget {

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String aboutUsHtml;
  SourceModel _currentSource;

  @override
  void initState() {
    Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
    print(sourceJson);
    _currentSource = SourceModel.fromJson(sourceJson);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('关于我们'),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 10, left: 30, right: 30, bottom: 30),
              child: HtmlWidget(
                aboutUsHtml ?? '我们是一群看剧爱好者，app用来自己看，如果觉得不错，可以推荐一下 by kkkanju.com',
                textStyle: TextStyle(
                  height: 1.8,
                  fontSize: 14,
                  color: KkColors.black,
                ),
              ),
            ),
            Text(
              _currentSource != null ? ('本地接口版本：' + _currentSource.version.toString()) : '',
              style: TextStyle(
                color: KkColors.black,
              ),
            ),
//            Image.asset(
//              'assets/image/sp.jpg',
//              fit: BoxFit.fitHeight,
//            ),
          ],
        ),

      ),
    );
  }
}