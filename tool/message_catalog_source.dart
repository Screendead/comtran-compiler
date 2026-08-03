/// Parses the transcribed J 90.04.01 error-message listing into (id,
/// text) pairs — the single parsing routine shared by the catalog
/// generator (`tool/generate_message_catalog.dart`) and the golden
/// byte-comparison test (decision D9.5, oracle 3).
///
/// The conversion (`comtran-manuals/J28-6169/90.04-error-messages.md`)
/// holds the listing in fenced blocks, interrupted by page markers and
/// the repeated `DATE 01/31/62  TIME` printer head. A message row is
/// `NNN,00` right-justified, the CODE column's `0`, then the text;
/// continuation lines keep their printed indentation and belong to the
/// preceding message (message 186 continues across a page break).
library;

/// One parsed message: the id (e.g. `62,00`) and the printed text with
/// continuation lines joined by `\n`, indentation preserved.
typedef SourceMessage = ({String id, String text});

final RegExp _row = RegExp(r'^ {0,5}(\d{1,3},\d\d) +0 {4}(.*)$');

const Set<String> _skip = {
  '',
  'DATE 01/31/62  TIME',
  'THE FOLLOWING ERRORS WERE DETECTED DURING COMPILATION-',
  'NUMBER   CODE   MESSAGE',
  'SEVERITY LIMIT WAS NOT REACHED',
};

/// Parses the conversion's [markdown] into the 210 messages, in order.
List<SourceMessage> parseCatalogSource(String markdown) {
  final messages = <SourceMessage>[];
  String? id;
  StringBuffer? text;
  var inFence = false;

  void flush() {
    if (id != null) {
      messages.add((id: id!, text: text.toString()));
      id = null;
      text = null;
    }
  }

  for (final String raw in markdown.split('\n')) {
    final String line = raw.trimRight();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence || _skip.contains(line)) {
      continue;
    }
    final RegExpMatch? row = _row.firstMatch(line);
    if (row != null) {
      flush();
      id = row[1];
      text = StringBuffer(row[2]!);
      continue;
    }
    if (text != null && line.startsWith('        ')) {
      text!.write('\n$line');
      continue;
    }
    throw FormatException('unrecognized listing line: "$line"');
  }
  flush();
  return messages;
}
