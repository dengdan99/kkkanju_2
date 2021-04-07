import 'dart:convert';

/// 视频实体类
class VideoModel {
  String id;
  String tid; // 分类ID
  String type; // 分类名称
  String name; // 标题名
  String pic; // 缩略图

  String lang; // 语言
  String area; // 地区
  String year; // 年份
  String last;  // 上传时间
  String state;
  String note; // 标签
  String actor; // 演员
  String director; // 导演
  String des; // 描述
  List<Anthology> anthologies; // 选集列表
  List<VideoSource> sources; // 播放源

  VideoModel({
    this.id,
    this.name,
    this.tid,
    this.type,
    this.pic,
    this.lang,
    this.area,
    this.year,
    this.last,
    this.state,
    this.note,
    this.actor,
    this.director,
    this.des,
    this.anthologies,
    this.sources});

  VideoModel.fromJson(Map<String, dynamic> json) {
    this.id = json['id'];
    this.name = json['name'];
    this.type = json['type'];
    this.tid = json['tid'];
    this.pic = json['pic'];
    this.lang = json['lang'];
    this.area = json['area'];
    this.year = json['year'];
    this.last = json['last'];
    this.state = json['state'];
    this.note = json['note'];
    this.actor = json['actor'];
    this.director = json['director'];
    this.des = json['des'];
    if (json['sources'] != null) {
      this.sources = <VideoSource>[];
      json['sources'].forEach((e) {
        this.sources.add(VideoSource.fromJSON(e));
      });
    }
    if (json['anthologies'] != null) {
      this.anthologies = <Anthology>[];
      json['anthologies'].forEach((e) {
        this.anthologies.add(Anthology.fromJSON(e));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['type'] = this.type;
    data['tid'] = this.tid;
    data['pic'] = this.pic;
    data['lang'] = this.lang;
    data['area'] = this.area;
    data['year'] = this.year;
    data['last'] = this.last;
    data['state'] = this.state;
    data['note'] = this.note;
    data['actor'] = this.actor;
    data['director'] = this.director;
    data['des'] = this.des;
    if (this.sources != null) {
      data['sources'] = this.sources.map((e) => e.toJson()).toList();
    }
    if (this.anthologies != null) {
      data['anthologies'] = this.anthologies.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// 选集
class Anthology {
  String name;
  String url;

  Anthology({this.name, this.url});

  Anthology.fromJSON(Map<String, dynamic> json) {
    name = json['name'];
    url = json['tid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['url'] = this.url;
    return data;
  }
}

/// 视频源
class VideoSource {
  String name;
  List<Anthology> anthologies;

  VideoSource({this.name, this.anthologies});

  VideoSource.fromJSON(Map<String, dynamic> json) {
    name = json['name'];
    if (json['anthologies'] != null) {
      this.anthologies = <Anthology>[];
      json['anthologies'].forEach((e) {
        this.anthologies.add(Anthology.fromJSON(e));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    if (this.anthologies != null) {
      data['anthologies'] = this.anthologies.map((v) => v.toJson()).toList();
    }
    return data;
  }
}