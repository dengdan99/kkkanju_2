import 'package:bot_toast/bot_toast.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/models/version_model.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/utils/rrm_utils.dart';
import 'package:video_player/video_player.dart';

class PlayerDataManager with ChangeNotifier {
  int currentPlaying = 0; // 集数的指针
  int sourceIndex; // 资源的指针
  Anthology currentAnthology; // 选中的集数
  SourceModel sourceModel; // 接口配置
  VideoModel videoModel; // 当前播放视频
  VersionModel versionModel; // 接口版本信息
  FlickManager flickManager;
  List<Anthology> anthologies;
  Function videoListener;
  bool needRefresh;
  bool isChanging = false; // 是否在视频切换中

  double currentspeeds = 1.0;
  final List<double> speeds = [0.5, 1.0, 2.0, 2.5, 3.0,];
  VideoSource get videoSource => videoModel.sources[sourceIndex]; // 当前播放视频资源


  void init(FlickManager _flickManager, VideoModel _videoModel, int _sourceIndex, VersionModel _versionModel, SourceModel _sourceModel,
      { Function listener, String initUrl}) {
    flickManager = _flickManager;
    sourceIndex = _sourceIndex;
    anthologies = _videoModel.sources[sourceIndex].anthologies;
    videoModel = _videoModel;
    versionModel = _versionModel;
    sourceModel = _sourceModel;
    if (listener != null) {
      videoListener = listener;
    }
    if (initUrl != null) {
      setCurrentPlayingByUrl(initUrl);
    }
    notifyListeners();
  }

  void resetSpeed() {
    currentspeeds = speeds[1];
    flickManager.flickVideoManager.videoPlayerController.setPlaybackSpeed(currentspeeds);
    notifyListeners();
  }

  double setSpeedByIndex(int index) {
    currentspeeds = speeds[index];
    flickManager.flickVideoManager.videoPlayerController.setPlaybackSpeed(currentspeeds);
    notifyListeners();
    return currentspeeds;
  }

  void setSourceIndex(int index) {
    sourceIndex = index;
    anthologies = videoModel.sources[index].anthologies;
    notifyListeners();
  }

  void setCurrentPlaying(int index) {
    if (index < 0) index = 0;
    if (index >= anthologies.length) index = anthologies.length - 1;
    currentAnthology = anthologies[index];
    notifyListeners();
  }

  void setCurrentPlayingByUrl(String url) {
    int index = anthologies.indexWhere((element) => element.url == url);
    setCurrentPlaying(index);
  }

  String getCurrentVideoName () {
    return currentAnthology.name;
  }

  String getNextVideo() {
    currentPlaying++;
    setCurrentPlaying(currentPlaying);
    return currentAnthology.url;
  }

  bool hasNextVideo() {
    return currentPlaying != anthologies.length - 1;
  }

  bool hasPreviousVideo() {
    return currentPlaying != 0;
  }

  int getCurrentPlayingByUrl(String url) {
    return anthologies.indexWhere((element) => element.url == url);
  }

  Future<String> playUrlHandler (url) async {
    if (RrmUtils.isRrmVideo(videoModel.sources[sourceIndex])) {
      return await RrmUtils.getM3u8Url(sourceModel, versionModel, url);
    } else {
      return url;
    }
  }

  skipToVideoByUrl(String url) async {
    currentPlaying = getCurrentPlayingByUrl(url);
    if (currentPlaying >= 0) {
      if (isChanging) {
        BotToast.showText(text: '视频切换中， 请稍等');
        return;
      }
      isChanging = true;
      flickManager.handleChangeVideo(
          VideoPlayerController.network(await playUrlHandler(anthologies[currentPlaying].url)),
      );
      if (videoListener != null) {
        flickManager.flickVideoManager.addListener(videoListener);
      }
      setCurrentPlaying(currentPlaying);
      isChanging = false;
    }
  }

  skipToNextVideo([Duration duration]) async {
    if (hasNextVideo()) {
      if (isChanging) {
        BotToast.showText(text: '视频切换中， 请稍等');
        return;
      }
      isChanging = true;
      flickManager.handleChangeVideo(
          VideoPlayerController.network(await playUrlHandler(anthologies[currentPlaying + 1].url)),
          videoChangeDuration: duration);
      if (videoListener != null) {
        flickManager.flickVideoManager.addListener(videoListener);
      }
      currentPlaying++;
      setCurrentPlaying(currentPlaying);
      isChanging = false;
    }
  }

  skipToPreviousVideo() async {
    if (hasPreviousVideo()) {
      if (isChanging) {
        BotToast.showText(text: '视频切换中， 请稍等');
        return;
      }
      isChanging = true;
      currentPlaying--;
      setCurrentPlaying(currentPlaying);
      flickManager.handleChangeVideo(
          VideoPlayerController.network(await playUrlHandler(anthologies[currentPlaying].url)));
      if (videoListener != null) {
        flickManager.flickVideoManager.addListener(videoListener);
      }
      isChanging = false;
    }
  }

  cancelVideoAutoPlayTimer({@required bool playNext}) {
    if (playNext != true) {
      currentPlaying--;
      setCurrentPlaying(currentPlaying);
    }

    flickManager.flickVideoManager
        ?.cancelVideoAutoPlayTimer(playNext: playNext);
  }

  pause() async {
    await flickManager.flickControlManager.pause();
  }
  play() async {
    await flickManager.flickControlManager.play();
  }
}