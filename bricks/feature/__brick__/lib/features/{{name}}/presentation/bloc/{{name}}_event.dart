part of '{{name}}_bloc.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 事件。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} events.
@freezed
abstract class {{#pascalCase}}{{name}}{{/pascalCase}}Event with _${{#pascalCase}}{{name}}{{/pascalCase}}Event {
  /// 编写你的事件：
  /// const factory {{#pascalCase}}{{name}}{{/pascalCase}}Event.add() = {{#pascalCase}}{{name}}{{/pascalCase}}Add;
}
