import 'package:bot_toast/bot_toast.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/provider/player_data_manager.dart';
import 'package:provider/provider.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';

class CustomOrientationControls extends StatefulWidget {
  final double iconSize;
  final double fontSize;
  final Widget topRightWidget;

  CustomOrientationControls({this.iconSize = 20, this.fontSize = 12, this.topRightWidget});

  @override
  _CustomOrientationControlsState createState() => _CustomOrientationControlsState();
}


class _CustomOrientationControlsState extends State<CustomOrientationControls> {
  double barHeight = 48.0;
  int duration = 10; // 双击快进 快退的速率

  final int _quickDuration = 100; // 快速滑动的时间间隔
  double _startPosition = 0; // 滑动的起始位置
  double _dragDistance = 0; // 滑动的距离
  int _startTimeStamp = 0; // 滑动的起始时间，毫秒
  int _dragDuration = 0; // 滑动的间隔时间，毫秒
  bool _leftVerticalDrag; // 是否左边滑动
  double _volume = 0; // 解决在设置音量的时候异步问题

  OverlayEntry _tipOverlay;

  VideoPlayerValue _latestValue;
  FlickVideoManager flickVideoManager;
  FlickControlManager controlManager;
  PlayerDataManager _playerDataManager;

  @override
  void didChangeDependencies() {
    flickVideoManager = Provider.of<FlickVideoManager>(context);
    controlManager = Provider.of<FlickControlManager>(context);
    _playerDataManager = context.read<PlayerDataManager>();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

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

  void _onLongPressStartHandler(LongPressStartDetails details) {
    if (flickVideoManager.videoPlayerController.value.isPlaying) {
      final speed = _playerDataManager.setSpeedByIndex(2);
      HapticFeedback.mediumImpact();
      showTooltip(Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.fast_forward,
            color: Colors.white,
            size: 40.0,
          ),
          Text(
            "${speed.toString()} 倍速",
            textAlign: TextAlign.center,
          ),
        ],
      ));
    }
  }

  void _onLongPressEndHandler(LongPressEndDetails details) {
    _playerDataManager.resetSpeed();
    hideTooltip();
  }

  void _playPause() {
    controlManager.togglePlay();
  }

  void _resetDragParam() {
    _startPosition = 0;
    _dragDuration = 0;
    _startTimeStamp = 0;
    _dragDuration = 0;
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (flickVideoManager == null) return;
    _latestValue = flickVideoManager.videoPlayerController.value;

    _startPosition = details.globalPosition.dx;
    _startTimeStamp = details.sourceTimeStamp.inMilliseconds;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_latestValue == null) return;
    if (_startPosition <= 0 || details == null) return;

    _dragDistance = details.globalPosition.dx - _startPosition;
    _dragDuration = details.sourceTimeStamp.inMilliseconds - _startTimeStamp;
    var f = _dragDistance > 0 ? "+" : "-";
    var offset = (_dragDistance / 10).round().abs();
    if (_dragDuration < _quickDuration) offset = 5;

    showTooltip(Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          _dragDistance > 0 ? Icons.fast_forward : Icons.fast_rewind,
          color: Colors.white,
          size: 40.0,
        ),
        Text(
          "$f${offset}s",
          textAlign: TextAlign.center,
        ),
      ],
    ));
  }

  void _onHorizontalDragEnd(DragEndDetails details) async  {
    if (_latestValue == null) return;

    int seekMill = _latestValue.position.inMilliseconds;
    if (_dragDuration <= _quickDuration) {
      // 快速滑动，默认5s
      seekMill += _dragDistance > 0 ? 5000 : -5000;
    } else {
      seekMill += (_dragDistance * 100).toInt();
    }
    // 区间控制
    if (seekMill < 0) {
      seekMill = 0;
    } else if (seekMill > _latestValue.duration.inMilliseconds) {
      seekMill = _latestValue.duration.inMilliseconds;
    }
    controlManager.seekTo(Duration(milliseconds: seekMill));
    // 延时关闭
    await Future<void>.delayed(Duration(milliseconds: 200));
    hideTooltip();
    _resetDragParam();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    // 判断滑动的位置是在左边还是右边
    RenderBox renderObject = context.findRenderObject() as RenderBox;
    _latestValue = flickVideoManager.videoPlayerController.value;

    if (renderObject == null) return;
    var bounds = renderObject.paintBounds;
    Offset localOffset = renderObject.globalToLocal(details.globalPosition);
    _leftVerticalDrag  = localOffset.dx / bounds.width <= 0.5;
    _volume = _latestValue.volume;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (_leftVerticalDrag == null || details == null) return;

    IconData iconData = Icons.volume_up;
    String text = "";

    if (_leftVerticalDrag == false) {
      // 右边区域，控制音量
      _volume -= details.delta.dy / 50;
      if (_volume >= 1) _volume = 1;
      if (_volume <= 0) _volume = 0;
      await controlManager.setVolume(_volume);

      if (_latestValue.volume <= 0) {
        iconData = Icons.volume_mute;
      } else if (_latestValue.volume < 0.5) {
        iconData = Icons.volume_down;
      } else {
        iconData = Icons.volume_up;
      }
      text = (_volume * 100).toStringAsFixed(0);
    } else {
      // 左边区域，控制屏幕亮度
      double brightness = await Screen.brightness;
      brightness -= details.delta.dy / 150;

      if (brightness > 1) {
        brightness = 1;
      } else if (brightness < 0) {
        brightness = 0;
      }
      // 设置亮度
      await Screen.setBrightness(brightness);

      if (brightness >= 0.66) {
        iconData = Icons.brightness_high;
      } else if (brightness < 0.66 && brightness > 0.33) {
        iconData = Icons.brightness_medium;
      } else {
        iconData = Icons.brightness_low;
      }
      text = (brightness * 100).toStringAsFixed(0);
    }

    showTooltip(Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          iconData,
          color: Colors.white,
          size: 25.0,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(text + '%'),
        ),
      ],
    ));
  }

  void _onVerticalDragEnd(DragEndDetails details)  {
    hideTooltip();
    _leftVerticalDrag = null;

    // 快速滑动，可能没清除完成
    Future.delayed(Duration(milliseconds: 1000), () {
      hideTooltip();
    });
  }


  void showTooltip(Widget w) {
    hideTooltip();
    _tipOverlay = OverlayEntry(
        builder: (BuildContext context) {
          return IgnorePointer(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                height: 100.0,
                width: 100.0,
                child: DefaultTextStyle(
                  child: w,
                  style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }
    );
    Overlay.of(context).insert(_tipOverlay);
  }

  void hideTooltip() {
    _tipOverlay?.remove();
    _tipOverlay = null;
  }

  /// 顶部UI构建
  Widget topBuild(BuildContext context) {
    return Positioned.fill(
      child: FlickAutoHideChild(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              color: Colors.black38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.maybePop(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back_ios)
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.maybePop(context);
                      },
                      child: Text(_playerDataManager.videoModel.name + '  ' + _playerDataManager.currentAnthology?.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white),
                      )
                    ),
                  ),
                  widget.topRightWidget
                ],
              ),
            ),
          ],
        )
      ),
    );
  }

  /// 中间主要控制部分
  Widget mainColBuild(BuildContext context) {
    return Positioned.fill(
      child: FlickShowControlsAction(
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
    );
  }

  /// 播放器底部 时间 进度条
  Widget bottomBuild(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: FlickAutoHideChild(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      FlickCurrentPosition(
                        fontSize: widget.fontSize,
                      ),
                      Text(
                        ' / ',
                        style: TextStyle(
                            color: Colors.white, fontSize: widget.fontSize),
                      ),
                      FlickTotalDuration(
                        fontSize: widget.fontSize,
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
                        size: widget.iconSize,
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
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerDataManager>(builder: (ctx, playerDataManager, child) {
      return GestureDetector(
        onLongPressStart: _onLongPressStartHandler,
        onLongPressEnd: _onLongPressEndHandler,
        onDoubleTap: () => _playPause(),
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
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
            mainColBuild(context),
            topBuild(context),
            bottomBuild(context),
          ],
        ),
      );
    });
  }
}
