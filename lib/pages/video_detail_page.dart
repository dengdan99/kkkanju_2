import 'dart:async';
import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/record_model.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/models/suggest_model.dart';
import 'package:kkkanju_2/models/version_model.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/provider/download_task.dart';
import 'package:kkkanju_2/provider/mirror_link.dart';
import 'package:kkkanju_2/provider/player_data_manager.dart';
import 'package:kkkanju_2/provider/source.dart';
import 'package:kkkanju_2/utils/analytics_utils.dart';
import 'package:kkkanju_2/utils/db_helper.dart';
import 'package:kkkanju_2/utils/http_utils.dart';
import 'package:kkkanju_2/utils/log_util.dart';
import 'package:kkkanju_2/utils/rrm_utils.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';
import 'package:kkkanju_2/widgets/player/custom_embed_controls.dart';
import 'package:kkkanju_2/widgets/player/custom_orientation_controls.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

import '../widgets/mirror_dialog.dart';

class VideoDetailPage extends StatefulWidget {
  final String api;
  final String videoId;

  VideoDetailPage({this.api, @required this.videoId});

  @override
  _VideoDetailPageState createState () => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> with SingleTickerProviderStateMixin {
  Future<VideoModel> _futureFetch;
  FlickManager _flickManager;
  DBHelper _db = DBHelper();

  SourceModel _currentSource;
  VideoModel _videoModel;
  RecordModel _recordModel;
  VideoSource currentVideoSource;
  double _aspectRatio = 16 / 9;
  bool _isSingleVideo = false; // 是否单视频,没有选集
  int _cachePlayedSecond = -1; // 临时的播放秒数
  int _sourceIndex = 0;
  bool _bannerAdLoading = true; // 广告显示
  BannerAd myBannerAd;
  bool isReported = false; // 是否报错过
  List<String> urls = [];
  Duration _startPlayPosition; // 调转到 起始播放起始
  PlayerDataManager _playerDataManager;
  TabController _sourceTabController;

  @override
  void initState() {
    super.initState();
    _playerDataManager = context.read<PlayerDataManager>();
//    _initAd();
    _futureFetch = _getVideoInfo();
  }

  _initAd() async {
    myBannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId:  'ca-app-pub-6001242100944185/6628544763',
      request: AdRequest(testDevices: ['7ACB3A77CBF29DD30773DE4170923AA6']),
      listener: AdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            ad.dispose();
            print('=======横幅广告加载错误 error');
            print(error);
          },
          onAdLoaded: (Ad ad) {
            setState(() {
              _bannerAdLoading = false;
            });
          }
      ),
    );
    myBannerAd.load();
  }


  Future<VideoModel> _getVideoInfo() async {
    String baseUrl = widget.api;
    Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
    VersionModel versionModel = await context.read<SourceProvider>().getVersion();
    _currentSource = SourceModel.fromJson(sourceJson);
    if (baseUrl == null) {
      baseUrl = _currentSource.httpsApi + HttpUtils.videoPath;
    } else {
      baseUrl = widget.api + HttpUtils.videoPath;
    }
    VideoModel video = await HttpUtils.getVideoById(baseUrl, widget.videoId);
    AnalyticsUtils.enterVideoPage(video);
    _videoModel = video;
    if (video != null) {
      if (video.sources.isNotEmpty) {
        RecordModel recordModel = await _db.getRecordByVid(_currentSource.httpsApi, widget.videoId);
        setState(() {
          _recordModel = recordModel;
          if (recordModel != null) {
//            print('recordModel.currentSourceIndex' + recordModel.currentSourceIndex.toString());
            _sourceIndex = recordModel.currentSourceIndex;
          }
        });

        String url;
        String name;
        int position = 0;
        if (_sourceIndex > video.sources.length) {
          _sourceIndex = 0;
        }
        VideoSource videoSource = video.sources[_sourceIndex];
        currentVideoSource = videoSource;
        if (_recordModel == null) {
          url = videoSource.anthologies.first.url;
          name = videoSource.anthologies.first.name == null ? video.name : (video.name + '  ' + videoSource.anthologies.first.name);
        } else {
          Anthology anthology = videoSource.anthologies.firstWhere((e) => e.name == _recordModel.anthologyName, orElse: () => null);
          if (anthology != null) {
            url = anthology.url;
            name = anthology.name == null ? video.name : (video.name + '  ' + anthology.name);
          } else {
            url = videoSource.anthologies.first.url;
            name = videoSource.anthologies.first.name == null ? video.name : (video.name + '  ' + videoSource.anthologies.first.name);
          }
          position = recordModel.playedTime;
        }
        _sourceTabController = TabController(length: video.sources.length, initialIndex: _sourceIndex, vsync: this);
        _sourceTabController.addListener(() {
          if (_sourceTabController.index.toDouble() == _sourceTabController.animation.value) {
            this.setState(() {
              _sourceIndex = _sourceTabController.index;
            });
          }
        });

        _startPlay(url, name, playPosition: position, version: versionModel, source: _currentSource);
      }
    }
    return video;
  }

  void _startPlay(String url, String name, { int playPosition, VersionModel version, SourceModel source }) async {
    if (RrmUtils.isRrmVideo(currentVideoSource)) {
      url = await RrmUtils.getM3u8Url(_currentSource, version, url);
    }

    // 切换视频，重置_cachePlayedSecond
    _cachePlayedSecond = -1;
    LogUtil.debug("当前播放：$name -> $url");
    // 初始化播放器
    _flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.network(url),
      autoInitialize: true,
      autoPlay: true,
    );
    if (playPosition != null) {
      _startPlayPosition = Duration(milliseconds: playPosition);
    }
    _flickManager.flickVideoManager.addListener(_videoListener);
    _playerDataManager.init(_flickManager, _videoModel, _sourceIndex, version, source, listener: _videoListener, initUrl: url);
    _playerDataManager.setCurrentPlayingByUrl(url);
    setState(() {});
  }

  @override
  void dispose() {
    if (myBannerAd != null) {
      myBannerAd.dispose();
    }
    _flickManager?.dispose();
    _db.close();

    super.dispose();
  }

  void _videoListener() async {
    if (_flickManager == null || _videoModel == null || _flickManager.flickVideoManager == null || !_flickManager.flickVideoManager.isVideoInitialized) return;
    if (_flickManager.flickVideoManager.isVideoInitialized && _startPlayPosition != null) {
      _flickManager.flickControlManager.seekTo(_startPlayPosition);
      _startPlayPosition = null;
    }
    VideoPlayerController _controller = _flickManager.flickVideoManager.videoPlayerController;
    // 视频播放同一秒内不执行操作
    if (_controller.value.position.inSeconds == _cachePlayedSecond) return;
    _cachePlayedSecond = _controller.value.position.inSeconds;

    String anthologyName;
    if (!_isSingleVideo) {
      VideoSource vs = _videoModel.sources[_sourceIndex];
      List<Anthology> anthologies = vs.anthologies;
      Anthology anthology = _playerDataManager?.currentAnthology;
      if (anthology != null) {
        anthologyName = anthology.name;
      }
    }

    // 播放记录
    if (_recordModel == null) {
      _recordModel = RecordModel(
          api: _currentSource.httpsApi,
          vid: widget.videoId,
          tid: _videoModel.tid,
          type: _videoModel.type,
          name: _videoModel.name,
          pic: _videoModel.pic,
          collected: 0,
          currentSourceIndex: _sourceIndex,
          anthologyName: anthologyName,
          progress: 0,
          playedTime: 0
      );
      _recordModel.id = await _db.insertRecord(_recordModel);
    } else {
      _db.updateRecord(_recordModel.id,
          anthologyName: anthologyName,
          playedTime: _controller.value.position.inMilliseconds,
          progress: _controller.value.position.inMilliseconds / _controller.value.duration.inMilliseconds,
          currentSourceIndex: _sourceIndex,
      );
    }

    if (!_isSingleVideo && _cachePlayedSecond >= _controller.value.duration.inSeconds) {
//      playNextVideoHandler();
    }
  }

  void playErrorHandler (VideoModel video) async {
    if (isReported) {
      return;
    }
    setState(() {
      isReported = true;
    });
    VideoSource vs = _videoModel.sources[_sourceIndex];
    var ant = _playerDataManager.currentAnthology;

    SuggestModel suggestModel = SuggestModel(
      type: 2,
      name: '无法播放: ' + video.name + '-' + ant.name,
      videoId: video.id,
      videoName: video.name,
      sourceName: vs.name,
      anthologyName: ant.name,
      platform: 'android',
      currentPlayUrl: ant.url,
      desc: '用户反馈，无法播放',
      awardedMarks: 0,
    );
    bool res = await HttpUtils.postSuggest(suggestModel);
    if (res) {
      BotToast.showText(text: '感谢您的报告');
    }
  }

  Widget _buildLoadingFallback(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: BackButton(color: Colors.white,),
        ),
        Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('精彩即将开始', style: TextStyle(color: Colors.white),),
                ),
              ],
            )
        )
      ],
    );
  }

  Widget _buildPlayerError(BuildContext context) {
//    print('视频播放错误：'  + errorMessage);
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: BackButton(color: Colors.white,),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.white,),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('抱歉，无法播放', style: TextStyle(color: Colors.white),),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('请尝试切换资源', style: TextStyle(color: Colors.white),),
              ),
//              Padding(
//                padding: EdgeInsets.only(top: 10),
//                child: Text(errorMessage, style: TextStyle(color: Colors.white70),),
//              ),
            ],
          )
        )
      ],
    );
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
                  ),
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
//      Padding(
//        padding: EdgeInsets.only(top: 8),
//        child: Divider(
//          color: Colors.grey.withOpacity(0.5),
//        ),
//      )
    ]);
    // 添加选集
    if (!_isSingleVideo) {
      children.addAll([
        /// 资源选择
        _buildAnthology(),
        Divider(
          height: 0,
          color: Colors.grey.withOpacity(0.5),
        ),
      ]);
    }

    // 添加简介
    children.addAll([
      Padding(
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('简介', style: TextStyle(
              color: KkColors.primaryWhite,
              fontSize: 18,
              height: 1
            )),
            TextButton(onPressed: () => playErrorHandler(video), child: Text(isReported ? '已报告错误' : '报告，无法播放？'))
          ],
        ),
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

  // 选集部分
  Widget _buildAnthology() {
    if (_videoModel == null) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.only(bottom: 10),
          child: TabBar(
            controller: _sourceTabController,
            isScrollable: true,
            onTap: (index) {
              setState(() {
                _sourceIndex = index;
              });
            },
            tabs: _videoModel.sources.map((e) => Tab(text: e.name + '资源',)).toList(),
          ),
        ),
        Container(
          height: 200,
          child: Consumer<PlayerDataManager>(builder: (ctx, _playerDataManager, child) {
            return TabBarView(
              controller: _sourceTabController,
              children: _videoModel.sources.map((e) {
                return Container(
                  child: GridView.builder(
                    padding: EdgeInsets.all(5.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      mainAxisExtent: 35,
                      crossAxisCount: 4,
                    ),
                    itemCount: e.anthologies.length,
                    itemBuilder: (ctx, index) {
                      Anthology ant = e.anthologies[index];
                      return _buildAnthologyButton(ant);
                    }
                  )
                );
              }).toList()
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAnthologyButton (Anthology anthology) {
    var _url = _playerDataManager?.currentAnthology?.url;
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ButtonStyle(
          elevation: MaterialStateProperty.all(0.0),
          padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 8)),
          backgroundColor: MaterialStateProperty.all(_url == anthology.url ? KkColors.primaryRed : KkColors.buttonBg),
        ),
        child: Text(anthology.name, style: TextStyle(
            color: _url == anthology.url ? Colors.white : null,
            fontSize: 14,
            fontWeight: FontWeight.normal
        ),),
        onPressed: () async {
          if (_url == anthology.url) return;
          if (_playerDataManager.sourceIndex != _sourceIndex) {
            _playerDataManager.setSourceIndex(_sourceIndex);
          }
          await _playerDataManager.skipToVideoByUrl(anthology.url);
        },
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

  GestureDetector _buildMirror() {
    return GestureDetector(
      onTap: () {
        if (_flickManager != null && _flickManager.flickControlManager.isFullscreen) {
          _flickManager.flickControlManager.exitFullscreen();
        }
        showDialog(
          context: context,
          builder: (content) {
            var name = _videoModel.name + '  ' + _playerDataManager.currentAnthology.name;
            var url = _playerDataManager.currentAnthology.url;
            return MirrorDialog(url: url, videoName: name, playerControls: _flickManager.flickVideoManager.videoPlayerController);
          },
        );
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
          Icons.mobile_screen_share,
          color: Colors.white,
        ),
      ),
    );
  }


  GestureDetector _buildDownload() {
    return GestureDetector(
      onTap: () async {
        if (RrmUtils.isRrmVideo(_playerDataManager.videoSource)) {
          BotToast.showText(text: '该资源不能下载');
          return;
        }
        var name = _videoModel.name + '  ' + _playerDataManager.currentAnthology.name;
        var url = _playerDataManager.currentAnthology.url;
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

  Widget _buildPlayerArea() {
    return Consumer<MirrorLinkProvider>(builder: (ctx, mirrorLinkProvider, child) {
      bool isMirrorRuning = mirrorLinkProvider.running;
      if (isMirrorRuning) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('是否结束投屏', style: TextStyle(color: Colors.black)),
                      actions: <Widget>[
                        TextButton(
                          child: Text('取消'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('确定'),
                          onPressed: () {
                            mirrorLinkProvider.disconnect();
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    )
                  )
                },
                child: Icon(
                  Icons.power_settings_new,
                  color: KkColors.primaryWhite,
                  size: 32,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(mirrorLinkProvider.currentDevice.name + ' 投屏中', style: TextStyle(color: KkColors.primaryWhite),),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(mirrorLinkProvider.videoName, style: TextStyle(color: KkColors.descWhite),),
              )
            ],
          ),
        );
      }
      if (_flickManager != null && _playerDataManager.currentAnthology != null) {
        return FlickVideoPlayer(
          flickManager: _flickManager,
//          preferredDeviceOrientationFullscreen: [
//            DeviceOrientation.portraitUp,
//            DeviceOrientation.landscapeLeft,
//            DeviceOrientation.landscapeRight,
//          ],
          flickVideoWithControls: FlickVideoWithControls(
            playerErrorFallback: _buildPlayerError(context),
            playerLoadingFallback: _buildLoadingFallback(context),
            controls: CustomEmbedControls(
              topRightWidget: Row(
                children: [
                  _buildMirror(),
                  _buildDownload(),
                ],
              ),
            ),
            videoFit: BoxFit.fitHeight,
          ),
          flickVideoWithControlsFullscreen: FlickVideoWithControls(
            playerErrorFallback: _buildPlayerError(context),
            controls: CustomOrientationControls(
              topRightWidget: Row(
                children: [
                  _buildMirror(),
                  _buildDownload(),
                ],
              ),
            ),
            videoFit: BoxFit.fitHeight,
          ),
        );
      } else {
        return Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: BackButton(color: Colors.white,),
            ),
            Center(
              child: CircularProgressIndicator(),
            )
          ],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _aspectRatio,
            child: Container(
              padding: EdgeInsets.only(top: MediaQueryData.fromWindow(window).padding.top),
              color: KkColors.black,
              child: _buildPlayerArea(),
            ),
          ),
          _bannerAdLoading
              ? Container()
              : Container(
            alignment: Alignment.center,
            child: AdWidget(ad: myBannerAd),
            width: myBannerAd.size.width.toDouble(),
            height: myBannerAd.size.height.toDouble(),
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