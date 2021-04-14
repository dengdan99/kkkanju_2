import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/models/version_model.dart';
import 'package:kkkanju_2/pages/home_page.dart';
import 'package:kkkanju_2/pages/my_page.dart';
import 'package:kkkanju_2/pages/search_bar.dart';
import 'package:kkkanju_2/pages/sort_page.dart';
import 'package:kkkanju_2/provider/download_task.dart';
import 'package:kkkanju_2/provider/source.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';
import 'package:kkkanju_2/utils/http_utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    int _localVersion = _currentSource.version;
    bool onclickOk;

    VersionModel version = await HttpUtils.getLastVersion();
    if (version == null) return;
    if (version.enable && version.version > _localVersion) {
      onclickOk = await _uploadDialog(version);
      if (onclickOk) {
        if (version.jumpUrl.isNotEmpty) {
          launch(version.jumpUrl);
        } else {
          launch(version.appUrl);
        }
      }
    }
  }
  Future<bool> _uploadDialog(VersionModel version) {
    List<Widget> buttons = [];
    if (!version.isForce) {
      buttons.add(TextButton(
        child: Text("暂时不升级"),
        onPressed: () => Navigator.of(context).pop(false),
      ));
    }
    buttons.add(TextButton(
      child: Text("立即升级"),
      onPressed: () {
        Navigator.of(context).pop(true);
      },
    ));
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("发现新的版本", style: TextStyle(color: Colors.black),),
          content: Text(version.descript, style: TextStyle(color: Colors.black),),
          actions: buttons,
        );
      },
    );
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
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              text,
              style: TextStyle(
                color: KkColors.placeholder,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
          child: _searchInput('请输入搜索的关键字,片名，演员'),
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