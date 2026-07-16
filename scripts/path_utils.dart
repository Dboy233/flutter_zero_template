// ignore_for_file: unused_element

/// 将相对路径 relative 解析到 base（绝对目录）下，并正确折叠 ".." / "."。
String resolve(String base, String relative) {
  final rel = normalize(relative);
  final target = rel.startsWith('/') || isAbsDrive(rel)
      ? rel
      : join(base, rel);
  return normalizeDots(target);
}

/// 折叠路径中的 "." 与 ".."，保留绝对路径的前导 "/" 或盘符。
String normalizeDots(String p) {
  final isAbs = p.startsWith('/') || isAbsDrive(p);
  final drive = isAbsDrive(p) ? p.substring(0, 2) : '';
  final body = drive.isNotEmpty
      ? p.substring(2)
      : (p.startsWith('/') ? p.substring(1) : p);
  final stack = <String>[];
  for (final seg in body.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (stack.isNotEmpty && stack.last != '..') {
        stack.removeLast();
      } else if (!isAbs) {
        stack.add('..');
      }
      // 绝对路径的 ".." 到达根后不再上移
    } else {
      stack.add(seg);
    }
  }
  final joined = stack.join('/');
  if (isAbs) {
    if (drive.isNotEmpty) return '$drive/$joined';
    return '/$joined';
  }
  return joined.isEmpty ? '.' : joined;
}

bool isAbsDrive(String p) => RegExp(r'^[a-zA-Z]:').hasMatch(p);

String normalize(String p) => p.replaceAll('\\', '/');

String basename(String p) {
  p = normalize(p);
  final idx = p.lastIndexOf('/');
  return idx < 0 ? p : p.substring(idx + 1);
}

String dirname(String p) {
  p = normalize(p);
  final idx = p.lastIndexOf('/');
  return idx < 0 ? '.' : p.substring(0, idx);
}

String extension(String p) {
  final base = basename(p);
  final idx = base.lastIndexOf('.');
  if (idx <= 0) return ''; // 无扩展名，或为点文件（如 .gitignore）
  return base.substring(idx); // 含点，如 ".dart"
}

String join(String a, String b) {
  a = normalize(a);
  b = normalize(b);
  if (a.isEmpty) return b;
  if (a.endsWith('/')) return '$a$b';
  return '$a/$b';
}

/// 判断相对路径 [relativePath] 是否被 [excludePaths] 中的路径条目排除。
///
/// [excludePaths] 条目为以输入根目录为起点的相对路径（如 `.git`、
/// `lib/features/home`、`lib/core/data/models/post_model.dart`）。
/// 命中条件：路径完全相等，或以其为前缀的子孙路径（如 `lib/features/home/x.dart`）。
bool isExcludedByPath(String relativePath, List<String> excludePaths) {
  for (final e in excludePaths) {
    final ne = normalize(e);
    if (ne.isEmpty) continue;
    if (relativePath == ne || relativePath.startsWith('$ne/')) return true;
  }
  return false;
}

/// 判断文件扩展名 [ext]（含点，如 `.dart`）是否被 [excludeSuffixes] 中的后缀排除。
///
/// 后缀条目以 `.` 开头（如 `.dart`、`.freezed.dart`、`.png`）：
/// - 扩展名完全相等时命中，如 `.dart` 命中 `foo.dart`；
/// - 复合后缀按其结尾命中，如 `.dart` 也会命中 `foo.freezed.dart`
///   （因扩展名以 `.dart` 结尾），而 `.freezed.dart` 仅命中扩展名
///   恰好为 `.freezed.dart` 的文件。
/// 目录可传空扩展名字符串，自然不匹配。
bool isExcludedBySuffix(String ext, List<String> excludeSuffixes) {
  if (ext.isEmpty) return false;
  for (final s in excludeSuffixes) {
    final ns = normalize(s);
    if (ns.isEmpty) continue;
    if (ns == ext || ext.endsWith(ns)) return true;
  }
  return false;
}

/// 计算 path 相对于 from 的相对路径（两者已规范化、同盘符）。
/// 仅用于 replace 目录与输出目录同仓库前缀一致的情形。
String relative(String path, String from) {
  path = normalize(path);
  from = normalize(from);
  if (from.endsWith('/')) from = from.substring(0, from.length - 1);
  if (path == from) return '.';
  if (path.startsWith('$from/')) return path.substring(from.length + 1);
  // 前缀不一致时退回绝对路径（本场景不会出现）
  return path;
}
