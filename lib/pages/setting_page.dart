import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/provider/app_info.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {

  String _colorKey;
  bool _wifiAutoDownload = true;
  bool _toMP4 = true;

  @override
  void initState() {
    super.initState();

    _colorKey = SpHelper.getString(Constant.key_theme_color, defValue: 'blue');
    _wifiAutoDownload = SpHelper.getBool(Constant.key_wifi_auto_download, defValue: true);
    _toMP4 = SpHelper.getBool(Constant.key_m3u8_to_mp4, defValue: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.wifi),
            title: Text('WiFi自动下载'),
            trailing: Switch(
                value: _wifiAutoDownload,
                onChanged: (v) {
                  setState(() {
                    _wifiAutoDownload = v;
                  });
                  SpHelper.putBool(Constant.key_wifi_auto_download, v);
                }
            ),
            onTap: () {
              bool v = !_wifiAutoDownload;
              setState(() {
                _wifiAutoDownload = v;
              });
              SpHelper.putBool(Constant.key_wifi_auto_download, v);
            },
          ),
          ListTile(
            leading: Icon(Icons.crop),
            title: Text('M3U8转MP4'),
            trailing: Switch(
                value: _toMP4,
                onChanged: (v) {
                  setState(() {
                    _toMP4 = v;
                  });
                  SpHelper.putBool(Constant.key_m3u8_to_mp4, v);
                }
            ),
            onTap: () {
              bool v = !_toMP4;
              setState(() {
                _toMP4 = v;
              });
              SpHelper.putBool(Constant.key_m3u8_to_mp4, v);
            },
          ),
          ListTile(
            leading: Icon(Icons.clear_all),
            title: Text('清空缓存'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              BotToast.showText(text: '待开发');
            },
          ),
        ],
      ),
    );
  }
}