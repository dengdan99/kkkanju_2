class CategoryModel {
  String id;
  String name;
  String pid;

  CategoryModel(
      {this.id,
        this.pid,
        this.name});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    pid = json['pid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['pid'] = this.pid;
    return data;
  }
}
