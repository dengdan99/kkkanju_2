import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:kkkanju_2/common/kk_colors.dart';

class AboutPage extends StatefulWidget {

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String aboutUsHtml;

  @override
  void initState() {
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
        child: HtmlWidget(
          aboutUsHtml ?? '暂时没有 cp kkkanju.com',
          textStyle: TextStyle(
            height: 1.8,
            fontSize: 14,
            color: KkColors.black,
          ),
        ),
      ),
    );
  }
}