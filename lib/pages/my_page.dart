import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/provider/source.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';
import 'package:kkkanju_2/utils/analytics_utils.dart';
import 'package:provider/provider.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with AutomaticKeepAliveClientMixin {

  RewardedAd myRewarded;
  BannerAd myBannerAd;
  bool _bannerAdLoading = true;
  bool checkLoading = false;
  AdWidget adWidget;
  List<_ListItemInfo> _items = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    setState(() {
      _items = [
        _ListItemInfo(title: '下载记录', icon: Icons.file_download, route: Routers.downloadPage),
        _ListItemInfo(title: '我的收藏', icon: Icons.star, route: Routers.collectionPage),
        _ListItemInfo(title: '播放记录', icon: Icons.access_time, route: Routers.playRecordPage),
        _ListItemInfo(title: '求片', icon: Icons.question_answer, route: Routers.suggestPage),
        _ListItemInfo(title: '设置', icon: Icons.settings, route: Routers.settingPage),
        _ListItemInfo(title: '检查更新', icon: Icons.update, handler: (item) => _checkUpdate(item)),
        _ListItemInfo(title: '关于我们', icon: Icons.info, route: Routers.aboutUsPage),
      ];
    });
    _initAd();
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

  /// 广告初始化
  _initAd () {
    /// 激励广告
    List<String> testDevices = ['7ACB3A77CBF29DD30773DE4170923AA6', 'D802DB35DCF70C5951D389B6B6935C4B'];
    String adId1 = Platform.isIOS ? 'ca-app-pub-6001242100944185/4086433480' : 'ca-app-pub-6001242100944185/7116987162';
    myRewarded = RewardedAd(
      adUnitId: adId1,
//      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
//      request: AdRequest(testDevices: testDevices),
      listener: AdListener(
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          AnalyticsUtils.adLoadFail(adId1);
          ad.dispose();
          print('=======激励广告加载错误 error');
          print(error);
        },
        onAdLoaded: (Ad ad) {
          _ListItemInfo adButton = _ListItemInfo(title: '看广告支持一下', icon: Icons.thumb_up, handler: (item) => myRewarded.show());
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
    String adId2 = Platform.isIOS ? 'ca-app-pub-6001242100944185/5942133143' : 'ca-app-pub-6001242100944185/3785623530';
    myBannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: adId2,
//      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: AdRequest(testDevices: testDevices),
      listener: AdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            AnalyticsUtils.adLoadFail(adId2);
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
  }

  void _checkUpdate(_ListItemInfo item) async {
    checkLoading = true;
    bool res = await context.read<SourceProvider>().checkVersion(context);
    checkLoading = false;
    if (res) {
      BotToast.showText(text: '已经是最新版本了');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
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
                        Application.router.navigateTo(context, item.route, transition: TransitionType.cupertino);
                      } else {
                        if (item.handler != null) {
                          item.handler(item);
                        }
                      }
                    },
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
  final Function handler;

  _ListItemInfo({this.title, this.icon, this.route, this.handler});
}
