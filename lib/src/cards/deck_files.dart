import 'dart:io';
import 'dart:typed_data';

import 'canon_codec.dart';
import 'card_image.dart';
import 'text_codec.dart';

/// Deck files on disk: the canon–mirror pairing rules of
/// `docs/design/deck-format.md` §6 (decision D0.5).
///
/// Canon files are authoritative. Each `X.ctd` has a generated mirror
/// `X.ct`. [checkDeckPaths] is the one implementation of the freshness and
/// round-trip rules; `deckconv check` and the MCP server both use it.

/// The extension of a canon file.
const String canonExtension = '.ctd';

/// The extension of a mirror file.
const String mirrorExtension = '.ct';

/// The mirror path that belongs to canon file [canonPath].
///
/// Throws a [FormatException] when [canonPath] has no name before its
/// extension.
String mirrorPathFor(String canonPath) {
  if (!canonPath.endsWith(canonExtension) ||
      canonPath.split(Platform.pathSeparator).last == canonExtension) {
    throw FormatException('not a named canon file: $canonPath');
  }
  return canonPath.substring(0, canonPath.length - canonExtension.length) +
      mirrorExtension;
}

/// The canon path that belongs to mirror file [mirrorPath].
String canonPathFor(String mirrorPath) =>
    mirrorPath.substring(0, mirrorPath.length - mirrorExtension.length) +
    canonExtension;

/// Writes to [path] through a sibling temporary file, then renames it into
/// place, so an interrupted write cannot leave a truncated deck file behind.
///
/// [write] receives the temporary [File] to write to. The CLI and the MCP
/// server both write every deck file through this function.
void writeAtomic(String path, void Function(File file) write) {
  final temp = File('$path.$pid.tmp');
  try {
    write(temp);
    temp.renameSync(path);
  } on Object {
    if (temp.existsSync()) {
      temp.deleteSync();
    }
    rethrow;
  }
}

/// Finds every file with [extension] under [paths], sorted.
///
/// A path that names a file is taken as given; a path that names a directory
/// is searched, and hidden directories such as `.git` are skipped below that
/// directory. The hidden-directory rule never applies to the named path
/// itself — a directory the caller gives directly is always searched, even
/// when it or one of its ancestors starts with a dot. Throws a
/// [FileSystemException] when a path does not exist.
List<String> findDeckFiles(Iterable<String> paths, String extension) {
  final found = <String>[];
  for (final path in paths) {
    final FileSystemEntityType type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.notFound) {
      throw FileSystemException('no such file or directory', path);
    }
    if (type == FileSystemEntityType.directory) {
      found.addAll(
        Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .map((File f) => f.path)
            .where(
              (String p) => p.endsWith(extension) && !_hiddenBelowRoot(path, p),
            ),
      );
    } else if (path.endsWith(extension)) {
      found.add(path);
    }
  }
  return found..sort();
}

/// The outcome of one check (spec §6).
enum DeckCheckStatus {
  /// The canon file round-trips and its mirror is fresh.
  ok,

  /// The mirror text of the canon file does not encode back to the same bytes.
  roundTripFailed,

  /// The canon file has no committed mirror.
  mirrorMissing,

  /// The committed mirror differs from the generated one.
  mirrorStale,

  /// A mirror file with no canon file beside it.
  orphanMirror,

  /// The canon file could not be read or decoded.
  unreadable,
}

/// One line of a check report.
final class DeckCheckResult {
  const DeckCheckResult({
    required this.path,
    required this.status,
    required this.message,
    this.mirrorPath,
  });

  /// The canon file that was checked, or the orphan mirror.
  final String path;

  /// The mirror that belongs to [path], when [path] is a canon file.
  final String? mirrorPath;

  final DeckCheckStatus status;

  /// A one-line explanation, for a report.
  final String message;

  bool get passed => status == DeckCheckStatus.ok;
}

/// Checks every canon and mirror file under [paths].
///
/// Each canon file must decode, must round-trip through its mirror text back
/// to the same bytes, and must have a fresh committed mirror. Each mirror file
/// must have a canon file beside it — a mirror addressed on its own, with a
/// healthy canon file next to it, is checked the same way its canon file
/// would be. Returns one result per file, canon files first. An empty result
/// means that no deck files were found; callers decide whether that is an
/// error. Throws a [FileSystemException] when a path in [paths] does not
/// exist.
List<DeckCheckResult> checkDeckPaths(Iterable<String> paths) {
  final List<String> pathList = paths.toList();
  final results = <DeckCheckResult>[];
  final checkedCanonPaths = <String>{};
  for (final String canonPath in findDeckFiles(pathList, canonExtension)) {
    results.add(checkCanonFile(canonPath));
    checkedCanonPaths.add(canonPath);
  }
  for (final String mirrorPath in findDeckFiles(pathList, mirrorExtension)) {
    final String canonPath = canonPathFor(mirrorPath);
    if (checkedCanonPaths.contains(canonPath)) {
      // Already reported through the canon-file pass above.
      continue;
    }
    if (!File(canonPath).existsSync()) {
      results.add(
        DeckCheckResult(
          path: mirrorPath,
          status: DeckCheckStatus.orphanMirror,
          message: '$mirrorPath: mirror without a canon file',
        ),
      );
      continue;
    }
    // The mirror was addressed directly (or found by a directory search
    // that did not separately match its canon file); its canon file exists,
    // so report the real status of the pair instead of staying silent.
    results.add(checkCanonFile(canonPath));
    checkedCanonPaths.add(canonPath);
  }
  return results;
}

/// Checks the single canon file [canonPath] and its mirror.
DeckCheckResult checkCanonFile(String canonPath) {
  String? mirrorPath;
  try {
    mirrorPath = mirrorPathFor(canonPath);
    final Uint8List bytes = File(canonPath).readAsBytesSync();
    final List<CardImage> deck = decodeCanon(bytes);
    final String text = deckToMirror(deck);
    if (!_bytesEqual(encodeCanon(mirrorToDeck(text)), bytes)) {
      return DeckCheckResult(
        path: canonPath,
        mirrorPath: mirrorPath,
        status: DeckCheckStatus.roundTripFailed,
        message:
            '$canonPath: mirror text does not round-trip to the same '
            'bytes',
      );
    }
    final mirror = File(mirrorPath);
    if (!mirror.existsSync()) {
      return DeckCheckResult(
        path: canonPath,
        mirrorPath: mirrorPath,
        status: DeckCheckStatus.mirrorMissing,
        message: '$canonPath: mirror $mirrorPath is missing',
      );
    }
    if (mirror.readAsStringSync() != text) {
      return DeckCheckResult(
        path: canonPath,
        mirrorPath: mirrorPath,
        status: DeckCheckStatus.mirrorStale,
        message: '$mirrorPath: stale mirror — regenerate with deckconv regen',
      );
    }
    return DeckCheckResult(
      path: canonPath,
      mirrorPath: mirrorPath,
      status: DeckCheckStatus.ok,
      message: 'OK: $canonPath',
    );
  } on Object catch (e) {
    return DeckCheckResult(
      path: canonPath,
      mirrorPath: mirrorPath,
      status: DeckCheckStatus.unreadable,
      message: '$canonPath: $e',
    );
  }
}

// Skips .git, .dart_tool, and the like when a directory is searched, but
// only for directory segments discovered below [root] — never for [root]
// itself, and never for an ancestor of [root] that happens to start with a
// dot (a clone checked out under a dot directory must still be searchable).
bool _hiddenBelowRoot(String root, String filePath) {
  var relative = filePath;
  if (relative.startsWith(root)) {
    relative = relative.substring(root.length);
  }
  final List<String> segments = relative
      .split(Platform.pathSeparator)
      .where((String s) => s.isNotEmpty)
      .toList();
  if (segments.isNotEmpty) {
    // The last segment is the file itself; only intervening directories can
    // hide it.
    segments.removeLast();
  }
  return segments.any(
    (String part) => part.length > 1 && part != '..' && part.startsWith('.'),
  );
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
