import 'package:flutter/material.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/utils/analytics_utils.dart';
import 'package:kkkanju_2/utils/http_utils.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';
import 'package:kkkanju_2/widgets/search_suggestions.dart';
import 'package:kkkanju_2/widgets/video_item.dart';

class SearchBarDelegate extends SearchDelegate<String> {
  Future<List<VideoModel>> _future;
  List<VideoModel> res = [];
  String keywords = '';

  SearchBarDelegate({
    String hintText,
  }) : super(
    searchFieldLabel: hintText
  );

  Future<List<VideoModel>> _getSearchResult(str) async {
    if (str == null || str == '') return [];
    if (keywords == str && res.isNotEmpty) {
      return res;
    }
    keywords = str;
    res = await HttpUtils.searchVideo(str);
    return res;
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

  @override
  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    assert(theme != null);
    return theme.copyWith(
      primaryColor: KkColors.mainBlackBg,
      primaryColorDark: KkColors.mainBlackBg,
      backgroundColor: KkColors.mainBlackBg,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
        backgroundColor: KkColors.black,
        iconTheme: theme.primaryIconTheme.copyWith(color: KkColors.greyInBalck),
        textTheme: theme.textTheme,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: KkColors.greyInBalck,
        hintStyle: TextStyle(
          color: KkColors.descWhite,
        ),
        labelStyle: TextStyle(
          color: KkColors.primaryWhite,
        ),
        border: InputBorder.none,
      ),
    );
  }

  //重写右侧的图标
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        //将搜索内容置为空
        onPressed: () {
          if (query == "") {
            close(context, null);
          } else {
            query = "";
            showSuggestions(context);
          }
        },
      )
    ];
  }

  //重写返回图标
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: AnimatedIcon(
            icon: AnimatedIcons.menu_arrow,
            progress: transitionAnimation
        ),
        //关闭上下文，当前页面
        onPressed: () => close(context, null));
  }

  //重写搜索结果
  @override
  Widget buildResults(BuildContext context) {
    _future = _getSearchResult(query);
    return FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return _buildText('网络请求出错了');
            }
            if (snapshot.hasData && snapshot.data != null) {
              try {
                AnalyticsUtils.searchEvent(keywords: query);
                List<VideoModel> videoList = snapshot.data;
                List _suggestList = SpHelper.getStringList(Constant.key_search_history, defValue: []);
                if (!_suggestList.contains(query)) {
                  _suggestList.insert(0, query);
                  SpHelper.putStringList(Constant.key_search_history, _suggestList);
                }
                if (videoList.length == 0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(),
                          flex: 2,
                        ),
                        SizedBox(
                          width: 100.0,
                          height: 100.0,
                          child: Image.asset('assets/image/nodata.png'),
                        ),
                        Text(
                          '没有找到视频',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey[400]),
                        ),
                        Expanded(
                          child: SizedBox(),
                          flex: 3,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: videoList.length,
                  itemBuilder: (context, index) {
                    return VideoItem(video: videoList[index], type: 1,);
                  }
                );
              } catch (e) {
                print(e);
                return _buildText('数据解析错误');
              }
            } else {
              return _buildText('没有找到视频');
            }
          } else {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: KkColors.mainBlackBg,
              ),
            );
          }
        }
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return SearchSuggestions(onClickHistory: (str) {
      query = str;
      showResults(context);
    });
  }
}