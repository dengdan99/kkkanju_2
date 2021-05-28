import 'package:flutter/material.dart';
import 'package:flutter_dlna/flutter_dlna.dart';

/// 投屏功能
class MirrorLinkProvider with ChangeNotifier {
  FlutterDlna _flutterDlna;

  bool _running = false; // 是否投屏中
  bool _playing = false; // 是否播放中
  String _videoName;
  List<DlnaDevice> _devices = [];
  DlnaDevice _currentDevice;

  get flutterDlna => _flutterDlna;
  get running => _running;
  get playing => _playing;
  get videoName => _videoName;
  get devices => _devices;
  get currentDevice => _currentDevice;

  Future<FlutterDlna> init () async {
    if (_flutterDlna == null) {
      _flutterDlna = FlutterDlna();
      await _flutterDlna.init();
      _flutterDlna.setSearchCallback((devicesRes) {
        print('dlna 搜索：');
        print(devicesRes);
        if (devicesRes != null && devicesRes.length > 0) {
          devicesRes.forEach((e) {
            if (_devices.indexWhere((element) => element.id == e["id"]) < 0) {
              _devices.add(DlnaDevice(name: e["name"], id: e["id"]));
            }
          });
          notifyListeners();
        }
      });
      return _flutterDlna;
    }
    return _flutterDlna;
  }

  void setPlaying(bool playing) {
    _playing = playing;
    notifyListeners();
  }

  void startSearchTvData() async {
    if (_flutterDlna == null) {
      await init();
    }
    _flutterDlna.search();
  }

  connect(String url,String name, DlnaDevice dlnaDevice) async {
    if (_flutterDlna == null) return;
    _currentDevice = dlnaDevice;
    await _flutterDlna.setDevice(dlnaDevice.id);
    await _flutterDlna.setVideoUrlAndName(url, name);
    await _flutterDlna.startAndPlay();
    _videoName = name;
    _running = true;
    setPlaying(true);
  }

  disconnect() async {
    _currentDevice = null;
    _running = false;
    setPlaying(false);
    notifyListeners();
    await _flutterDlna.stop();
  }
}

class DlnaDevice {
  String id;
  String name;

  DlnaDevice({this.name, this.id});
}
