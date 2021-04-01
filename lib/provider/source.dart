import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/models/source_model.dart';
import 'package:kkkanju_2/provider/category.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';

class SourceProvider with ChangeNotifier {

  SourceModel _currentSource;

  SourceModel get currentSource => _currentSource;

  void setCurrentSource(SourceModel model, BuildContext context) {
    _currentSource = model;
    SpHelper.putObject(Constant.key_current_source, model);

    context.read<CategoryProvider>().setCategoryIndex(0);
    context.read<CategoryProvider>().getCategoryList();
    notifyListeners();
  }
}