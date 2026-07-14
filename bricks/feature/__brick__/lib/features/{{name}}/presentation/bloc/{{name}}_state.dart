part of '{{name}}_bloc.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 状态。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} state.
@freezed
abstract class {{#pascalCase}}{{name}}{{/pascalCase}}State with _${{#pascalCase}}{{name}}{{/pascalCase}}State {
  /// 创建初始状态。
  ///
  /// Initial state.
  const factory {{#pascalCase}}{{name}}{{/pascalCase}}State() =
      _{{#pascalCase}}{{name}}{{/pascalCase}}State;
}
