import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/models/version_model.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/utils/aes_utils.dart';
import 'package:kkkanju_2/utils/http_utils.dart';
import 'package:kkkanju_2/utils/log_util.dart';

class RrmUtils {
  /// 这些视频源 让rrm 来解析
  static final List<String> rrmSourceName = ['kkvip', 'kkkanju_blue', 'youku', 'qiyi', 'qq', 'mgtv', 'sohu', 'bilibili', 'renrenmi'];

  static bool isRrmVideo(VideoSource videoSource) {
    return rrmSourceName.contains(videoSource.name);
  }

  static String getKey(SourceModel _sourceModel, VersionModel versionModel) {
    return AesUtils.decryptAes(versionModel.rrmKey, _sourceModel.key, iv: _sourceModel.iv);
  }

  static Future<String> getM3u8Url(SourceModel _sourceModel, VersionModel _versionModel, String originUrl) async {
    final key = getKey(_sourceModel, _versionModel);
    String url = '';
    url = await HttpUtils.getRrmUrl(key, _versionModel.rrmType, originUrl);
    LogUtil.debug('人人迷资源地址: ' + url);
    return url;
  }
}

