import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lblelinkplugin/tv_list.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../common/kk_colors.dart';
import '../provider/mirror_link.dart';

class MirrorDialog extends StatefulWidget {
  final String url;
  VideoPlayerController playerControls;
  final String videoName;

  MirrorDialog({@required this.url, @required this.playerControls, this.videoName});

  @override
  _MirrorDialogState createState() => _MirrorDialogState();
}

class _MirrorDialogState extends State<MirrorDialog> {
  bool _loading = false;
  bool _searching = false;
  MirrorLinkProvider _mirrorLinkProvider;

  @override
  void initState() {
    super.initState();
    _searchTv();
  }

  @override
  void dispose() {
    _mirrorLinkProvider.removeListener(_mirrorListener);
    super.dispose();
  }

  void _connectTv (TvData tv) async {
    Navigator.of(context).pop();
    widget.playerControls.pause();
    await context.read<MirrorLinkProvider>().connect(widget.url, widget.videoName, tv);
    setState(() {});
  }

  Future<void> _searchTv() async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });
    _mirrorLinkProvider = context.read<MirrorLinkProvider>();
    await _mirrorLinkProvider.init();
    _mirrorLinkProvider.addListener(_mirrorListener);
    _mirrorLinkProvider.startSearchTvData();
    setState(() {
      _searching = true;
      _loading = false;
    });
  }

  void _mirrorListener() {
    print('_mirrorLinkProvider 事件监听');
  }

  Widget _buildTvList (BuildContext context) {
    return Consumer<MirrorLinkProvider>(builder: (ctx, mirrorLinkProvider, child) {
      TvData selected = mirrorLinkProvider.selected;
      List<TvData> _tvData = mirrorLinkProvider.tvData;
      return Container(
        child: _tvData.length == 0
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 100.0,
                height: 100.0,
//                child: Image.asset('assets/image/nodata.png'),
                child: Icon(Icons.wifi, size: 60, color: Colors.grey[800],),
              ),
              Text(
                '正在搜索中',
                style: TextStyle(fontSize: 14.0, color: Colors.grey[400]),
              ),
              Text(
                '请确保设备在同一wifi下',
                style: TextStyle(fontSize: 14.0, color: Colors.grey[400]),
              ),
            ],
          ),
        )
            : ListView.builder(
            shrinkWrap: true,
            physics: const ScrollPhysics(),
            itemCount: _tvData.length,
            itemBuilder: (context, index) {
              bool slet = false;
              if (selected != null) {
                slet = selected.uId == _tvData[index].uId;
              }
              return ListTile(
//             dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
                leading: Icon(Icons.tv, color: slet ? KkColors.primaryRed : KkColors.descWhite,),
                onTap: () => _connectTv(_tvData[index]),
                title: Text(_tvData[index].name, style: TextStyle(color: slet ? KkColors.primaryRed : KkColors.descWhite,),),
                trailing: slet
                    ? Icon(Icons.check, color: KkColors.primaryRed,)
                    : Text('选择',  style: TextStyle(color: KkColors.descWhite),),
              );
            }
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: KkColors.mainBlackBg,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('请选择设备'),
          TextButton(
            onPressed: () => _searchTv(),
            child: _searching ?  Text('搜索中...') :  Text('重新搜索'),
          )
        ],
      ),
      content: Container(
        height: 250,
        child: _loading
            ? Align(
          child: CircularProgressIndicator(),
        )
            : _buildTvList(context),
      )
    );
  }
}