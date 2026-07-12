import 'package:freezed_annotation/freezed_annotation.dart';

part '{{name}}_model.freezed.dart';
part '{{name}}_model.g.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 数据模型。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} data model.
@freezed
abstract class {{#pascalCase}}{{name}}{{/pascalCase}}Model with _${{#pascalCase}}{{name}}{{/pascalCase}}Model {
  /// 创建模型。
  ///
  /// Creates the model.
  const factory {{#pascalCase}}{{name}}{{/pascalCase}}Model() = _{{#pascalCase}}{{name}}{{/pascalCase}}Model;

  /// 从 JSON 反序列化。
  ///
  /// Deserializes from JSON.
  factory {{#pascalCase}}{{name}}{{/pascalCase}}Model.fromJson(Map<String, dynamic> json) =>
      _${{#pascalCase}}{{name}}{{/pascalCase}}ModelFromJson(json);
}
