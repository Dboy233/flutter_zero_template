# 共享数据模型（Shared Models）

跨多个 feature 共享的数据模型（DTO）放在本目录。

- **何时上移**：某模型被 2 个及以上 feature 直接消费时，从 `features/<name>/data/models/` 提到这里，避免 feature 互引。仅单 feature 使用的模型留在原处。
- **约定**：用 `freezed` + `json_serializable`；文件名 `lower_snake_case` 以 `_model` 结尾；纯数据结构（DTO），不含业务逻辑。

示例：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({required int id, required String name}) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

> 对应架构文档「跨模块数据共享」：共享结构（Model）上提到这里，共享访问能力（Repository）上提到 `core/data/repositories/`。
