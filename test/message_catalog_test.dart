import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

import '../tool/message_catalog_source.dart';

void main() {
  final List<SourceMessage> source = parseCatalogSource(
    File('comtran-manuals/J28-6169/90.04-error-messages.md').readAsStringSync(),
  );

  test('the transcription parses to 210 messages, ids 0,00-209,00', () {
    expect(source, hasLength(210));
    for (var i = 0; i < source.length; i++) {
      expect(source[i].id, '$i,00');
    }
  });

  test('the catalog equals the transcription byte for byte (D9.5)', () {
    expect(messageCatalog, hasLength(210));
    for (final SourceMessage message in source) {
      final Message? stored = messageCatalog[message.id];
      expect(stored, isNotNull, reason: message.id);
      if (message.id == '187,00') {
        continue; // The one documented exception, checked below.
      }
      expect(stored!.text, message.text, reason: message.id);
    }
  });

  test('message 187 carries the D9.6 truncation, and only it', () {
    // The 1962 printout ran message 187's continuation into message
    // 196's text (a print defect, scan-confirmed); the stored text ends
    // after EACH WITH and does not reproduce the run-on (decision D9.6).
    final Message stored = messageCatalog['187,00']!;
    final SourceMessage printed = source.singleWhere(
      (SourceMessage m) => m.id == '187,00',
    );
    expect(stored.text, endsWith('EACH WITH'));
    expect(printed.text, startsWith(stored.text));
    expect(
      printed.text.substring(stored.text.length),
      ' ILLEGAL SENTENCE STRUCTURE NOTHING DONE.',
    );
  });

  test('the M1 message constants match their catalog rows', () {
    const List<Message> m1 = [
      msgFileCardLacksName,
      msgNumericLengthExceeded,
      msgIncorrectNumericForm,
      msgPeriodAssumed,
      msgCondCardLacksName,
      msgPictorialTooLong,
      msgIllegalCharacterReplaced,
      msgIllegalEnvironmentType,
      msgConstantTooLong,
      msgLiteralTooLong,
      msgSecondQuoteMissing,
      msgLiteralAcrossCards,
      msgFixedFieldOnContinuation,
      msgIllegalMode,
      msgIllegalJustification,
      msgDataNameLacksLevel,
    ];
    for (final Message message in m1) {
      expect(
        messageCatalog[message.number]?.text,
        message.text,
        reason: message.number,
      );
    }
  });

  test('the D9.15 reserved ids are present with their texts', () {
    // Messages 85, 135, 136, 137, 140 are unreachable by construction;
    // their ids and texts stay reserved (decision D9.15). Message 0 is
    // the fallback for an id with no text.
    for (final String id in [
      '85,00', '135,00', '136,00', '137,00', //
      '140,00',
    ]) {
      expect(messageCatalog[id], isNotNull, reason: id);
    }
    expect(messageCatalog['0,00']!.text, 'ERROR MESSAGE NOT YET IN FILE.');
  });
}
