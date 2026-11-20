/// Manual titles the site quotes as the conversions give them. Rule E2
/// outranks D5 for a quotation, and web-copy.md names the F28-8043 title as
/// the one case this exception exists for.
const List<String> quotedTitles = <String>[
  'General Information Manual — IBM Commercial Translator',
];

/// [line] with each quoted title removed.
String unquoted(String line) => quotedTitles.fold(
  line,
  (String text, String title) => text.replaceAll(title, ''),
);
