# Changelog

本文件记录 `flutter_zero_template` 的所有重要变更。格式参考 [Keep a Changelog](https://keepachangelog.com/)。

> 模板版本与 CLI 版本独立发布、互不绑定；二者之间的版本约束关系见文档「版本约束规则」（`flutter_zero_doc/docs/zh/versioning-rules.md`）。

## [2.0.0] - 2026-08-19

### Added
- 新增 `fluzer.yaml`，作为原 `flutter_zero_config.yaml` 的更名文件（详见 Removed），结构精简为仅保留 `version` 与 `template_name`。
- `BaseRepository` 从 `core/storage` 迁移至 `core/network`，并极简化为仅持有 `Dio` 实例，不再提供任何响应解析与异常处理助手，将决定权交还开发者。
- 新增 `lib/core/network/interceptors/` 子目录，将原根目录下的 `auth_interceptor.dart` 与 `locale_interceptor.dart` 归入其中。
- 新增 `lib/core/network/test_repository.dart` 示例仓储，演示 `mixin XxxRepositoryMixin on BaseRepository` + 私有请求方法 + 公开业务方法的零封装仓储编写范式。
- 新增多环境入口 `main_dev.dart`（开发）与 `main_staging.dart`（测试），各环境 baseUrl 独立配置，配合 `flutter run -t lib/main_dev.dart` 切换。
- feature brick 新增 `data/models/README.md`，取代原先生成的示例 Model 文件，仅说明模型约定。

### Changed
- `main.dart` 改为手动注册 `Dio` 单例（注入 `AuthInterceptor` / `LocaleInterceptor`），不再依赖被移除的 `DioClient`；并补充多环境入口切换说明。
- 依赖注入 `core/di/injection.dart` 删除 `_registerNetworkLayer()`（原注册 `DioClient`），改为由各环境 `main` 手动注册 `Dio`。
- `core/result/result.dart`：`Failure.exception` 字段类型由 `AppException` 改为 `Exception`；`runToResult` 重命名为 `runCatching`。
- `core/effect/ui_effect.dart`：`ExceptionToToast` 扩展作用对象由 `AppException` 改为 `Exception`；`ToastEffect.code` 注释移除 `AppErrorCodes` 引用。
- `core/effect/effect_handle/default_toast_effect_handle.dart`：移除整段基于 `error400~504` 与解析错误的 `_handleErrorCode` 映射逻辑；Toast 文案解析优先级统一为 `message → l10nCode → code → Unknown`，兜底走 `l.unknownError(code)`。
- `core/bloc/bloc_error_handler_mixin.dart`：移除 `ErrorHandler` / `handleError` / `runWithErrorHandling`；`runCatching` 内部异常包装改为 `e is Exception ? Failure(e) : Failure(Exception(...))`；示例 `runToResult` 改为 `runCatching`。
- `core/bloc/bloc_cancel_token_mixin.dart`：示例异常处理写法同步更新为 `e is Exception ? e : Exception(...)`。
- `core/data/shares_repositories.dart`：示例由 `getIt<DioClient>()` 改为 `getIt<Dio>()`。
- `core/data/repositories/README.md` 与 `core/data/models/README.md`：示例/说明同步移除 `DioClient`、`parseList` / `parseSingle` 引用，改用 `super.dio`。
- feature brick `{{name}}_module.dart`：仓储注册由 `getIt<DioClient>()` 改为 `getIt<Dio>()`。
- feature brick `{{name}}_repository.dart`：`BaseRepository` 导入路径由 `core/storage` 改为 `core/network`；`super.client` 改为 `super.dio`，并移除附带的示例方法（由 README 取代）。
- `lib/l10n/app_zh.arb` / `app_en.arb`：大幅精简错误码文案，移除 `error400~504`、`parseError`、`noConnection`、`requestTimeout` 等 20+ 条，仅保留 `unknownError`。

### Removed
- 删除整套异常体系：`core/error/app_exception.dart`（`AppException` 及 `ServerException` / `ParseException` 等子类）、`core/error/error_handler.dart`、`core/error/app_error_codes.dart`、`core/error/server_message_extractor.dart`。框架改为零异常封装，网络异常原样外抛，由 BLoC 经 `Exception → ToastEffect` 上报。
- 删除 `core/network/dio_client.dart`：`DioClient` 封装类（含 `get/post/put/delete/uploadFile`），改由开发者直接使用 `dio` 实例。
- 删除 `core/constants/api_constants.dart`：`ApiConstants.baseUrl`，baseUrl 改由各环境 `main` 自行配置。
- 删除 feature brick 生成时附带的示例 `{{name}}_model.dart`。
- 删除 `flutter_zero_config.yaml`，由 `fluzer.yaml` 取代（详见 Added）。

## [1.0.1] - 2026-08-01

### Added
- `flutter_zero_config.yaml` 新增 `minCliVersion` 字段（当前为 `"1.1.0"`）。该字段声明此模板版本所依赖的最低 CLI 版本，供 `fluzer new` 与 `fluzer gen-l10n` 的版本门禁逻辑消费，用于判定当前 CLI 是否支持本项目模板。

### Changed
- 更新 `lib/core/effect/effect_handle/default_toast_effect_handle.dart` 的文档注释：当 `ToastEffect.l10nCode` 未被默认处理器处理时，说明可运行 `fluzer gen-l10n` 自动生成 `L10nCode` 值对象、`L10nToastType` 扩展与 `L10nToastEffectHelper`，将 `l10nCode` 映射为本地化文案并在业务 handle 中展示。
- 因文档引用了 `fluzer gen-l10n` 命令（由 CLI 1.1.0 引入），本模板版本的 `minCliVersion` 相应提升至 `1.1.0`。

## [1.0.0]

> 首个发布版本（初始日期未在仓库中记录）。

### Added
- `flutter_zero` 模板首个发布版本，包含 `project` 与 `feature` 两类 Mason brick，提供 MVI-BLoC 架构骨架、Effect 系统、依赖注入与示例。
