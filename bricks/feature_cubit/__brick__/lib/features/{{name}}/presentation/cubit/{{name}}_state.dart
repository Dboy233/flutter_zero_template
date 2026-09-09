part of '{{name}}_cubit.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 状态。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} state.
@freezed
abstract class {{#pascalCase}}{{name}}{{/pascalCase}}State with _${{#pascalCase}}{{name}}{{/pascalCase}}State {

  /// 创建初始状态。
  ///
  /// Initial state.
  const factory(/*{
    String? name,
    Default(0) int age,
  }*/) = _{{#pascalCase}}{{name}}{{/pascalCase}}State;

}
