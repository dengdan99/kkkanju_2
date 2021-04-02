import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/record_model.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/provider/download_task.dart';
import 'package:kkkanju_2/utils/db_helper.dart';
import 'package:kkkanju_2/utils/http_utils.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';
import 'package:kkkanju_2/widgets/video_controls.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

class VideoDetailPage extends StatefulWidget {
  final String api;
  final String videoId;

  VideoDetailPage({this.api, @required this.videoId});

  @override
  _VideoDetailPageState createState () => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  Future<VideoModel> _futureFetch;
  VideoPlayerController _controller;
  ChewieController _chewieController;
  DBHelper _db = DBHelper();

  String _url;
  SourceModel _currentSource;
  VideoModel _videoModel;
  RecordModel _recordModel;
  bool _isSingleVideo = false; // 是否单视频,没有选集
  int _cachePlayedSecond = -1; // 临时的播放秒数

  @override
  void initState() {
    super.initState();
    _futureFetch = _getVideoInfo();
  }

  Future<VideoModel> _getVideoInfo() async {
    String baseUrl = widget.api;
    if (baseUrl == null) {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      _currentSource = SourceModel.fromJson(sourceJson);
      baseUrl = _currentSource.httpsApi;
    }
    VideoModel video = await HttpUtils.getVideoById(baseUrl + HttpUtils.videoPath, widget.videoId);
    _videoModel = video;
    if (video != null) {
      if (video.anthologies.isNotEmpty) {
        RecordModel recordModel = await _db.getRecordByVid(baseUrl, widget.videoId);
        setState(() {
          _recordModel = recordModel;
          // 单视频，只有一个anthology，并且name为null
          if (video.anthologies.length == 1 && video.anthologies.first.name == null) {
            _isSingleVideo = true;
          }
        });

        String url;
        String name;
        int position;
        if (_recordModel == null) {
          url = video.anthologies.first.url;
          name = video.anthologies.first.name == null ? video.name : (video.name + '  ' + video.anthologies.first.name);
        } else {
          Anthology anthology = video.anthologies.firstWhere((e) => e.name == _recordModel.anthologyName, orElse: () => null);
          if (anthology == null) {
            url = anthology.url;
            name = anthology.name == null ? video.name : (video.name + '  ' + anthology.name);
          } else {
            url = video.anthologies.first.url;
            name = video.anthologies.first.name == null ? video.name : (video.name + '  ' + video.anthologies.first.name);
          }
          position = recordModel.playedTime;
        }
        _startPlay(url, name, playPosition: position);
      }
    }
    return video;
  }

  void _startPlay(String url, String name, { int playPosition }) async {
    // 切换视频，重置_cachePlayedSecond
    _cachePlayedSecond = -1;

    setState(() {
      _url = url;
    });
    if (_controller == null) {
      _initController(url, name, playPosition: playPosition);
      return;
    }
    final oldController = _controller;
    // 在下一帧处理完后
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      oldController.removeListener(_videoListener);
      // 注销旧的controller
      await oldController.dispose();
      _chewieController?.dispose();
      _initController(url, name);
    });
    setState(() {
      _controller = null;
    });
  }

  void _initController(String url, String name, { int playPosition }) async {
//        url = "http://static.chinameifei.com/group2/M00/2E/C3/dyqVIl_kIm6ABKpkAABSNGvBuCk29.m3u8";
        url = "http://iqiyi.cdn22-okzyw.net/20210317/10325_133d4c2a/1200k/hls/index.m3u8";
    //    url = "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4";
    print("播放地址：" + url);
    // 设置资源
    _controller = VideoPlayerController.network(url, videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true
    ));
    try {
      // 为了自适应视频比例
      await _controller.initialize();
    } catch(err) {
      print(err);
      return;
    }

    Duration position;
    if (playPosition != null) {
      position = Duration(milliseconds: playPosition);
    }

    _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        startAt: position,
        allowedScreenSleep: false,
        playbackSpeeds: [0.5, 1, 1.25, 1.5, 2],
        customControls: VideoControls(
          title: name,
          actions: _buildDownload(url, name),
        )
    );

    _controller.addListener(_videoListener);
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _chewieController?.dispose();
    _db.close();

    super.dispose();
  }

  void _videoListener() async {
    if (_videoModel == null || _controller == null || !_controller.value.isPlaying) return;
    // 视频播放同一秒内不执行操作
    if (_controller.value.position.inSeconds == _cachePlayedSecond) return;
    _cachePlayedSecond = _controller.value.position.inSeconds;

    String anthologyName;
    if (!_isSingleVideo) {
      Anthology anthology = _videoModel.anthologies.firstWhere((e) => e.url == _url, orElse: () => null);
      if (anthology != null) {
        anthologyName = anthology.name;
      }
    }

    // 播放记录
    if (_recordModel == null) {
      _recordModel = RecordModel(
          api: _currentSource.httpApi,
          vid: widget.videoId,
          tid: _videoModel.tid,
          type: _videoModel.type,
          name: _videoModel.name,
          pic: _videoModel.pic,
          collected: 0,
          anthologyName: anthologyName,
          progress: 0,
          playedTime: 0
      );
      _recordModel.id = await _db.insertRecord(_recordModel);
    } else {
      _db.updateRecord(_recordModel.id,
          anthologyName: anthologyName,
          playedTime: _controller.value.position.inMilliseconds,
          progress: _controller.value.position.inMilliseconds / _controller.value.duration.inMilliseconds
      );
    }

    // 多个选集
    if (_videoModel.anthologies != null && _videoModel.anthologies.length > 1) {
      // 播放到最后，切换下一个视频
      if (_cachePlayedSecond >= _controller.value.duration.inSeconds) {
        int index = _videoModel.anthologies.indexWhere((e) => e.url == _url);
        if (index > -1 && index != (_videoModel.anthologies.length - 1)) {
          Anthology next = _videoModel.anthologies[index + 1];
          _startPlay(next.url, _videoModel.name + '  ' + next.name);
        }
      }
    }
  }

  Widget _buildText(String str) {
    return Container(
      child: Center(
        child: Text(str, style: TextStyle(
            color: Colors.redAccent,
            fontSize: 16
        )),
      ),
    );
  }

  Widget _buildScrollContent(VideoModel video) {
    List arr = [];
    if (video.year != null && video.year.isNotEmpty) {
      arr.add(video.year);
    }
    if (video.area != null && video.area.isNotEmpty) {
      arr.add(video.area);
    }
    if (video.lang != null && video.lang.isNotEmpty) {
      arr.add(video.lang);
    }
    if (video.type != null && video.type.isNotEmpty) {
      arr.add(video.type);
    }
    List<Widget> children = [];

    // 添加视频标题和说明
    children.addAll([
      Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.name,
                    style: TextStyle(color: KkColors.primaryWhite, fontSize: 22) ,
                  ),
                  SizedBox(height: 8,),
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: KkColors.primaryWhite,
                        size: 12,
                      ),
                      SizedBox(width: 8,),
                      Text(
                          arr.join('/'),
                          style: TextStyle(color: KkColors.primaryWhite, fontSize: 12, height: 1)
                      ),
                    ],
                  )

                ],
              ),
            ),
            Container(
              width: 48,
              margin: EdgeInsets.only(right: 6),
              child: MaterialButton(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Icon(
                      _recordModel?.collected == 1 ? Icons.star : Icons.star_border,
                      color: _recordModel?.collected == 1 ? KkColors.primaryRed : KkColors.primaryWhite,
                      size: 24,
                    ),
                    Text(
                      _recordModel?.collected == 1 ? '已收藏' : '收藏',
                      style: TextStyle(
                        color: _recordModel?.collected == 1 ? KkColors.primaryRed : KkColors.primaryWhite,
                        fontSize: 12,
                      ),
                    )
                  ],
                ),
                onPressed: () async {
                  if (_currentSource == null || _videoModel == null) return;
                  if (_recordModel == null) {
                    BotToast.showText(text: '请等待视频加载完成');
                    return;
                  }
                  int newCollected = _recordModel.collected == 1 ? 0 : 1;
                  await _db.updateRecord(_recordModel.id, collected: newCollected);
                  setState(() {
                    _recordModel.collected = newCollected;
                  });
                  BotToast.showText(text: newCollected == 1 ? '收藏成功' : '取消收藏成功');
                },
              ),

            )
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 8, bottom: 4),
        child: Divider(
          color: Colors.grey.withOpacity(0.5),
        ),
      )
    ]);
    // 添加选集
    if (!_isSingleVideo) {
      children.addAll([
        Padding(
          padding: EdgeInsets.only(left: 6),
          child: Text('选集', style: TextStyle(
            color: KkColors.primaryWhite,
            fontSize: 18,
            height: 1
          ),),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: video.anthologies.map((e) {
              return SizedBox(
                height: 36,
                child: RaisedButton(
                  elevation: 0,
                  highlightElevation: 4,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  color: _url == e.url ? KkColors.primaryRed : null,
                  child: Text(e.name, style: TextStyle(
                      color: _url == e.url ? Colors.white : null,
                      fontSize: 14,
                      fontWeight: FontWeight.normal
                  ),),
                  onPressed: () async {
                    if (_url == e.url) return;
                    _startPlay(e.url, video.name + '  ' + e.name);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Divider(
          color: Colors.grey.withOpacity(0.5),
        ),
      ]);
    }

    // 添加简介
    children.addAll([
      Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text('简介', style: TextStyle(
            color: KkColors.primaryWhite,
            fontSize: 18,
            height: 1
        )),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('地区', video.area),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('年份', video.year),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('分类', video.type),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('导演', video.director),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('演员', video.actor),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('发布', video.last),
      ),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: HtmlWidget(
            video.des ?? '',
            textStyle: TextStyle(
                height: 1.8,
                fontSize: 14,
                color: KkColors.descWhite,
            ),
          )
      ),
    ]);
    // 添加底部占位
    children.add(SizedBox(
      height: 20,
    ));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabelText(String label, String text) {
    return RichText(
        text: TextSpan(
            children: [
              TextSpan(text: label, style: TextStyle(
                  fontSize: 14,
                  color: KkColors.descWhite,
                  letterSpacing: 4
              )),
              TextSpan(text: '：  ', style: TextStyle(
                fontSize: 14,
                color: KkColors.descWhite,
              )),
              TextSpan(text: text ?? '', style: TextStyle(
                  fontSize: 14,
                  color: KkColors.descWhite,
                  height: 1.6
              )),
            ]
        )
    );
  }

  GestureDetector _buildDownload(String url, String name) {
    return GestureDetector(
      onTap: () async {
        await context.read<DownloadTaskProvider>().createDownload(
          context: context,
          video: _videoModel,
          url: url,
          name: name
        );
        BotToast.showText(text: '开始下载 【$name】');
      },
      child: Container(
        height: 48,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0
        ),
        child: Icon(
          Icons.file_download,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16/9,
            child: Container(
              padding: EdgeInsets.only(top: MediaQueryData.fromWindow(window).padding.top),
              color: KkColors.black,
              child: _chewieController != null && _controller != null
                ? Chewie(controller: _chewieController)
                  : Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: BackButton(color: Colors.white,),
                  ),
                  Center(
                    child: CircularProgressIndicator(),
                  )
                ],
              )
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: KkColors.mainBlackBg,
              child: FutureBuilder(
                future: _futureFetch,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return _buildText('网络请求出错了');
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      try {
                        return _buildScrollContent(snapshot.data);
                      } catch(e) {
                        return Center(
                          child: Text('数据解析错误'),
                        );
                      }
                    } else {
                      return _buildText('没有找到视频');
                    }
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          )
        ],
      )
    );
  }
}