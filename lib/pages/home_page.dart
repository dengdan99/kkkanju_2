import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';
import 'package:kkkanju_2/utils/db_helper.dart';
import 'package:kkkanju_2/models/record_model.dart';
import 'package:kkkanju_2/utils/http_utils.dart';
import 'package:kkkanju_2/widgets/video_item.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DBHelper _db = DBHelper();
  bool _firstLoading = true;
  EasyRefreshController _controller;
  List<RecordModel> _recordList = [];
  List<_LevelModel> _levelList = [
    _LevelModel(title: '电影推荐', level: 8, videos: []),
    _LevelModel(title: '美剧推荐', level: 5, videos: []),
    _LevelModel(title: '韩剧推荐', level: 6, videos: []),
    _LevelModel(title: 'KK推荐', level: 7, videos: []),
  ];

  @override
  void initState() {
    super.initState();
    _controller = EasyRefreshController();
    _initData();
  }

  Future<void> _initData() async {
    List record = await _db.getRecordList(pageNum: 0, pageSize: 20, played: true);
    _levelList.asMap().forEach((index, _levelItem) {
      HttpUtils.getLevelVideo(_levelItem.level).then((res) {
        setState(() {
          _levelList[index].videos = res;
          _firstLoading = false;
        });
      });
    });
    setState(() {
      _recordList = record;
    });
  }

  Widget _buildLineTitle(String title, { String path }) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              color: KkColors.primaryWhite,
            ),
          ),
          path != null && path.isNotEmpty ?
          TextButton(
            onPressed: () {
              if (path.isNotEmpty) {
                Application.router.navigateTo(context, path);
              }
            },
            child: Text(
              '更多 >>',
              style: TextStyle(
                fontSize: 14,
                color: KkColors.descWhite
              ))
          ) : Container(),
        ],
      ),
    );
  }

  Widget _bulidMyRecord() {
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLineTitle('最近观看', path: Routers.playRecordPage),
          Container(
            height: 200,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(10),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => GestureDetector(
                            onTap: () { Application.router.navigateTo(context,  Routers.detailPage + '?id=${_recordList[index].vid}'); },
                            child: _buildHomeRecordItem(_recordList[index])
                          ),
                      childCount: _recordList.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 8,
                        childAspectRatio: 16 / 9
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeRecordItem(RecordModel video) {
    RecordModel model = video;
    String recordStr = '看到';
    if (model.progress > 0.99) {
      recordStr += '  ' + '播放完毕';
    } else {
      recordStr += '  ' + (model.progress * 100).toStringAsFixed(2) + '%';
    }

    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: video.type == null || video.type.isEmpty
                ? FadeInImage.assetNetwork(
              placeholder: 'assets/image/placeholder-p.jpg',
              image: model.pic,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
                : Stack(
              children: <Widget>[
                FadeInImage.assetNetwork(
                  placeholder: 'assets/image/placeholder-p.jpg',
                  image: model.pic,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                    top: 5,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: KkColors.primaryRed.withAlpha(125),
                      ),
                      child: Text(
                        model.anthologyName != null ? model.anthologyName : model.type ,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),),
                    )
                )
              ],
            )
          )
        ),
        Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            children: [
              Text(
                video.name,
                style: TextStyle(
                  color: KkColors.primaryWhite,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                recordStr,
                style: TextStyle(
                  color: KkColors.descWhite,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevel(_LevelModel levelModel) {
    return SliverPadding(
      padding: EdgeInsets.all(10),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          return VideoItem(video: levelModel.videos[index], type: 0,);
        },
          childCount: levelModel.videos.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 9 / 15
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    List<Widget> mainColum = [];
    if (_recordList.length > 0) mainColum.add(_bulidMyRecord());
    _levelList.forEach((item) {
      if (item.videos.length > 0) {
        mainColum.add(
          SliverToBoxAdapter(
            child: _buildLineTitle(item.title),
          )
        );
        mainColum.add(_buildLevel(item));
      }
    });
    return _firstLoading
        ? Center(
        child: CircularProgressIndicator()
    )
        : EasyRefresh.custom(
      controller: _controller,
      slivers: mainColum,
      header: ClassicalHeader(
          textColor: KkColors.primaryWhite,
          infoColor: KkColors.primaryRed,
          refreshText: '下拉刷新',
          refreshReadyText: '释放刷新',
          refreshingText: '正在刷新...',
          refreshedText: '已获取最新数据',
          infoText: '更新于%T'
      ),
      onRefresh: () async {
        await _initData();
      },
    );
  }
}



class _LevelModel {
  String title;
  int level;
  List<VideoModel> videos;

  _LevelModel({this.title, this.level, this.videos});
}