import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {

  List<_ListItemInfo> _items = <_ListItemInfo>[
    new _ListItemInfo(title: '下载记录', icon: Icons.file_download, route: Routers.downloadPage),
    new _ListItemInfo(title: '我的收藏', icon: Icons.star, route: Routers.collectionPage),
    new _ListItemInfo(title: '播放记录', icon: Icons.access_time, route: Routers.playRecordPage),
    new _ListItemInfo(title: '设置', icon: Icons.settings, route: Routers.settingPage),
    new _ListItemInfo(title: '关于', icon: Icons.info),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
//        UserAccountsDrawerHeader(
//          currentAccountPicture: CircleAvatar(
//            backgroundImage: AssetImage('assets/image/placeholder-cover.jpg'),
//          ),
//          accountName: Text(
//            '单身汪',
//            style: TextStyle(
//              color: Colors.white,
//              fontSize: 16,
//              fontWeight: FontWeight.bold,
//            ),
//          ),
//          accountEmail: Text('别看了，臭屌丝。有本事充钱啊！',
//            overflow: TextOverflow.ellipsis,
//            style: TextStyle(
//                fontSize: 14,
//                color: Colors.white
//            ),
//          ),
//          decoration: BoxDecoration(
//            color: Theme.of(context).primaryColor,
//          ),
//        ),
        Expanded(
            child: MediaQuery.removePadding(
              removeTop: true,
              context: context,
              child: ListView.separated(
                separatorBuilder: (BuildContext context, int index) => Divider(height: 1.0, color: KkColors.descWhite),
                itemCount: _items.length,
                itemBuilder: (BuildContext context, int index) {
                  _ListItemInfo item = _items[index];
                  return ListTile(

                    leading: Icon(
                      item.icon,
                      color: KkColors.primaryWhite,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: KkColors.primaryWhite
                      ),
                    ),
                    onTap: () {
                      if (item.route != null) {
                        Application.router.navigateTo(context, item.route);
                      }
                    }
                  );
                },
              ),
            )
        ),
      ],
    );
  }
}

class _ListItemInfo {
  final String title;
  final IconData icon;
  final String route;

  _ListItemInfo({this.title, this.icon, this.route});
}