import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kkkanju_2/models/version_model.dart';
import 'package:kkkanju_2/utils/http_utils.dart';
import 'package:provider/provider.dart';

import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/provider/category.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class SourceProvider with ChangeNotifier {

  SourceModel _currentSource;

  SourceModel get currentSource => _currentSource;

  void setCurrentSource(SourceModel model, BuildContext context) {
    _currentSource = model;
    SpHelper.putObject(Constant.key_current_source, model);
  }

  // 预加载一些数据
  void preloadData(BuildContext context) {
    context.read<CategoryProvider>().setCategoryIndex(0);
    context.read<CategoryProvider>().getCategoryList();
    notifyListeners();
  }

  /// 获取版本
  Future<VersionModel> getVersion({bool force = false}) async {
    Map json = SpHelper.getObject(Constant.key_version_result);
    VersionModel _version;
    if (json == null || force) {
      _version = await HttpUtils.getLastVersion();
      SpHelper.putObject(Constant.key_version_result, _version);
    } else {
      _version = VersionModel.fromJson(json);
    }
    return _version;
  }

  /// 检查版本
  Future<bool> checkVersion(BuildContext ctx) async {
    int _localVersion = _currentSource.version;
    bool onclickOk;
    VersionModel version = await getVersion(force: true);
    if (version == null) return true;
    if (version.enable && version.version > _localVersion) {
      onclickOk = await _uploadDialog(version, ctx);
      if (onclickOk) {
        if (version.jumpUrl != null && version.jumpUrl.isNotEmpty) {
          launch(version.jumpUrl);
        } else {
          launch(version.appUrl);
        }
      }
      return false;
    } else {
      return true;
    }
  }

  Future<bool> _uploadDialog(VersionModel version,  BuildContext ctx) {
    List<Widget> buttons = [];
    if (!version.isForce) {
      buttons.add(TextButton(
        child: Text("暂时不升级"),
        onPressed: () => Navigator.of(ctx).pop(false),
      ));
    }
    buttons.add(TextButton(
      child: Text("立即升级"),
      onPressed: () {
        Navigator.of(ctx).pop(true);
      },
    ));
    return showDialog(
      barrierDismissible: false,
      context: ctx,
      builder: (_) {
        return AlertDialog(
          title: Text("发现新的版本", style: TextStyle(color: Colors.black),),
          content: Text(version.descript, style: TextStyle(color: Colors.black),),
          actions: buttons,
        );
      },
    );
  }
}