import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lblelinkplugin/lblelinkplugin.dart';
import 'package:lblelinkplugin/tv_list.dart';

/// 投屏功能
class MirrorLinkProvider with ChangeNotifier {
  bool _running = false;
  bool _playing = false;
  bool _isInited = false;
  String _videoName;
  List<TvData> _tvData = [];
  TvData _selected;

  bool get running => _running;
  bool get playing => _playing;
  String get videoName => _videoName;
  List<TvData> get tvData => _tvData;
  TvData get selected => _selected;

  Future<void> init() async {
    if (_isInited) return;
    if (Platform.isIOS) {
      await Lblelinkplugin.initLBSdk("17574", "49db6247a699b1fba3f692eb965f0720");
    } else {
      await Lblelinkplugin.initLBSdk("17572", "fafd882c3969b5e6ec4fc643b7bce285");
    }
    Lblelinkplugin.lbCallBack = MirrorCallBack();
    Lblelinkplugin.eventChannelDistribution();
    _isInited = true;
    notifyListeners();
  }

  Future<String> getVersion() async {
    return await Lblelinkplugin.platformVersion;
  }

  void setPlaying(bool playing) {
    _playing = playing;
    notifyListeners();
  }

  void startSearchTvData() async {
    Lblelinkplugin.getServicesList((data) {
//      print(" 获取投屏可链接设备 ");
//      print(data);
//      // mock
//      data = [TvData()
//      ..name = '测试电视机测试电视机测试电视机测试电视机'
//      ..ipAddress = '127.0.0.1'
//      ..uId = 'xxxxsdfwqxxx',
//      TvData()
//      ..name = '测试客厅电视'
//      ..ipAddress = '127.0.0.1'
//      ..uId = 'yyyysdaf'];
//      // mock end
      _tvData = data;
      notifyListeners();
    });
  }

  void connect(String url,String name, TvData data) {
    Lblelinkplugin.disConnect();
    Lblelinkplugin.connectToService(
      data.ipAddress,
      fConnectListener: () {
        _selected = data;
        _running = true;
        _playing = true;
        print('链接成功： ${data.ipAddress}, ${data.name}');
        Lblelinkplugin.play(url);
        _videoName = name;
        notifyListeners();
      },
      fDisConnectListener: () {
        _selected = null;
        _running = false;
        print('断开链接： ${data.ipAddress}, ${data.name}');
        notifyListeners();
      }
    );
  }

  void pause() {
    Lblelinkplugin.pause();
    _playing = false;
    notifyListeners();
  }

  void resumePlay() {
    Lblelinkplugin.resumePlay();
    _playing = true;
    notifyListeners();
  }

  void disconnect() {
    Lblelinkplugin.stop();
    Lblelinkplugin.disConnect();
    _videoName = null;
    _running = false;
    _playing = false;
    _selected = null;
    notifyListeners();
  }
}

/// 投屏控制
class MirrorCallBack with LbCallBack {

  @override
  void completeCallBack() {
    print('投屏播放完了');
  }

  @override
  void errorCallBack(String errorDes) {
    print('投屏播放错误');
    print(errorDes);
  }

  @override
  void stopCallBack() {
    print('投屏停止播放');
  }

  @override
  void startCallBack() {
    print('投屏开始播放');
  }

  @override
  void pauseCallBack() {
    print('投屏暂停播放');
  }
}