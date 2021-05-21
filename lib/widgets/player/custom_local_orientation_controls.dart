import 'package:bot_toast/bot_toast.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/provider/player_data_manager.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class CustomLocalOrientationControls extends StatelessWidget {
  const CustomLocalOrientationControls(
      {Key key,
        this.iconSize = 20,
        this.fontSize = 12,
        this.title,
        this.nextVideo,
        this.previousVideo,
        this.speedIndex,
        this.onClickSeepdBtn,
        this.duration = 10, // 双击快进 快退的速率
      })
      : super(key: key);
  final double iconSize;
  final double fontSize;
  final String title;
  final Function nextVideo;
  final Function previousVideo;
  final Function onClickSeepdBtn;
  final int speedIndex;
  final double barHeight = 48.0;
  final int duration;
  static List<double> speeds = [0.5, 1.0, 1.5, 2.0, 2.5, 3, 4];

  Widget _buildSpeedBtn(double speed) {
    var _speedIndex = speeds.indexWhere((element) => element == speed);
    return GestureDetector(
      onTap: () {
        onClickSeepdBtn(_speedIndex, speed) ?? () {};
      },
      child: Container(
        padding: EdgeInsets.all(5.0),
        color: KkColors.primaryRed.withAlpha(speed == speeds[speedIndex] ? 80 : 0),
        child: Text('x' + speed.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    FlickVideoManager flickVideoManager = Provider.of<FlickVideoManager>(context);
    FlickControlManager controlManager = Provider.of<FlickControlManager>(context);

    return GestureDetector(
      onLongPressStart: (details) {
        if (flickVideoManager.videoPlayerController.value.isPlaying) {
          final speed = speeds[4];
          flickVideoManager.videoPlayerController.setPlaybackSpeed(speed);
          BotToast.showText(text: speed.toString() + ' 倍速度播放 >>', duration: null);
        }
      },
      onLongPressEnd: (details) {
        flickVideoManager.videoPlayerController.setPlaybackSpeed(speeds[1]);
        BotToast.cleanAll();
      },
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: FlickAutoHideChild(
              child: Container(color: Colors.black38),
            ),
          ),
          Positioned.fill(
            child: FlickShowControlsAction(
              child: FlickSeekVideoAction(
                duration: Duration(seconds: duration),
                seekForward: () {
                  BotToast.showText(text: '快进 ' + duration.toString() + '秒');
                  controlManager.seekForward(Duration(seconds: duration));
                },
                seekBackward: () {
                  BotToast.showText(text: '退后 ' + duration.toString() + '秒');
                  controlManager.seekBackward(Duration(seconds: duration));
                },
                forwardSeekIcon: Icon(Icons.fast_forward, size: 26),
                backwardSeekIcon: Icon(Icons.fast_rewind, size: 26),
                child: Center(
                  child: flickVideoManager.nextVideoAutoPlayTimer != null
                      ? FlickAutoPlayCircularProgress(
                    colors: FlickAutoPlayTimerProgressColors(
                      backgroundColor: Colors.white30,
                      color: Colors.red,
                    ),
                  )
                      : FlickAutoHideChild(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              if (this.previousVideo != null) this.previousVideo();
                            },
                            child: Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: flickVideoManager.isBuffering ? CircularProgressIndicator() : FlickPlayToggle(size: 50),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              if (this.nextVideo != null) this.nextVideo();
                            },
                            child: Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: FlickAutoHideChild(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            FlickCurrentPosition(
                              fontSize: fontSize,
                            ),
                            Text(
                              ' / ',
                              style: TextStyle(
                                  color: Colors.white, fontSize: fontSize),
                            ),
                            FlickTotalDuration(
                              fontSize: fontSize,
                            ),
                          ],
                        ),
                        Expanded(
                          child: Container(),
                        ),
                      ] +
                          speeds.asMap().entries.map<Widget>((enrty) => _buildSpeedBtn(enrty.value)).toList()
                          + [
                            SizedBox(width: 30,),
                            FlickFullScreenToggle(
                              size: iconSize,
                              padding: EdgeInsets.all(5.0),
                            ),
                          ],
                    ),
                    FlickVideoProgressBar(
                      flickProgressBarSettings: FlickProgressBarSettings(
                        height: 5,
                        handleRadius: 5,
                        curveRadius: 50,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white38,
                        playedColor: KkColors.primaryRedgrep,
                        handleColor: KkColors.primaryRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: barHeight,
            child: FlickAutoHideChild(
              child: Container(
                color: Colors.black38,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BackButton(
                      color: Colors.white,
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
