import 'package:logger/logger.dart';

class LogUtil {
  static Logger _log;
  static Logger getLogInstance () {
    if (_log == null) {
      _log = Logger();
    }
    return _log;
  }
  static Logger get log => getLogInstance();

  static void debug(dynamic message) {
    if (_log == null) getLogInstance();
    _log.d(message);
  }

  static void info(dynamic message) {
    if (_log == null) getLogInstance();
    _log.i(message);
  }

  static void warning(dynamic message) {
    if (_log == null) getLogInstance();
    _log.w(message);
  }

  static void error(dynamic message) {
    if (_log == null) getLogInstance();
    _log.e(message);
  }
}