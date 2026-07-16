# data_sources（数据源目录）

本目录存放 `{{name}}` 功能的**数据源实现**，负责与外部环境（远程 API / 本地存储 / 设备能力等）直接交互。

## 职责

- 封装具体的外部读写细节：HTTP 请求（基于 `DioClient`）、本地数据库、SharedPreferences、平台通道等。
- 将原始响应转换为本功能的数据模型（`../models` 中的 DTO），或在失败时抛出 `AppException` 交由上层处理。
- 只做"取数"，不包含业务规则、状态管理或 UI 逻辑。

## 存放内容

- 远程数据源：`{{name}}_remote_data_source.dart`（封装 Dio 调用）。
- 本地数据源：`{{name}}_local_data_source.dart`（封装本地持久化）。
- 可按来源分子目录（`remote/`、`local/`）进一步归类。
- 接口与实现分离：建议定义抽象类（如 `{{Name}}RemoteDataSource`），便于在测试中用 mock 替换。

## 约定

- 数据源仅被同层 `../repositories` 的仓储依赖；**不要**被 `bloc/` 或 `pages/` 直接引用（依赖方向：bloc → repository → data_source）。
- 跨功能复用的数据源应上移到 `core/data`，而非留在本目录。
- 不在本目录放业务逻辑判断，业务编排交给 repository。
