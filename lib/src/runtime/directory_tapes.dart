/// The tape store of `comtranc --run --tapes=DIR`: unit `U` is the
/// file `DIR/U.tap` (M5-3).
library;

import 'dart:io';

import 'tape_store.dart';

/// A store over one host directory, read and written as the run goes.
final class DirectoryTapes implements TapeStore {
  DirectoryTapes(this.directory);

  final Directory directory;

  File _file(String unit) => File(where(unit));

  @override
  List<int>? read(String unit) {
    final File file = _file(unit);
    return file.existsSync() ? file.readAsBytesSync() : null;
  }

  @override
  void write(String unit, List<int> bytes) {
    _file(unit).writeAsBytesSync(bytes);
  }

  @override
  void append(String unit, List<int> bytes) {
    _file(unit).writeAsBytesSync(bytes, mode: FileMode.append);
  }

  @override
  String where(String unit) => '${directory.path}/$unit.tap';
}
