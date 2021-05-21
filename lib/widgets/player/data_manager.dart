import 'dart:async';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:video_player/video_player.dart';

class DataManager {
  DataManager({@required this.flickManager, @required this.anthologies});

  int currentPlaying = 0;
  Anthology currentAnthology;
  final FlickManager flickManager;
  final List<Anthology> anthologies;

  Timer videoChangeTimer;

  Anthology setCurrentPlaying(int index) {
    if (index < 0) index = 0;
    if (index >= anthologies.length) index = anthologies.length - 1;
    currentAnthology = anthologies[index];
    return currentAnthology;
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

  skipToVideoByUrl(String url) {
    currentPlaying = getCurrentPlayingByUrl(url);
    if (currentPlaying >= 0) {
      flickManager.handleChangeVideo(
          VideoPlayerController.network(anthologies[currentPlaying].url));
    }
  }

  skipToNextVideo([Duration duration]) {
    if (hasNextVideo()) {
      flickManager.handleChangeVideo(
          VideoPlayerController.network(anthologies[currentPlaying + 1].url),
          videoChangeDuration: duration);

      currentPlaying++;
      setCurrentPlaying(currentPlaying);
    }
  }

  skipToPreviousVideo() {
    if (hasPreviousVideo()) {
      currentPlaying--;
      setCurrentPlaying(currentPlaying);
      flickManager.handleChangeVideo(
          VideoPlayerController.network(anthologies[currentPlaying].url));
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
}