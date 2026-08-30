import 'package:{{package_name}}/core/network/base_repository.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 仓库。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} repository.
class {{#pascalCase}}{{name}}{{/pascalCase}}Repository extends BaseRepository {
  /// 创建仓库。
  ///
  /// Creates the repository.
  const {{#pascalCase}}{{name}}{{/pascalCase}}Repository({required super.dio});

}
