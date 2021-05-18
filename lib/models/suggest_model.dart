import 'dart:developer';

import 'dart:io';

import 'package:kkkanju_2/utils/http_utils.dart';

/**
 * type: 0 基本建议 ， 1 求片， 2 无法播放
 */
class SuggestModel {
  int type;
  int userId;
  String platform;
  String videoId;
  String videoName;
  String name;
  String sourceName;
  String anthologyName;
  String currentPlayUrl;
  String desc;
  int awardedMarks;
  String ip;

  SuggestModel({this.type, this.userId, this.platform, this.videoId, this.videoName, this.name, this.sourceName, this.anthologyName, this.currentPlayUrl, this.desc, this.awardedMarks});

  Future<Map<String, dynamic>> toJson() async {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.ip == null) await setIp();
    data['type'] = this.type;
    data['user_id'] = this.userId;
    data['platform'] = this.platform;
    data['video_id'] = this.videoId != null ? int.parse(this.videoId) : null;
    data['name'] = this.name;
    data['video_name'] = this.videoName;
    data['source_name'] = this.sourceName;
    data['anthology_name'] = this.anthologyName;
    data['play_url'] = this.currentPlayUrl;
    data['desc'] = this.desc;
    data['awarded_marks'] = this.awardedMarks;
    data['ip'] = this.ip;
    return data;
  }

  setIp () async {
    this.ip = await HttpUtils.getLocalIp();
  }
}
