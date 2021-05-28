import 'package:bot_toast/bot_toast.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/provider/player_data_manager.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class CustomOrientationControls extends StatelessWidget {
  const CustomOrientationControls(
      {Key key, this.iconSize = 20, this.fontSize = 12, this.topRightWidget})
      : super(key: key);
  final double iconSize;
  final double fontSize;
  final Widget topRightWidget;
  final double barHeight = 48.0;
  final int duration = 10; // 双击快进 快退的速率

  Widget _buildSpeedBtn(double speed, double currentSpeed, Function callBack) {
    return GestureDetector(
      onTap: callBack ?? () {},
      child: Container(
        padding: EdgeInsets.all(5.0),
        color: KkColors.primaryRed.withAlpha(speed == currentSpeed ? 80 : 0),
        child: Text('x' + speed.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    FlickVideoManager flickVideoManager = Provider.of<FlickVideoManager>(context);
    FlickControlManager controlManager = Provider.of<FlickControlManager>(context);
    PlayerDataManager _playerDataManager = context.read<PlayerDataManager>();

    return GestureDetector(
      onLongPressStart: (details) {
        if (flickVideoManager.videoPlayerController.value.isPlaying) {
          final speed = _playerDataManager.setSpeedByIndex(4);
          HapticFeedback.mediumImpact();
          BotToast.showText(text: speed.toString() + ' 倍速度播放 >>', duration: null);
        }
      },
      onLongPressEnd: (details) {
        _playerDataManager.resetSpeed();
        BotToast.cleanAll();
      },
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _playerDataManager.isChanging
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Text('视频切换中')
                ],
              ),
            )
                : Container(),
          ),
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
                            onTap: () async {
                              BotToast.showText(text: '视频切换中， 请稍等');
                              await _playerDataManager.skipToPreviousVideo();
                            },
                            child: Icon(
                              Icons.skip_previous,
                              color: _playerDataManager.hasPreviousVideo()
                                  ? Colors.white
                                  : Colors.white38,
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
                            onTap: () async {
                              BotToast.showText(text: '视频切换中， 请稍等');
                              await _playerDataManager.skipToNextVideo();
                            },
                            child: Icon(
                              Icons.skip_next,
                              color: _playerDataManager.hasNextVideo()
                                  ? Colors.white
                                  : Colors.white38,
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
                          _playerDataManager.speeds.asMap().entries.map<Widget>((enrty) => _buildSpeedBtn(enrty.value, _playerDataManager.currentspeeds, () {
                            _playerDataManager.setSpeedByIndex(enrty.key);
                          })).toList()
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
                child: Consumer<PlayerDataManager>(builder: (ctx, _playerDataManager, child) {
                  return Container(
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
                          child: Text(_playerDataManager.videoModel.name + '  ' + _playerDataManager.currentAnthology?.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        topRightWidget
                      ],
                    ),
                  );
                },)
            ),
          ),
        ],
      ),
    );

  }
}
