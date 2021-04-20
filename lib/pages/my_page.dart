import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {

  RewardedAd myRewarded;
  BannerAd myBannerAd;
  bool _bannerAdLoading = true;
  AdWidget adWidget;

  List<_ListItemInfo> _items = <_ListItemInfo>[
    _ListItemInfo(title: '下载记录', icon: Icons.file_download, route: Routers.downloadPage),
    _ListItemInfo(title: '我的收藏', icon: Icons.star, route: Routers.collectionPage),
    _ListItemInfo(title: '播放记录', icon: Icons.access_time, route: Routers.playRecordPage),
    _ListItemInfo(title: '设置', icon: Icons.settings, route: Routers.settingPage),
    _ListItemInfo(title: '关于我们', icon: Icons.info, route: Routers.aboutUsPage),
  ];

  @override
  void initState() {
    /// 激励广告
    myRewarded = RewardedAd(
      adUnitId: Platform.isIOS ? 'ca-app-pub-6001242100944185/4086433480' : 'ca-app-pub-6001242100944185/7116987162',
//      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: AdRequest(testDevices: ['7ACB3A77CBF29DD30773DE4170923AA6']),
      listener: AdListener(
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('=======激励广告加载错误 error');
          print(error);
        },
        onAdLoaded: (Ad ad) {
          _ListItemInfo adButton = _ListItemInfo(title: '看广告支持一下', icon: Icons.thumb_up);
          setState(() {
            _items.add(adButton);
          });
        },
        onRewardedAdUserEarnedReward: (RewardedAd ad, RewardItem reward) {
          BotToast.showText(text: '感谢您的支持');
          print(reward.type);
          print(reward.amount);
        },
      ),
    );
    myRewarded.load();

    /// 横幅广告
    myBannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: Platform.isIOS ? 'ca-app-pub-6001242100944185/5942133143' : 'ca-app-pub-6001242100944185/3785623530',
//      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: AdRequest(testDevices: ['7ACB3A77CBF29DD30773DE4170923AA6']),
      listener: AdListener(
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('=======横幅广告加载错误 error');
          print(error);
        },
        onAdLoaded: (Ad ad) {
          setState(() {
            _bannerAdLoading = false;
          });
        }
      ),
    );
    myBannerAd.load();
    adWidget = AdWidget(ad: myBannerAd);
    super.initState();
  }

  @override
  void dispose() {
    if (myRewarded != null) {
      myRewarded.dispose();
    }
    if (myBannerAd != null) {
      myBannerAd.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        _bannerAdLoading
        ? Container()
        : Container(
          alignment: Alignment.center,
          child: adWidget,
          width: myBannerAd.size.width.toDouble(),
          height: myBannerAd.size.height.toDouble(),
        ),
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
                      } else {
                        myRewarded.show();
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
