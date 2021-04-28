import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/category_model.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/provider/source.dart';
import 'package:kkkanju_2/utils/http_utils.dart';
import 'package:kkkanju_2/widgets/animated_floating_action_button.dart';
import 'package:kkkanju_2/widgets/no_data.dart';
import 'package:kkkanju_2/widgets/video_item.dart';
import 'package:provider/provider.dart';

class SortPage extends StatefulWidget {
  @override
  _SortPageState createState() => _SortPageState();
}

class _SortPageState extends State<SortPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // 滚动控制
  TabController _navController;
  List<CategoryModel> _categoryList = [];
  String _type = '';
  // 布局方式
  bool _isLandscape = false;

  EasyRefreshController _controller;
  int _pageNum = 1;
  List _videoList = [];
  SourceModel _currentSource;
  SourceProvider _sourceProvider;
  GlobalKey<AnimatedFloatingActionButtonState> _buttonKey = GlobalKey<AnimatedFloatingActionButtonState>();
  bool _firstLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _navController = TabController(length: _categoryList.length, vsync: this);
    _controller = EasyRefreshController();

    _sourceProvider = context.read<SourceProvider>();
    _currentSource = _sourceProvider.currentSource;
    _sourceProvider.addListener(() {
      if (!mounted) return;
      setState(() {
        _videoList = [];
        _currentSource = _sourceProvider.currentSource;
      });
      _initData();
    });
    _initData();
  }

  // 获取分类
  Future<void> _getCategoryList() async {
    if (!mounted) return;
    _navController?.dispose();
    setState(() {
      _type = '';
      _categoryList = [];
    });
    List<CategoryModel> list = await HttpUtils.getCategoryList();
    list.retainWhere((element) => (element.pid != '1' && element.id != '1'));
    setState(() {
      _categoryList = [CategoryModel(id: '', name: '最新')] + list;
      _navController = TabController(length: _categoryList.length, vsync: this);
    });
  }
  //  获取视频列表
  Future<int> _getVideoList() async {
    int hour; // 最近几个小时更新
    if (_type == null || _type.isEmpty) {
      hour = 72;
    }
    List<VideoModel> videos = await HttpUtils.getVideoList(pageNum: _pageNum, type: _type, hour: hour);
    if (!mounted) return 0;
    setState(() {
      if (this._pageNum <= 1) {
        _videoList = videos;
      } else {
        _videoList += videos;
      }
    });
    return videos.length;
  }

  void _initData() async {
    setState(() {
      _firstLoading = true;
      _pageNum = 1;
    });
    try {
      await _getCategoryList();
      await _getVideoList();
    } catch(e) {
      print(e);
    }
    setState(() {
      _firstLoading = false;
    });
  }

  Widget _buildCategoryNav() {
    return PreferredSize(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: _categoryList.isNotEmpty ? TabBar(
                controller: _navController,
                isScrollable: true,
                tabs: _categoryList.map((e) => Tab(text: e.name,)).toList(),
                onTap: (index) {
                  this._type = _categoryList[index].id;
                  this._pageNum = 0;
                  this._controller.callRefresh();
                },
              ) : Container(),
            ),
            Container(
              height: 20,
              margin: EdgeInsets.only(left: 4),
              child: VerticalDivider(
                color: Colors.grey[200],
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              padding: EdgeInsets.only(left: 4),
              child: IconButton(
                color: KkColors.descWhite,
                icon: Icon(_isLandscape ? Icons.list : Icons.table_chart),
                padding: EdgeInsets.all(4),
                onPressed: () {
                  setState(() {
                    _isLandscape = !_isLandscape;
                  });
                },
              ),
            )
          ],
        ),
        preferredSize: Size.fromHeight(40)
    );
  }

  Widget _buildVideoList() {
    return NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null && _buttonKey.currentState != null) {
            if (notification.dragDetails.delta.dy < 0 && _buttonKey.currentState.isShow) {
              _buttonKey.currentState.hide();
            } else if (notification.dragDetails.delta.dy > 0 && !_buttonKey.currentState.isShow) {
              _buttonKey.currentState.show();
            }
          }
          return false;
        },
        child: EasyRefresh.custom(
          controller: _controller,
          slivers: [
            _isLandscape
                ? SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return VideoItem(video: _videoList[index], type: 1,);
              },
                  childCount: _videoList.length
              ),
            )
                : SliverPadding(
              padding: EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return VideoItem(video: _videoList[index], type: 0,);
                },
                  childCount: _videoList.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    childAspectRatio: 9 / 15
                ),
              ),
            )
          ],
          emptyWidget: _videoList.length == 0 ? NoData(tip: '没有找到视频',) : null,
          header: ClassicalHeader(
            textColor: KkColors.primaryWhite,
            infoColor: KkColors.primaryRed,
            refreshText: '下拉刷新',
            refreshReadyText: '释放刷新',
            refreshingText: '正在刷新...',
            refreshedText: '已获取最新数据',
            infoText: '更新于%T'
          ),
          footer: ClassicalFooter(
            textColor: KkColors.primaryWhite,
            infoColor: KkColors.primaryRed,
            loadText: '上拉加载',
            loadReadyText: '释放加载',
            loadingText: '正在加载',
            loadedText: '已加载结束',
            noMoreText: '没有更多数据了~',
            infoText: '更新于%T',
          ),
          onRefresh: () async {
            _pageNum = 1;
            await _getVideoList();
          },
          onLoad: () async {
            _pageNum ++;
            int len = await _getVideoList();
            print(len);
            if (len < 20) {
              _controller.finishLoad(noMore: true);
            }
          },
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      height: double.infinity,
      child: _firstLoading
          ? Center(
          child: CircularProgressIndicator(),
        )
          : Container(
        child: Column(
//          mainAxisSize: MainAxisSize.max,
          children: [
            _buildCategoryNav(),
            Expanded(child: _buildVideoList())
          ],
        ),
      ),
    );
  }
}