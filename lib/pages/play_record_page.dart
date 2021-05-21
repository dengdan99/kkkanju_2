import 'package:bot_toast/bot_toast.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/record_model.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';
import 'package:kkkanju_2/utils/db_helper.dart';
import 'package:kkkanju_2/utils/fluro_convert_util.dart';
import 'package:kkkanju_2/widgets/no_data.dart';

class PlayRecordPage extends StatefulWidget {
  @override
  _PlayRecordPageState createState() => _PlayRecordPageState();
}

class _PlayRecordPageState extends State<PlayRecordPage> {
  DBHelper _db = DBHelper();
  EasyRefreshController _controller = EasyRefreshController();

  int _pageNum = -1; // 从0开始
  List<RecordModel> _recordList = [];

  Future<int> _getRecordList() async {
    List list = await _db.getRecordList(pageNum: _pageNum, pageSize: 20, played: true);
    if (!mounted) return 0;
    setState(() {
      if (_pageNum <= 0) {
        _recordList = list;
      } else {
        _recordList += list;
      }
    });
    return list.length;
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('播放记录'),
      ),
      body: EasyRefresh.custom(
          controller: _controller,
          firstRefresh: true,
          firstRefreshWidget: Center(
            child: CircularProgressIndicator(),
          ),
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                RecordModel model = _recordList[index];
                String recordStr = '';
                if (model.anthologyName != null) {
                  recordStr += model.anthologyName;
                }
                if (model.progress > 0.99) {
                  recordStr += '  ' + '播放完毕';
                } else {
                  recordStr += '    ' + (model.progress * 100).toStringAsFixed(2) + '%';
                }
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/image/placeholder-l.jpg',
                      image: model.pic,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 75,
                    ),
                  ),
                  title: Text(model.name, style: TextStyle(color: KkColors.black, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2,),
                  subtitle: Text(recordStr, style: TextStyle(color: KkColors.descBlack, fontSize: 12)),
                  isThreeLine: false,
                  trailing: SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: Icon(Icons.delete_forever),
                      color: Color(0xff3d3d3d),
                      onPressed: () => _deleteRecord(model),
                    ),
                  ),
                  onTap: ()  => _playVideo(model.api, model.vid),
                );
              },
                childCount: _recordList.length,
              ),
            )
          ],
          emptyWidget: _recordList.length == 0
              ? NoData(tip: '没有播放记录',)
              : null,
          header: ClassicalHeader(
              refreshText: '下拉刷新',
              refreshReadyText: '释放刷新',
              refreshingText: '正在刷新...',
              refreshedText: '已获取最新数据',
              infoText: '更新于%T'),
          footer: ClassicalFooter(
              loadText: '上拉加载',
              loadReadyText: '释放加载',
              loadingText: '正在加载',
              loadedText: '已加载结束',
              noMoreText: '没有更多数据了~',
              infoText: '更新于%T'),
          onRefresh: () async {
            _pageNum = 0;
            await _getRecordList();
          },
          onLoad: () async {
            _pageNum++;
            int len = await _getRecordList();
            if (len < 20) {
              _controller.finishLoad(noMore: true);
            }
          }
      ),
    );
  }

  void _playVideo(String api, String vid) {
    Application.router.navigateTo(context, Routers.detailPage + '?api=${FluroConvertUtils.fluroCnParamsEncode(api)}&id=$vid', transition: TransitionType.cupertino);
  }

  void _deleteRecord(RecordModel model) async {
    int i = await _db.deleteRecordById(model.id);
    if (i > 0) {
      _recordList.remove(model);
      setState(() {});
      BotToast.showText(text: '删除成功');
    }
  }
}
