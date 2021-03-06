class VersionModel {
  int id;
  int version; // 版本号
  String jumpUrl; // 下载落地页
  String appUrl; // app 下载链接
  String platform; // 平台 android / ios
  bool isForce; // 是否强制更新
  bool enable; // 是否启用更新
  String descript; // 更新描述
  String rrmApi;
  String rrmKey;
  String rrmType;
  String apiEncryptKey; // api加密过的密钥

  VersionModel({
    this.id,
    this.version,
    this.jumpUrl,
    this.appUrl,
    this.platform,
    this.isForce,
    this.enable,
    this.descript,
    this.rrmApi,
    this.rrmType,
    this.rrmKey,
    this.apiEncryptKey
  });

  VersionModel.fromJson(Map<String, dynamic> json) {
    this.id = json['id'];
    this.version = json['version'];
    this.jumpUrl = json['jump_url'];
    this.appUrl = json['app_url'];
    this.platform = json['platform'];
    this.isForce = json['is_force'] == 1 ? true : false;
    this.enable = json['enable'] == 1 ? true : false;
    this.descript = json['descript'];
    this.rrmApi = json['rrm_api'];
    this.rrmKey = json['rrm_key'];
    this.apiEncryptKey = json['api_key'];
    this.rrmType = json['rrm_type'] ?? 'json';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['version'] = this.version;
    data['jump_url'] = this.jumpUrl;
    data['app_url'] = this.appUrl;
    data['platform'] = this.platform;
    data['is_force'] = this.isForce ? 1 : 0;
    data['enable'] = this.enable ? 1 : 0;
    data['descript'] = this.descript;
    data['rrm_api'] = this.rrmApi;
    data['rrm_key'] = this.rrmKey;
    data['rrm_type'] = this.rrmType;
    data['api_key'] = this.apiEncryptKey;
    return data;
  }
}
