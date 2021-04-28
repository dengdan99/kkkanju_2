import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/models/video_model.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';

/// 横向的
class VideoItem extends StatelessWidget {

  VideoItem({ @required this.video, this.type = 0});

  final VideoModel video;
  final int type; // 0-竖屏(网格布局)    1-横屏(列表布局)

  String _getItemDescribe () {
    if (video.actor.isNotEmpty) return video.actor;
    if (video.area.isNotEmpty) return video.area;
    if (video.lang.isNotEmpty) return video.lang;
    if (video.last.isNotEmpty) return video.last;
    if (video.des.isNotEmpty) return video.des;
    return '暂无描述';
  }

  Widget _buildLandscapeItem() {
    return Card(
      color: KkColors.black,
      child: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child:
            ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
                child: video.note == null || video.note.isEmpty
                    ? FadeInImage.assetNetwork(
                  placeholder: 'assets/image/placeholder-l.jpg',
                  image: video.pic,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
                    : Stack(
                  children: <Widget>[
                    FadeInImage.assetNetwork(
                      placeholder: 'assets/image/placeholder-l.jpg',
                      image: video.pic,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                        top: 5,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: KkColors.primaryRed.withAlpha(125),
                          ),
                          child: Text(
                            video.note, overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14
                            ),),
                        )
                    )
                  ],
                )
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            margin: EdgeInsets.symmetric(vertical: 5),
            child: Column(
              children: [
                Text(
                  video.name,
                  style: TextStyle(
                    color: KkColors.primaryWhite,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getItemDescribe(),
                  style: TextStyle(
                    color: KkColors.descWhite,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitItem() {
    return Column(
      children: <Widget>[
        Expanded(
            flex: 1,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: video.note == null || video.note.isEmpty
                    ? FadeInImage.assetNetwork(
                  placeholder: 'assets/image/placeholder-p.jpg',
                  image: video.pic,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
                    : Stack(
                  children: <Widget>[
                    FadeInImage.assetNetwork(
                      placeholder: 'assets/image/placeholder-p.jpg',
                      image: video.pic,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                        top: 5,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: KkColors.primaryRed.withAlpha(125),
                          ),
                          child: Text(
                            video.note, overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),),
                        )
                    )
                  ],
                )
            )
        ),
        Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            children: [
              Text(
                video.name,
                style: TextStyle(
                  color: KkColors.primaryWhite,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _getItemDescribe(),
                style: TextStyle(
                  color: KkColors.descWhite,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Application.router.navigateTo(
              context, Routers.detailPage + '?id=${video.id}', transition: TransitionType.cupertino);
        },
        child: this.type == 0 ? _buildPortraitItem() : _buildLandscapeItem()
    );
  }
}