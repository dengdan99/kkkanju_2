import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/pages/home_page.dart';
import 'package:kkkanju_2/pages/my_page.dart';
import 'package:kkkanju_2/pages/search_bar.dart';
import 'package:kkkanju_2/pages/sort_page.dart';
import 'package:kkkanju_2/provider/download_task.dart';
import 'package:kkkanju_2/provider/source.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';
import 'package:kkkanju_2/utils/ColorsUtil.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  SourceModel _currentSource;
  SourceProvider _sourceProvider;

  int _currentInde = 0;
  List _pageList = [
    HomePage(),
    SortPage(),
    MyPage(),
  ];

  @override
  void initState() {
    _sourceProvider = context.read<SourceProvider>();
    _currentSource = _sourceProvider.currentSource;
    super.initState();
    // 初始化下载器
    context.read<DownloadTaskProvider>().initialize(context);
  }

  Widget _searchInput(String text) {
    return Container(
      height: 35,
      padding: EdgeInsets.only(left: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(35),
        ),
        color: KkColors.greyInBalck,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.search,
            color: KkColors.placeholder,
          ),
          Text(
            text,
            style: TextStyle(
              color: KkColors.placeholder,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KkColors.mainBlackBg,
      appBar: AppBar(
        leading: Builder(builder: (BuildContext ctx) {
          return IconButton(
            icon: Container(
              width: 50,
              decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('assets/image/logo.png'),
                  )
              ),
            ),
          );
        }),
        centerTitle: true,
        title: TextButton(
          child: _searchInput('请输入需要搜索的关键字'),
          onPressed: () {
            showSearch(context: context, delegate: SearchBarDelegate(hintText: '搜索【${_currentSource.name}】的资源'));
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download_outlined),
            onPressed: () {
              Application.router.navigateTo(context, Routers.downloadPage);
            },
          ),
          IconButton(
            icon: Icon(Icons.av_timer),
            onPressed: () {
              Application.router.navigateTo(context, Routers.playRecordPage);
            },
          ),
        ],
      ),
      body: _pageList[_currentInde],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: KkColors.black,
        unselectedItemColor: KkColors.primaryWhite,
        currentIndex: _currentInde,
        onTap: (index) {
          setState(() {
            _currentInde = index;
          });
        },
        iconSize: 24.0,
        type: BottomNavigationBarType.fixed,
        fixedColor: KkColors.primaryRed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: '找片'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}