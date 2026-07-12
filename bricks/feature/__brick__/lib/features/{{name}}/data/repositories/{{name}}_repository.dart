import 'package:{{package_name}}/core/data/base_repository.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 仓库。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} repository.
class {{#pascalCase}}{{name}}{{/pascalCase}}Repository extends BaseRepository {
  /// 创建仓库。
  ///
  /// Creates the repository.
  const {{#pascalCase}}{{name}}{{/pascalCase}}Repository({required super.client});

  // 请求列表示例 / Fetch list example:
  // Future<List<{{#pascalCase}}{{name}}{{/pascalCase}}Model>> fetch{{#pascalCase}}{{name}}{{/pascalCase}}s() async {
  //   final response = await client.get<List<dynamic>>('/{{name}}s');
  //   return parseList(response, {{#pascalCase}}{{name}}{{/pascalCase}}Model.fromJson);
  // }

  // 请求单条示例 / Fetch single example:
  // Future<{{#pascalCase}}{{name}}{{/pascalCase}}Model?> fetch{{#pascalCase}}{{name}}{{/pascalCase}}() async {
  //   final response = await client.get<Map<String, dynamic>>(
  //     '/{{name}}s/1',
  //   );
  //   return parseSingle(response, {{#pascalCase}}{{name}}{{/pascalCase}}Model.fromJson);
  // }
}
