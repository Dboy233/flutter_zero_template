# Changelog

本文件记录 `flutter_zero_template` 的所有重要变更。格式参考 [Keep a Changelog](https://keepachangelog.com/)。

> 模板版本与 CLI 版本独立发布、互不绑定；二者之间的版本约束关系见文档「版本约束规则」（`flutter_zero_doc/docs/zh/versioning-rules.md`）。

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
