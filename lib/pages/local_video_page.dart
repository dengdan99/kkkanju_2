import 'dart:io';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:kkkanju_2/models/download_model.dart';
import 'package:kkkanju_2/provider/player_data_manager.dart';
import 'package:kkkanju_2/utils/db_helper.dart';
import 'package:kkkanju_2/widgets/player/custom_local_orientation_controls.dart';
import 'package:video_player/video_player.dart';

class LocalVideoPage extends StatefulWidget {
  LocalVideoPage({this.id, this.url, this.name});

  final String id;
  final String url;
  final String name;

  @override
  _LocalVideoPageState createState() => _LocalVideoPageState();
}

class _LocalVideoPageState extends State<LocalVideoPage> {
  DBHelper _db = DBHelper();
  double aspectRatio = 1;
  FlickManager _flickManager;
  int speedIndex = 1;
  int _cachePlayedSecond = -1;
  String url;
  String name;
  int id;

  @override
  void initState() {
    super.initState();
    print('------------');
    print(id);
    setState(() {
      url = widget.url;
      name = widget.name;
      id = int.parse(widget.id);
    });
    printFileContent();
    print('本地地址：' + widget.url);
    _initAsync();
  }

  Future<void> printFileContent() async {
    var file = File(widget.url);
    if (!file.existsSync()) {
      print('文件不存在！！！！！！！！！！！');
    }
//    var content = await file.readAsString();
//    print('==============');
//    print(content);
//    print('==============');
  }

  void _initAsync() async {
    _flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.network(url),
      autoInitialize: true,
      autoPlay: true,
    );
    _flickManager.flickVideoManager.addListener(_videoListener);
    setState(() {});
  }

  void _videoListener() async {
    VideoPlayerController _controller = _flickManager.flickVideoManager.videoPlayerController;
    if (_flickManager.flickVideoManager.isVideoInitialized) {
      if (_controller.value.aspectRatio <= 1) {
        AutoOrientation.portraitAutoMode();
      } else {
        AutoOrientation.landscapeAutoMode();
      }
    }

    // 视频播放同一秒内不执行操作
    if (_controller.value.position.inSeconds == _cachePlayedSecond) return;
    _cachePlayedSecond = _controller.value.position.inSeconds;

    if (_cachePlayedSecond >= _controller.value.duration.inSeconds) {
      nextVideoHandler();
    }
  }

  void onClickSeepdBtn(int index, double speed) {
    setState(() {
      speedIndex = index;
    });
    _flickManager.flickControlManager.setPlaybackSpeed(speed);
  }

  @override
  void dispose() {
    if (_flickManager != null) {
      _flickManager?.dispose();
    }


    // 销毁时，返回竖屏
    AutoOrientation.portraitAutoMode();
    super.dispose();
  }

  Future<void> nextVideoHandler() async {
    DownloadModel downloadModel = await _db.getNextOrPreviousVideoWithId(id, true);
    if (downloadModel != null) {
      await _flickManager.handleChangeVideo(VideoPlayerController.network(downloadModel.url));
      _flickManager.flickVideoManager.addListener(_videoListener);
      setState(() {
        url = downloadModel.url;
        name = downloadModel.name;
        id = downloadModel.id;
      });
      return;
    }
    BotToast.showText(text: '没有下个视频了');
  }
  void previousVideoHandler() async {
    DownloadModel downloadModel = await _db.getNextOrPreviousVideoWithId(id, false);
    if (downloadModel != null) {
      _flickManager.handleChangeVideo(VideoPlayerController.network(downloadModel.url));
      _flickManager.flickVideoManager.addListener(_videoListener);
      setState(() {
        url = downloadModel.url;
        name = downloadModel.name;
        id = downloadModel.id;
      });
      return;
    }
    BotToast.showText(text: '没有上个视频了');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: _flickManager != null ? FlickVideoPlayer(
          flickManager: _flickManager,
          flickVideoWithControls: FlickVideoWithControls(
            videoFit: BoxFit.fitHeight,
            controls: CustomLocalOrientationControls(
              title: name,
              speedIndex: speedIndex,
              onClickSeepdBtn: onClickSeepdBtn,
              nextVideo: nextVideoHandler,
              previousVideo: previousVideoHandler,
            ),
          ),
        ) : Center(
          child: CircularProgressIndicator(),
    ));
  }
}