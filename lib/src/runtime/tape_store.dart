/// Where a run's tape images live: one image per unit, named for the
/// UNIT1 of the `*FILE` card that mounts it (M5-3).
///
/// The machine reads and writes images through this interface alone, so
/// a browser can run a program over images it holds in memory, and
/// `comtranc --run` over a directory of `.tap` files.
library;

/// The images of one run, keyed by unit.
abstract interface class TapeStore {
  /// The image on [unit], or `null` when the store holds none.
  List<int>? read(String unit);

  /// Replaces the image on [unit] with [bytes].
  void write(String unit, List<int> bytes);

  /// Adds [bytes] to the end of the image on [unit].
  void append(String unit, List<int> bytes);

  /// Where the image on [unit] lives, in the words a fault prints.
  String where(String unit);
}

/// A store that holds every image in memory.
final class MemoryTapes implements TapeStore {
  /// A store that starts with a copy of [images].
  MemoryTapes([Map<String, List<int>> images = const {}])
    : _images = {
        for (final MapEntry<String, List<int>> image in images.entries)
          image.key: <int>[...image.value],
      };

  final Map<String, List<int>> _images;

  @override
  List<int>? read(String unit) => _images[unit];

  @override
  void write(String unit, List<int> bytes) {
    _images[unit] = <int>[...bytes];
  }

  @override
  void append(String unit, List<int> bytes) {
    (_images[unit] ??= <int>[]).addAll(bytes);
  }

  @override
  String where(String unit) => '$unit.tap';
}
