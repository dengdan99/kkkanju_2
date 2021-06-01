import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/provider/player_data_manager.dart';
import 'package:provider/provider.dart';

import 'data_manager.dart';

class CustomEmbedControls extends StatelessWidget {
  const CustomEmbedControls(
        {Key key, this.iconSize = 28, this.fontSize = 12, this.topRightWidget})
      : super(key: key);
  final double iconSize;
  final double fontSize;
  final double barHeight = 48.0;
  final Widget topRightWidget;

  @override
  Widget build(BuildContext context) {
    FlickVideoManager flickVideoManager = Provider.of<FlickVideoManager>(context);

    return (flickVideoManager.errorInVideo || !flickVideoManager.isVideoInitialized)
        ? Container()
        : Stack(
      children: <Widget>[
        Positioned.fill(
          child: FlickShowControlsAction(
            child: FlickSeekVideoAction(
              child:  Center(
                child: FlickAutoHideChild(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: flickVideoManager.isBuffering ? CircularProgressIndicator() : FlickPlayToggle(size: 50),
                      ),
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
                      FlickFullScreenToggle(
                        size: iconSize,
                      ),
                    ],
                  ),
                  FlickVideoProgressBar(
                    flickProgressBarSettings: FlickProgressBarSettings(
                      height: 5,
                      handleRadius: 5,
                      curveRadius: 50,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white54,
                      playedColor: KkColors.lightRed,
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
                      child: Text(_playerDataManager.currentAnthology?.name,
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
    );
  }
}