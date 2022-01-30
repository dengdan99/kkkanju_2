import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kkkanju_2/models/suggest_model.dart';
import 'package:kkkanju_2/utils/http_utils.dart';

class SuggestPage extends StatefulWidget {
  @override
  _SuggestPage createState() => _SuggestPage();
}

class _SuggestPage extends State<SuggestPage> {
  //全局 Key 用来获取 Form 表单组件
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RewardedAd myRewarded;
  bool myRewardedError = false;
  int myRewardedScore = 0;
  String videoName;
  String reason;

  @override
  void initState() {
    _initAd();
    super.initState();
  }

  @override
  void dispose() {
    if (myRewarded != null) {
      myRewarded.dispose();
    }
    super.dispose();
  }

  Future<void> suggestHandler() async {
    if (formKey.currentState.validate()) {
      bool showAd = await _showDialog();
      if (showAd && !myRewardedError) {
        await myRewarded.show();
      }
      await postForm();
    }
  }

  Future<void> postForm() async {
    formKey.currentState.save();
    SuggestModel suggestModel = SuggestModel(
      type: 1,
      platform: 'android',
      videoName: videoName,
      name: '求片: ' + videoName,
      desc: reason,
      awardedMarks: myRewardedScore
    );
    bool res = await HttpUtils.postSuggest(suggestModel);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('感谢您的推荐，我们会尽力的', style: TextStyle(color: Colors.black87),),
          actions: <Widget>[
            TextButton(
              child: Text('返回'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    Navigator.pop(context);
  }

  _initAd () {
    /// 激励广告
    List<String> testDevices = [
      '7ACB3A77CBF29DD30773DE4170923AA6',
      'D802DB35DCF70C5951D389B6B6935C4B'
    ];
    myRewarded = RewardedAd(
      adUnitId: Platform.isIOS
          ? 'ca-app-pub-6001242100944185/4086433480'
          : 'ca-app-pub-6001242100944185/7116987162',
//      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: AdRequest(testDevices: testDevices),
      listener: AdListener(
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          myRewardedError = true;
          ad.dispose();
          print('=======激励广告加载错误 error');
          print(error);
        },
        onAdLoaded: (Ad ad) {
        },
        onRewardedAdUserEarnedReward: (RewardedAd ad, RewardItem reward) {
          myRewardedScore = reward.amount;
          print(reward.type);
          print(reward.amount);
          postForm();
        },
        onAdClosed: (Ad ad) async {
          await myRewarded.dispose();
          _initAd();
        }
      ),
    );
    myRewarded.load();
  }

  Future<bool> _showDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('看完广告, 会大大加快求片的处理速度，找片不易 :)', style: TextStyle(color: Colors.black87),),
          actions: <Widget>[
            TextButton(
              child: Text('不看广告'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('提交，看会儿广告'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('求片'),
      ),
      body: Column(
        children: [
          Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: '推荐片名',
                    hintText: '请输入影片的名称',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.videocam),
                  ),
                  validator: (value) {
                    return value.trim().length > 0 ? null : "片名不能为空";
                  },
                  onSaved: (value) {
                    videoName = value;
                  },
                ),
                TextFormField(
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: '推荐理由',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.description),
                  ),
                  onSaved: (value) {
                    reason = value;
                  },
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            "提交求片",
                            style: TextStyle(fontSize: 18),
                          ),
                          textColor: Colors.white,
                          color: Theme.of(context).primaryColor,
                          onPressed: suggestHandler,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}