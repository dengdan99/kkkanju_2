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
  bool _firstLoading = false;
  TabController _navController;
  List<CategoryModel> _categoryList = [];
  List<_TabViewData> _tabViewData = [];

  @override
  void initState() {
    _initData();
    super.initState();
  }
  @override
  void dispose() {
    _navController?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _initData() async {
    setState(() {
      _firstLoading = true;
    });
    try {
      await _getCategoryList();
      if (_tabViewData[0] != null) {
        await _getVideoList(_tabViewData[0]);
      }
    } catch(e) {
      print(e);
    }
    setState(() {
      _firstLoading = false;
    });
  }

  // 获取分类 电影的
  Future<int> _getCategoryList() async {
    if (!mounted) return 0;
    _navController?.dispose();
    setState(() {
      _categoryList = [];
    });
    List<CategoryModel> list = await HttpUtils.getCategoryList();
    list.retainWhere((element) => (element.pid != '1' && element.id != '1'));
    setState(() {
      _categoryList = list;
      _navController = TabController(length: _categoryList.length, vsync: this);
      _tabViewData = List.generate(_categoryList.length, (index) => _TabViewData(pageNum: 1, typeId: _categoryList[index].id, list: [], controller: EasyRefreshController()));
    });
    _navController.addListener(() {
      int index = _navController.index;
      if (_tabViewData[index].list.isEmpty) {
        _getVideoList(_tabViewData[index]);
      }
    });
  }

  //  获取视频列表
  Future<int> _getVideoList(_TabViewData viewData) async {
    List<VideoModel> videos = await HttpUtils.getVideoList(pageNum: viewData.pageNum,  type: viewData.typeId);
    if (!mounted) return 0;
    setState(() {
      if (viewData.pageNum <= 1) {
        viewData.list = videos;
      } else {
        viewData.list += videos;
      }
      viewData.firstLoading = false;
    });
    return videos.length;
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
              ) : Container(),
            ),
          ],
        ),
        preferredSize: Size.fromHeight(40)
    );
  }

  Widget _buildVideoList(_TabViewData data) {
    return EasyRefresh.custom(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              return VideoItem(video: data.list[index], type: 0,);
            },
              childCount: data.list.length,
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
      emptyWidget: data.firstLoading ? Center(child: CircularProgressIndicator()) : (data.list.isEmpty ? NoData(tip: '没有找到视频',) : null),
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
        data.pageNum = 1;
        await _getVideoList(data);
      },
      onLoad: () async {
        data.pageNum ++;
        int len = await _getVideoList(data);
        if (len < 20) {
          data.controller.finishLoad(noMore: true);
        }
      },
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
            Expanded(child: TabBarView(
              controller: _navController,
              children: _tabViewData.map((e) => _buildVideoList(e)).toList(),
            ))
          ],
        ),
      ),
    );
  }
}



class _TabViewData {
  int pageNum = 0;
  String typeId;
  List<VideoModel> list;
  EasyRefreshController controller;
  bool firstLoading = true;

  _TabViewData({this.pageNum, this.typeId, this.list, this.controller});
}