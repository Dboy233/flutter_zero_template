/// sync_project_brick.dart
///
/// 将输入目录（最小可运行应用，如 flutter_zero_app）同步为 Mason Brick 模板
/// （如 bricks/project/__brick__）。流程：
///   1) 拷贝输入目录到输出目录（输出目录内会生成与输入目录同名的子目录，整个目录连同自身目录名一起拷贝）；排除列表中的文件/文件夹/后缀不拷贝；清理文件夹列表中的文件夹保留空壳（内容不拷贝）；
///   2) 文件替换：用 replaceDir（默认 scripts/replace）中文件按【文件名】覆盖输出树中的同名文件（按文件名匹配，无需镜像目录层级；输出中无同名文件则跳过，不新增文件）；
///   3) 对拷贝后的所有文件内容做全文本替换（find -> replace）；
///   4) 对拷贝后的所有文件名、文件夹名做替换（重命名，find -> replace，目录优先于其内部实体）。
///
/// 纯 Dart 标准库实现，不依赖任何第三方包（仅 dart:io）。
///
/// 使用方式：
///   直接修改下方“可配置变量”区块，然后在 flutter_zero_template 目录下（或任意目录）执行：
///     dart run scripts/sync_project_brick.dart
///   路径相对于本脚本所在仓库根目录（scripts/ 的上一级）解析，因此无论从哪个目录运行都能正确找到 ../flutter_zero_app。
///
/// 命令行参数（可选，覆盖上方写死的变量，便于测试）：
///   --input=PATH           输入目录
///   --output=PATH          输出目录
///   --exclude=a,b,c        排除列表（逗号分隔）
///   --clean=a,b,c          清理文件夹列表（逗号分隔，目录保留空壳、内容排除）
///   --replace=PATH         用于覆盖同名文件的目录（默认 scripts/replace）
///   --content-find=TEXT    内容替换的查找文本
///   --content-replace=TEXT 内容替换的替换文本
///   --name-find=TEXT       文件名/目录名替换的查找文本
///   --name-replace=TEXT    文件名/目录名替换的替换文本
///   示例：
///     dart run scripts/sync_project_brick.dart --input=.t_src --output=.t_dst --exclude=.git,build
///
/// 说明：
///   - 排除列表支持三种写法：文件夹/文件名（如 .git、pubspec.lock），
///     带点的后缀（如 .dart），不带点的后缀（如 dart）。
///   - 清理文件夹列表（cleanDirs）按目录名匹配：目录本身保留，但其中所有
///     文件与子目录均不拷贝（仅生成空壳目录）。与 excludeList 的区别在于
///     excludeList 会连同目录一起排除，cleanDirs 仅清空目录内容。
///   - 内容替换会跳过无法以 UTF-8 解码的二进制文件，避免损坏。
///   - 文件名/文件夹名替换作用于文件与文件夹（含最外层目标目录名）。
///   - 文件替换步骤按文件名匹配覆盖输出树中的同名文件，replaceDir 的目录层级无需与输出树一致；输出树中无同名文件则跳过，不新增文件。

import 'dart:io';

import 'path_utils.dart';

void main(List<String> args) {
  // ===================== 可配置变量（直接修改此处） =====================
  // 1) 输入目录路径（将要被同步为模板的源工程，相对于仓库根目录）
  const inputDir = '../flutter_zero_app';
  // 2) 输出目录路径（Mason Brick 的 __brick__ 目录，相对于仓库根目录）
  const outputDir = 'bricks/project/__brick__';
  // 3) 排除列表：文件/文件夹名，或文件后缀名（支持 ".dart" 与 "dart" 两种写法）
  const excludeList = <String>[
    '.git',
    '.idea',
    'build',
    '.dart_tool',
    '.metadata',
    'pubspec.lock',
    '.iml',
    'android',
    'ios',
    'linux',
    'macos',
    'web',
    'windows',
    '.flutter-plugins-dependencies',
    'home',
    'settings',
    'gen'
    // 需要排除的二进制或无关文件可在此追加，例如：
    // '.png', 'png', '.jpg', '.keystore',
  ];
  // 内容全文本替换：find -> replace
  const contentFind = 'flutter_zero_app';
  const contentReplace = '{{name}}';
  // 文件名替换（重命名）：find -> replace
  const nameFind = 'flutter_zero_app';
  const nameReplace = '{{name}}';
  // 文件替换目录：拷贝完成后，用该目录中同名文件覆盖输出树中的文件（仅覆盖已存在者）
  const replaceDir = 'scripts/replace';
  // 5) 清理文件夹列表：文件夹本身拷贝，但其内容全部排除（只保留空壳目录）。
  //    与 excludeList 不同：excludeList 会连同文件夹一起排除；此处文件夹保留占位，
  //    仅清空其中内容。适用于开发阶段示例/演示目录（如 test），模板需要该目录
  //    但不需要里面的示例文件。按目录名（basename）匹配，命中任意层级同名目录。
  const cleanDirs = <String>[
    'test',
    // 需要保留空壳目录的示例/演示目录可在此追加，例如：
    // 'example', 'samples',
  ];
  // =====================================================================

  // 命令行参数覆盖（便于测试；未传则使用上方写死的默认值）
  // 一次性解析所有参数为 Map，后续直接取值，避免每次调用都遍历参数列表
  final argMap = _parseArgs(args);
  final aInput = argMap['input'] ?? inputDir;
  final aOutput = argMap['output'] ?? outputDir;
  final aExclude = argMap['exclude']
          ?.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      excludeList;
  final aReplace = argMap['replace'] ?? replaceDir;
  final aClean = argMap['clean']
          ?.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      cleanDirs;
  final aContentFind = argMap['content-find'] ?? contentFind;
  final aContentReplace = argMap['content-replace'] ?? contentReplace;
  final aNameFind = argMap['name-find'] ?? nameFind;
  final aNameReplace = argMap['name-replace'] ?? nameReplace;

  // 仓库根目录 = 本脚本所在目录（scripts/）的上一级，路径解析以此为基准，
  // 这样无论从哪个工作目录运行脚本，../flutter_zero_app 都能正确定位。
  final repoRoot = dirname(dirname(Platform.script.toFilePath()));

  final inputPath = resolve(repoRoot, aInput);
  final outputPath = resolve(repoRoot, aOutput);

  // 输入输出不能相同，避免清空自身
  if (normalize(inputPath) == normalize(outputPath)) {
    stderr.writeln('[错误] 输入目录与输出目录不能相同: $inputPath');
    exit(1);
  }

  final input = Directory(inputPath);
  if (!input.existsSync()) {
    stderr.writeln('[错误] 输入目录不存在: ${input.absolute.path}');
    exit(1);
  }

  // 输出目录（Mason Brick 的 __brick__），确保存在
  final output = Directory(outputPath);
  output.createSync(recursive: true);

  // 目标目录内创建子目录，目录名取输入目录名并应用文件名替换规则
  // （如 flutter_zero_app -> {{name}}），将整个输入目录（含自身目录名）拷贝进去
  final targetName = basename(input.path).replaceAll(aNameFind, aNameReplace);
  final target = Directory(join(output.path, targetName));

  // 防止清空自身：目标子目录不能等于输入目录
  if (normalize(target.path) == normalize(inputPath)) {
    stderr.writeln('[错误] 目标子目录与输入目录相同，将清空自身: ${target.path}');
    exit(1);
  }

  // 清空同名目标子目录，保证同步结果干净
  if (target.existsSync()) {
    target.deleteSync(recursive: true);
  }
  target.createSync(recursive: true);

  stdout.writeln(
    '[1/4] 拷贝 ${input.absolute.path}'
    ' -> ${target.absolute.path}',
  );
  stdout.writeln('      排除: ${aExclude.join(', ')}');
  stdout.writeln('      清理目录(保留空壳): ${aClean.join(', ')}');
  _copyTree(input, target, aExclude, aClean);

  final replacePath = resolve(repoRoot, aReplace);
  stdout.writeln('[2/4] 文件替换（用同名文件覆盖）: $replacePath');
  _applyFileOverrides(target, Directory(replacePath));

  stdout.writeln('[3/4] 内容替换: "$aContentFind" -> "$aContentReplace"');
  _replaceContent(target, aContentFind, aContentReplace);

  stdout.writeln('[4/4] 文件/目录重命名: "$aNameFind" -> "$aNameReplace"');
  _renameEntities(target, aNameFind, aNameReplace);

  stdout.writeln('完成。模板已同步到 ${target.absolute.path}');
}

/// 将命令行参数一次性解析为 key -> value 映射。
/// 仅遍历参数列表一遍，支持 `--name value` 与 `--name=value` 两种写法。
/// 解析后通过返回的 Map 直接取值，避免每次查找都重复遍历。
Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('--')) continue;
    final body = a.substring(2);
    final eq = body.indexOf('=');
    if (eq != -1) {
      // --name=value 写法
      final key = body.substring(0, eq);
      final value = body.substring(eq + 1);
      if (key.isNotEmpty) map[key] = value;
    } else {
      // --name value 写法：消耗下一个 token 作为 value
      if (i + 1 < args.length) {
        map[body] = args[i + 1];
        i++;
      }
    }
  }
  return map;
}

/// 用 replaceDir 中的文件按【文件名】覆盖输出树中的同名文件。
/// 按文件名（basename）匹配，因此 replace 目录无需镜像输出树的目录层级，
/// 平铺放置亦可（如 scripts/replace/app_router.dart 会覆盖输出树中任意
/// lib/router/app_router.dart）。输出树中无同名文件则跳过（不新增文件）。
/// 若同一文件名在输出树中出现多处，则全部覆盖。
void _applyFileOverrides(Directory output, Directory replaceDir) {
  if (!replaceDir.existsSync()) {
    stdout.writeln('      （replace 目录不存在，跳过）');
    return;
  }
  // 收集输出树所有文件，按下文件名索引
  final byBasename = <String, List<File>>{};
  for (final entity in output.listSync(recursive: true)) {
    if (entity is File) {
      final bn = basename(entity.path);
      byBasename.putIfAbsent(bn, () => []).add(entity);
    }
  }
  var count = 0;
  for (final entity in replaceDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final bn = basename(entity.path);
    final targets = byBasename[bn];
    if (targets == null || targets.isEmpty) {
      stdout.writeln('      （输出树中无同名文件，跳过: $bn）');
      continue;
    }
    final bytes = entity.readAsBytesSync();
    for (final t in targets) {
      t.writeAsBytesSync(bytes);
      count++;
      final rel = relative(t.path, output.path);
      stdout.writeln('      覆盖: $rel');
    }
  }
  if (count == 0) {
    stdout.writeln('      （无同名文件需覆盖）');
  }
}

/// 递归拷贝目录。
/// - [exclude]：匹配的文件/文件夹/后缀整项排除（含文件夹本身）。
/// - [cleanDirs]：文件夹本身保留，但其内容全部排除（只生成空壳目录）。
///   命中 [cleanDirs] 的目录仅创建空目录，不递归拷贝其中内容。
void _copyTree(
  Directory src,
  Directory dst,
  List<String> exclude,
  List<String> cleanDirs,
) {
  for (final entity in src.listSync(recursive: false)) {
    final name = basename(entity.path);
    if (isExcluded(name, extension(entity.path), exclude)) {
      continue;
    }
    if (entity is Link) {
      // 跳过符号链接，避免循环或跨盘拷贝
      continue;
    } else if (entity is Directory) {
      final newDir = Directory(join(dst.path, name));
      newDir.createSync(recursive: true);
      if (cleanDirs.contains(name)) {
        // 清理目录：仅保留空壳目录，跳过其中全部内容
        continue;
      }
      _copyTree(entity, newDir, exclude, cleanDirs);
    } else if (entity is File) {
      final newFile = File(join(dst.path, name));
      newFile.createSync(recursive: true);
      newFile.writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}

/// 对目录下所有文件内容做全文本替换（二进制文件解码失败时跳过）。
void _replaceContent(Directory dir, String find, String replace) {
  if (find.isEmpty) return;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    try {
      final text = entity.readAsStringSync();
      if (text.contains(find)) {
        entity.writeAsStringSync(text.replaceAll(find, replace));
      }
    } on FormatException {
      // 二进制文件，无法以 UTF-8 解码，跳过内容替换
    } catch (e) {
      stderr.writeln('[警告] 读取失败，跳过: ${entity.path} ($e)');
    }
  }
}

/// 对目录下所有文件名、文件夹名做替换（重命名）。
/// 从最深层的实体开始重命名，避免父目录先改名导致子路径失效。
void _renameEntities(Directory dir, String find, String replace) {
  if (find.isEmpty) return;
  final entities = dir.listSync(recursive: true);
  // 按路径长度降序排序，保证先处理最深层（子）再处理上层（父）
  entities.sort((a, b) => b.path.length.compareTo(a.path.length));
  for (final entity in entities) {
    final name = basename(entity.path);
    if (name.contains(find)) {
      final newName = name.replaceAll(find, replace);
      final newPath = join(dirname(entity.path), newName);
      if (FileSystemEntity.isDirectorySync(newPath) ||
          File(newPath).existsSync()) {
        stderr.writeln('[警告] 目标已存在，跳过: $newPath');
        continue;
      }
      entity.renameSync(newPath);
    }
  }
}
