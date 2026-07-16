/// 服务端错误消息提取器。
///
/// 不同后端返回的错误字段名不统一：有的用 `message`，有的用 `error`、
/// `errorMsg` 或 `msg`。本类把"如何从响应体中取出错误文案"与
/// [ErrorHandler] 解耦，让使用本项目的开发者可以动态替换取值逻辑，
/// 而不必修改核心错误封装。
///
/// 默认按 [keys] 顺序取第一个非空字符串。开发者可直接修改 [keys] 列表，
/// 或在构造 [ErrorHandler] 时传入自定义实例：
///
/// ```dart
/// final handler = ErrorHandler(
///   serverMessageExtractor: ServerMessageExtractor(['msg', 'errorMessage']),
/// );
/// ```
///
/// Server error message extractor.
///
/// Backends disagree on the error field name — `message`, `error`,
/// `errorMsg`, `msg`. This class decouples "how to read the error
/// text from a response body" from [ErrorHandler] so developers can swap
/// the extraction logic without touching the core error handling.
///
/// It tries the first non-empty string among [keys] in order. Developers can
/// edit the [keys] list directly.
class ServerMessageExtractor {
  /// 创建一个提取器。
  ///
  /// [keys] 候选字段名，**顺序即优先级**，默认为
  /// `['message', 'error', 'errorMsg', 'msg']`。
  ///
  /// Creates an extractor. [keys] are tried in order; defaults to
  /// `['message', 'error', 'errorMsg', 'msg']`.
  ServerMessageExtractor([List<String>? keys])
      : keys = keys ?? ['message', 'error', 'errorMsg', 'msg'];

  /// 候选字段名（按优先级排序）。
  ///
  /// Candidate field names (in priority order).
  List<String> keys;

  /// 从响应体 [data] 中提取第一条可用的错误文案；找不到返回 `null`。
  ///
  /// Extracts the first usable error text from [data]; returns `null` if none.
  String? extract(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}
