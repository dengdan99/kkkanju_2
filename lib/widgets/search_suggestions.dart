import 'package:flutter/material.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';

class SearchSuggestions extends StatefulWidget {
  final Function onClickHistory;

  SearchSuggestions({this.onClickHistory});

  @override
  _SearchSuggestionsStatus createState() => _SearchSuggestionsStatus();
}

class _SearchSuggestionsStatus extends State<SearchSuggestions> {
  List<String> _suggestList;

  @override
  void initState() {
    _suggestList = SpHelper.getStringList(Constant.key_search_history);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '历史搜索：',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0
                  )
              ),
              TextButton(
                  onPressed: () {
                    SpHelper.remove(Constant.key_search_history);
                    setState(() {
                      _suggestList = [];
                    });
                  },
                  child: Text(
                      '清除历史',
                      style: TextStyle(
                          color: Colors.teal,
                          fontSize: 12.0
                      )
                  )),
            ],
          ),
        ),
        Wrap(
          spacing: 16,
          alignment: WrapAlignment.start,
          children: _suggestList.map((str) {
            return RaisedButton(
              child: Text(str),
              onPressed: () {
                widget.onClickHistory(str);
              },
            );
          }).toList(),
        )

      ],
    );
  }
}