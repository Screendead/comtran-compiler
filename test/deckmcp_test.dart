import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

/// A minimal MCP client: line-delimited JSON-RPC 2.0 over a subprocess.
///
/// When [roots] is given, the client declares the `roots` capability and
/// answers the server's `roots/list` request with it, so the server's path
/// confinement (MCP-6) allows paths under any of them. With no [roots], the
/// client declares no roots capability at all, matching a client that does
/// not support the feature.
class _McpClient {
  _McpClient(this._process, this._roots) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_receive);
    _process.stderr.transform(utf8.decoder).listen(stderrText.write);
  }

  static Future<_McpClient> start({List<String>? roots}) async => _McpClient(
    await Process.start(Platform.resolvedExecutable, [
      'run',
      'comtran:deckmcp',
    ]),
    roots,
  );

  final Process _process;
  final List<String>? _roots;
  final StringBuffer stderrText = StringBuffer();
  final Map<int, Completer<Map<String, Object?>>> _pending = {};
  int _nextId = 1;

  void _receive(String line) {
    if (line.trim().isEmpty) {
      return;
    }
    final Object? message = jsonDecode(line);
    if (message is! Map<String, Object?>) {
      return;
    }
    if (message['method'] == 'roots/list') {
      _send({
        'jsonrpc': '2.0',
        'id': message['id'],
        'result': {
          'roots': [
            for (final String root in _roots ?? const <String>[])
              {'uri': Uri.file(root).toString()},
          ],
        },
      });
      return;
    }
    final Object? id = message['id'];
    if (id is int) {
      _pending.remove(id)?.complete(message);
    }
  }

  void _send(Map<String, Object?> message) =>
      _process.stdin.writeln(jsonEncode(message));

  /// Sends [method] and waits for its response envelope.
  Future<Map<String, Object?>> request(
    String method, [
    Map<String, Object?>? params,
  ]) {
    final int id = _nextId++;
    final completer = Completer<Map<String, Object?>>();
    _pending[id] = completer;
    _send({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': ?params});
    return completer.future.timeout(const Duration(seconds: 60));
  }

  /// Sends a notification, which has no response.
  void notify(String method) => _send({'jsonrpc': '2.0', 'method': method});

  /// Completes the handshake: `initialize` then `notifications/initialized`.
  Future<Map<String, Object?>> initialize() async {
    final Map<String, Object?> response = await request('initialize', {
      'protocolVersion': '2025-06-18',
      'capabilities': <String, Object?>{
        if (_roots != null) 'roots': <String, Object?>{},
      },
      'clientInfo': {'name': 'deckmcp_test', 'version': '1.0.0'},
    });
    expect(response['error'], isNull, reason: '$stderrText');
    notify('notifications/initialized');
    return response['result']! as Map<String, Object?>;
  }

  /// Calls tool [name] and returns its `CallToolResult`.
  Future<Map<String, Object?>> call(
    String name,
    Map<String, Object?> arguments,
  ) async {
    final Map<String, Object?> response = await request('tools/call', {
      'name': name,
      'arguments': arguments,
    });
    expect(response['error'], isNull, reason: '$response');
    return response['result']! as Map<String, Object?>;
  }

  Future<void> close() async {
    await _process.stdin.close();
    _process.kill();
    await _process.exitCode;
  }
}

Map<String, Object?> _content(Map<String, Object?> result) =>
    result['structuredContent']! as Map<String, Object?>;

Map<String, Object?> _errorOf(Map<String, Object?> result) {
  expect(result['isError'], isTrue, reason: '$result');
  return _content(result)['error']! as Map<String, Object?>;
}

void main() {
  late _McpClient client;
  late Map<String, Object?> initializeResult;
  late Directory dir;
  late String canonPath;
  late String mirrorPath;

  // Card 1 is a glyph card, card 2 punches a group mark and an illegal
  // two-zone column, card 3 is blank.
  const sample = 'HELLO\n! 1:12-5-8 80:12-11\n\n';

  setUpAll(() async {
    // Cover every temp directory setUp creates, plus the repository root, so
    // the shared client can read the committed payroll fixture too.
    client = await _McpClient.start(
      roots: [Directory.systemTemp.path, Directory.current.path],
    );
    initializeResult = await client.initialize();
  });

  tearDownAll(() => client.close());

  setUp(() {
    dir = Directory.systemTemp.createTempSync('deckmcp_test');
    canonPath = '${dir.path}/a.ctdeck';
    mirrorPath = '${dir.path}/a.deck';
    final List<CardImage> deck = mirrorToDeck(sample);
    File(canonPath).writeAsBytesSync(encodeCanon(deck));
    File(mirrorPath).writeAsStringSync(deckToMirror(deck));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('handshake', () {
    test('initialize names the server and offers tools', () {
      expect(initializeResult['protocolVersion'], '2025-06-18');
      final serverInfo =
          initializeResult['serverInfo']! as Map<String, Object?>;
      expect(serverInfo['name'], 'comtran-decks');
      expect(serverInfo['version'], comtranVersion);
      final capabilities =
          initializeResult['capabilities']! as Map<String, Object?>;
      expect(capabilities.containsKey('tools'), isTrue);
      expect(initializeResult['instructions'], contains('Never hand-edit'));
    });

    test('tools/list gives every tool with a schema', () async {
      final Map<String, Object?> response = await client.request('tools/list');
      final tools =
          (response['result']! as Map<String, Object?>)['tools']!
              as List<Object?>;
      final names = <String>[
        for (final Object? tool in tools)
          (tool! as Map<String, Object?>)['name']! as String,
      ];
      expect(names, [
        'deck_read',
        'deck_write',
        'deck_edit_cards',
        'deck_card',
        'card_code_info',
        'deck_check',
      ]);
      for (final tool in tools) {
        final entry = tool! as Map<String, Object?>;
        expect(entry['description'], isNotEmpty);
        expect(
          (entry['inputSchema']! as Map<String, Object?>)['type'],
          'object',
        );
        expect(
          (entry['inputSchema']!
              as Map<String, Object?>)['additionalProperties'],
          isFalse,
          reason: '${entry['name']}',
        );
        expect(
          (entry['outputSchema']! as Map<String, Object?>)['type'],
          'object',
          reason: '${entry['name']}',
        );
      }
    });

    test('read-only tools are annotated read-only, deck_write and '
        'deck_edit_cards are not', () async {
      final Map<String, Object?> response = await client.request('tools/list');
      final tools =
          (response['result']! as Map<String, Object?>)['tools']!
              as List<Object?>;
      final byName = <String, Map<String, Object?>>{
        for (final Object? tool in tools)
          (tool! as Map<String, Object?>)['name']! as String:
              tool as Map<String, Object?>,
      };
      for (final name in [
        'deck_read',
        'deck_card',
        'card_code_info',
        'deck_check',
      ]) {
        final annotations =
            byName[name]!['annotations']! as Map<String, Object?>;
        expect(annotations['readOnlyHint'], isTrue, reason: name);
      }
      final writeAnnotations =
          byName['deck_write']!['annotations']! as Map<String, Object?>;
      expect(writeAnnotations['destructiveHint'], isTrue);
      expect(writeAnnotations['idempotentHint'], isTrue);
      final editAnnotations =
          byName['deck_edit_cards']!['annotations']! as Map<String, Object?>;
      expect(editAnnotations['destructiveHint'], isTrue);
    });
  });

  group('deck_read', () {
    test('reports the card count and the mirror text', () async {
      final Map<String, Object?> result = await client.call('deck_read', {
        'path': canonPath,
      });
      expect(result['isError'], isNot(isTrue));
      final Map<String, Object?> json = _content(result);
      expect(json['card_count'], 3);
      expect(json['mirror'], sample);
      expect(json['mirror_path'], mirrorPath);
      expect(json['mirror_status'], 'fresh');
      expect(json.containsKey('cards'), isFalse);
      final content = result['content']! as List<Object?>;
      expect(
        (content.first! as Map<String, Object?>)['text'],
        contains('"card_count": 3'),
      );
    });

    test('reports a stale mirror', () async {
      File(mirrorPath).writeAsStringSync('TAMPERED\n');
      final Map<String, Object?> json = _content(
        await client.call('deck_read', {'path': canonPath}),
      );
      expect(json['mirror_status'], 'stale');
    });

    test('include_cards gives the structured form of a range', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_read', {
          'path': canonPath,
          'include_cards': true,
          'start_card': 2,
          'max_cards': 1,
        }),
      );
      // The full mirror text would duplicate the structured form, so it is
      // omitted once include_cards is set (MCP-1).
      expect(json.containsKey('mirror'), isFalse);
      expect(json['cards_returned'], 1);
      expect(json['next_start_card'], 3);
      final cards = json['cards']! as List<Object?>;
      expect(cards, hasLength(1));
      final card = cards.single! as Map<String, Object?>;
      expect(card['card_index'], 2);
      expect(card['form'], 'punch');
      final columns = card['columns']! as List<Object?>;
      expect(columns, hasLength(2));
      final first = columns.first! as Map<String, Object?>;
      expect(first['column'], 1);
      expect(first['card_code'], '12-5-8');
      expect(first['bcd_octal'], '37');
      expect(first['name'], 'group mark');
      final second = columns.last! as Map<String, Object?>;
      expect(second['card_code'], '12-11');
      expect(second['readable'], isFalse);
      expect(second['bcd_octal'], isNull);
    });

    test('include_cards reports a null next_start_card at the end', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_read', {
          'path': canonPath,
          'include_cards': true,
        }),
      );
      expect(json['cards_returned'], 3);
      expect(json['next_start_card'], isNull);
    });

    test(
      'include_cards defaults to a bounded page and pages a long deck',
      () async {
        // Matches defaultMaxCards in deck_tools.dart. Not imported directly:
        // deck_tools.dart is an implementation detail behind the tools, not
        // part of the public package API.
        const defaultPage = 25;
        final Map<String, Object?> json = _content(
          await client.call('deck_read', {
            'path': '${Directory.current.path}/tests/90.05-payroll.ctdeck',
            'include_cards': true,
          }),
        );
        expect(json['card_count'], 293);
        expect(json['cards_returned'], defaultPage);
        expect(json['next_start_card'], defaultPage + 1);
        expect((json['cards']! as List<Object?>).length, defaultPage);
      },
    );

    test('rejects max_cards above the schema maximum', () async {
      final Map<String, Object?> result = await client.call('deck_read', {
        'path': canonPath,
        'include_cards': true,
        'max_cards': 1000,
      });
      expect(result['isError'], isTrue);
      expect(result.containsKey('structuredContent'), isFalse);
    });

    test('rejects a start_card below one', () async {
      // The schema's minimum: 1 rejects this before readDeck's own
      // start_card < 1 check ever runs, so the failure is a plain-text
      // schema-validation error, not a structured DeckToolException.
      final Map<String, Object?> result = await client.call('deck_read', {
        'path': canonPath,
        'include_cards': true,
        'start_card': 0,
      });
      expect(result['isError'], isTrue);
      expect(result.containsKey('structuredContent'), isFalse);
    });

    test('rejects a max_cards below one', () async {
      final Map<String, Object?> result = await client.call('deck_read', {
        'path': canonPath,
        'include_cards': true,
        'max_cards': 0,
      });
      expect(result['isError'], isTrue);
      expect(result.containsKey('structuredContent'), isFalse);
    });

    test(
      'include_cards on an empty deck returns no cards, not an error',
      () async {
        final emptyPath = '${dir.path}/empty.ctdeck';
        await client.call('deck_write', {'path': emptyPath, 'mirror': ''});
        final Map<String, Object?> json = _content(
          await client.call('deck_read', {
            'path': emptyPath,
            'include_cards': true,
          }),
        );
        expect(json['card_count'], 0);
        expect(json['cards'], isEmpty);
        expect(json['cards_returned'], 0);
        expect(json['next_start_card'], isNull);
      },
    );

    test('rejects a start_card past the end of a non-empty deck', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_read', {
          'path': canonPath,
          'include_cards': true,
          'start_card': 4,
        }),
      );
      expect(error['kind'], 'out_of_range');
      expect(error['message'], contains('past the last card'));
    });

    test('clamps max_cards larger than the cards remaining', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_read', {
          'path': canonPath,
          'include_cards': true,
          'start_card': 2,
          'max_cards': 100,
        }),
      );
      expect(json['cards_returned'], 2);
      expect(json['next_start_card'], isNull);
      expect((json['cards']! as List<Object?>).length, 2);
    });

    test('rejects a missing file', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_read', {'path': '${dir.path}/none.ctdeck'}),
      );
      expect(error['kind'], 'not_found');
      expect(error['message'], contains('none.ctdeck'));
    });

    test('rejects a path that is not a canon file', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_read', {'path': mirrorPath}),
      );
      expect(error['kind'], 'bad_extension');
    });

    test('rejects a file that is not canon', () async {
      final bad = '${dir.path}/bad.ctdeck';
      File(bad).writeAsBytesSync([1, 2, 3]);
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_read', {'path': bad}),
      );
      expect(error['kind'], 'format');
      expect(error['message'], contains('header'));
    });

    test('rejects a missing required argument', () async {
      final Map<String, Object?> result = await client.call('deck_read', {});
      expect(result['isError'], isTrue);
    });
  });

  group('deck_write', () {
    test('writes the canon file and regenerates the mirror', () async {
      final path = '${dir.path}/b.ctdeck';
      const text = 'MOVE A TO B.\n! 5:0-2-8\n';
      final Map<String, Object?> json = _content(
        await client.call('deck_write', {'path': path, 'mirror': text}),
      );
      expect(json['card_count'], 2);
      expect(json['canon_bytes'], 12 + 120 * 2);
      expect(json['mirror'], text);
      expect(File('${dir.path}/b.deck').readAsStringSync(), text);
      expect(decodeCanon(File(path).readAsBytesSync()), mirrorToDeck(text));

      final Map<String, Object?> check = _content(
        await client.call('deck_check', {
          'paths': <Object?>[path],
        }),
      );
      expect(check['ok'], isTrue);
    });

    test('overwrites a stale mirror so the pair stays fresh', () async {
      File(mirrorPath).writeAsStringSync('TAMPERED\n');
      await client.call('deck_write', {'path': canonPath, 'mirror': sample});
      expect(File(mirrorPath).readAsStringSync(), sample);
    });

    test(
      'rejects text that is not in normal form and writes nothing',
      () async {
        final path = '${dir.path}/c.ctdeck';
        final Map<String, Object?> error = _errorOf(
          await client.call('deck_write', {
            'path': path,
            'mirror': 'TRAILING SPACE \n',
          }),
        );
        expect(error['kind'], 'format');
        expect(error['message'], contains('card 1'));
        expect(error['message'], contains('normal form'));
        expect(File(path).existsSync(), isFalse);
        expect(File('${dir.path}/c.deck').existsSync(), isFalse);
      },
    );

    test('rejects a glyph outside the source set', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_write', {
          'path': '${dir.path}/d.ctdeck',
          'mirror': 'A%B\n',
        }),
      );
      expect(error['kind'], 'format');
      expect(error['message'], contains('column 2'));
      expect(File('${dir.path}/d.ctdeck').existsSync(), isFalse);
    });

    test('rejects text with no final newline', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_write', {
          'path': '${dir.path}/e.ctdeck',
          'mirror': 'HELLO',
        }),
      );
      expect(error['kind'], 'format');
      expect(error['message'], contains('newline'));
    });

    test('rejects a target that is not a canon path', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_write', {
          'path': '${dir.path}/f.deck',
          'mirror': 'HELLO\n',
        }),
      );
      expect(error['kind'], 'bad_extension');
      expect(File('${dir.path}/f.deck').existsSync(), isFalse);
    });

    test('rejects a missing directory', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_write', {
          'path': '${dir.path}/nowhere/g.ctdeck',
          'mirror': 'HELLO\n',
        }),
      );
      expect(error['kind'], 'not_found');
    });

    test('accepts expected_mirror when it matches and writes', () async {
      await client.call('deck_write', {
        'path': canonPath,
        'mirror': 'CHANGED\n',
        'expected_mirror': sample,
      });
      expect(File(mirrorPath).readAsStringSync(), 'CHANGED\n');
    });

    test(
      'rejects expected_mirror that no longer matches and writes nothing',
      () async {
        File(mirrorPath).writeAsStringSync('SOMEONE ELSE\n');
        final Map<String, Object?> error = _errorOf(
          await client.call('deck_write', {
            'path': canonPath,
            'mirror': 'MINE\n',
            'expected_mirror': sample,
          }),
        );
        expect(error['kind'], 'conflict');
        expect(File(mirrorPath).readAsStringSync(), 'SOMEONE ELSE\n');
      },
    );
  });

  group('deck_edit_cards', () {
    test('inserts cards without touching the rest of the deck', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_edit_cards', {
          'path': canonPath,
          'start_card': 1,
          'insert_lines': ['NEW'],
        }),
      );
      expect(json['card_count'], 4);
      expect(json['deleted_count'], 0);
      expect(json['inserted_count'], 1);
      final String mirror = File(mirrorPath).readAsStringSync();
      expect(mirror, startsWith('NEW\n'));
      expect(mirror, endsWith(sample));
    });

    test('deletes cards when insert_lines is empty', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_edit_cards', {
          'path': canonPath,
          'start_card': 3,
          'delete_count': 1,
        }),
      );
      expect(json['card_count'], 2);
      expect(json['deleted_count'], 1);
      expect(json['inserted_count'], 0);
      expect(
        File(mirrorPath).readAsStringSync(),
        'HELLO\n! 1:12-5-8 80:12-11\n',
      );
    });

    test('replaces a range in the middle of the deck', () async {
      await client.call('deck_edit_cards', {
        'path': canonPath,
        'start_card': 2,
        'delete_count': 1,
        'insert_lines': ['REPLACED'],
      });
      expect(File(mirrorPath).readAsStringSync(), 'HELLO\nREPLACED\n\n');
    });

    test('appends when start_card is one past the last card', () async {
      await client.call('deck_edit_cards', {
        'path': canonPath,
        'start_card': 4,
        'insert_lines': ['LAST'],
      });
      expect(File(mirrorPath).readAsStringSync(), '${sample}LAST\n');
    });

    test('rejects a delete range past the end of the deck', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_edit_cards', {
          'path': canonPath,
          'start_card': 2,
          'delete_count': 5,
        }),
      );
      expect(error['kind'], 'out_of_range');
    });

    test('rejects a start_card past card_count + 1', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_edit_cards', {
          'path': canonPath,
          'start_card': 10,
        }),
      );
      expect(error['kind'], 'out_of_range');
    });

    test('rejects malformed insert_lines and writes nothing', () async {
      final String fresh = File(mirrorPath).readAsStringSync();
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_edit_cards', {
          'path': canonPath,
          'start_card': 1,
          'insert_lines': ['TRAILING SPACE '],
        }),
      );
      expect(error['kind'], 'format');
      expect(File(mirrorPath).readAsStringSync(), fresh);
    });

    test('rejects expected_mirror that no longer matches', () async {
      File(mirrorPath).writeAsStringSync('SOMEONE ELSE\n');
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_edit_cards', {
          'path': canonPath,
          'start_card': 1,
          'insert_lines': ['NEW'],
          'expected_mirror': sample,
        }),
      );
      expect(error['kind'], 'conflict');
    });
  });

  group('deck_card', () {
    test('describes a glyph card', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_card', {'path': canonPath, 'card_index': 1}),
      );
      expect(json['card_count'], 3);
      expect(json['form'], 'glyph');
      expect(json['glyph_line'], 'HELLO');
      expect(json['mirror_line'], 'HELLO');
      expect(json['punch_notation'], '! 1:12-8 2:12-5 3:11-3 4:11-3 5:11-6');
      expect(json['punched_columns'], 5);
      final columns = json['columns']! as List<Object?>;
      final first = columns.first! as Map<String, Object?>;
      expect(first['glyph'], 'H');
      expect(first['card_code'], '12-8');
      expect(first['bcd_octal'], '30');
      expect(first['name'], 'letter H');
      expect(first['punch_rows'], ['12', '8']);
    });

    test('describes a blank card', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_card', {'path': canonPath, 'card_index': 3}),
      );
      expect(json['blank'], isTrue);
      expect(json['form'], 'glyph');
      expect(json['mirror_line'], '');
      expect(json['punch_notation'], isNull);
      expect(json['columns'], isEmpty);
    });

    test('rejects an index past the end of the deck', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_card', {'path': canonPath, 'card_index': 4}),
      );
      expect(error['kind'], 'out_of_range');
      expect(error['message'], contains('1..3'));
    });

    test('rejects an index below one', () async {
      final Map<String, Object?> result = await client.call('deck_card', {
        'path': canonPath,
        'card_index': 0,
      });
      expect(result['isError'], isTrue);
    });
  });

  group('card_code_info', () {
    test('looks a glyph up', () async {
      final Map<String, Object?> json = _content(
        await client.call('card_code_info', {'glyph': 'A'}),
      );
      expect(json['bcd_octal'], '21');
      expect(json['bcd_decimal'], 17);
      expect(json['canonical_card_code'], '12-1');
      expect(json['canonical_punch_rows'], ['12', '1']);
      expect(json['glyph'], 'A');
      expect(json['name'], 'letter A');
      expect(json['attested'], isTrue);
    });

    test('looks the blank up', () async {
      final Map<String, Object?> json = _content(
        await client.call('card_code_info', {'glyph': ' '}),
      );
      expect(json['bcd_octal'], '60');
      expect(json['name'], 'blank');
      expect(json['canonical_card_code'], '');
      expect(json['canonical_punch_rows'], isEmpty);
    });

    test('looks a card code up', () async {
      final Map<String, Object?> json = _content(
        await client.call('card_code_info', {'card_code': '12-5-8'}),
      );
      expect(json['bcd_octal'], '37');
      expect(json['name'], 'group mark');
      expect(json['machine_special'], 'group mark');
      expect(json['glyph'], isNull);
      expect(json['is_canonical'], isTrue);
    });

    test('marks a legal but non-canonical card code', () async {
      final Map<String, Object?> json = _content(
        await client.call('card_code_info', {'card_code': '12-2-8'}),
      );
      expect(json['bcd_octal'], '32');
      expect(json['name'], 'plus zero');
      expect(json['canonical_card_code'], '12-0');
      expect(json['is_canonical'], isFalse);
    });

    test('marks a combination with no readout', () async {
      final Map<String, Object?> json = _content(
        await client.call('card_code_info', {'card_code': '12-7-8'}),
      );
      expect(json['readable'], isFalse);
      expect(json['bcd_octal'], isNull);
      expect(json['note'], contains('no BCD readout'));
    });

    test('looks a BCD code up', () async {
      final Map<String, Object?> json = _content(
        await client.call('card_code_info', {'bcd_octal': '35'}),
      );
      expect(json['canonical_card_code'], isNull);
      expect(json['attested'], isFalse);
      expect(json['glyph'], isNull);
    });

    test('rejects a glyph outside the source set', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('card_code_info', {'glyph': '%'}),
      );
      expect(error['kind'], 'unknown_glyph');
    });

    test('rejects a malformed card code', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('card_code_info', {'card_code': '8-12'}),
      );
      expect(error['kind'], 'bad_card_code');
    });

    test('rejects a BCD code outside the table', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('card_code_info', {'bcd_octal': '99'}),
      );
      expect(error['kind'], 'invalid_argument');
    });

    test('rejects no query and two queries', () async {
      expect(
        _errorOf(await client.call('card_code_info', {}))['kind'],
        'invalid_argument',
      );
      expect(
        _errorOf(
          await client.call('card_code_info', {
            'glyph': 'A',
            'bcd_octal': '21',
          }),
        )['kind'],
        'invalid_argument',
      );
    });

    test('rejects an omitted arguments field instead of crashing', () async {
      // card_code_info has no required property, so schema validation lets
      // an entirely absent "arguments" field through; the handler used to
      // read request.arguments! and crash with a Dart stack trace (MCP-4).
      final Map<String, Object?> response = await client.request('tools/call', {
        'name': 'card_code_info',
      });
      expect(response['error'], isNull, reason: '$response');
      final result = response['result']! as Map<String, Object?>;
      final Map<String, Object?> error = _errorOf(result);
      expect(error['kind'], 'invalid_argument');
      final text =
          ((result['content']! as List<Object?>).first!
                  as Map<String, Object?>)['text']!
              as String;
      expect(text, isNot(contains('Null check operator')));
    });

    test(
      'rejects a two-octal-digit lookalike that is not valid octal',
      () async {
        // int.tryParse(radix: 8) would accept "021" and "+21"; the spec gives
        // BCD codes as exactly two octal digits, 00 to 77 (MCP-14).
        for (final bad in ['021', '+21', '8', '99', '1']) {
          final Map<String, Object?> error = _errorOf(
            await client.call('card_code_info', {'bcd_octal': bad}),
          );
          expect(error['kind'], 'invalid_argument', reason: bad);
        }
      },
    );

    test('rejects an unknown property', () async {
      final Map<String, Object?> result = await client.call('card_code_info', {
        'glyph': 'A',
        'bogus': 1,
      });
      expect(result['isError'], isTrue);
    });
  });

  group('deck_check', () {
    test('passes a fresh pair addressed by its mirror path', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_check', {
          'paths': <Object?>[mirrorPath],
        }),
      );
      expect(json['ok'], isTrue);
      final results = json['results']! as List<Object?>;
      final entry = results.single! as Map<String, Object?>;
      expect(entry['status'], 'ok');
      expect(entry['path'], canonPath);
    });

    test('reports a stale pair addressed by its mirror path', () async {
      File(mirrorPath).writeAsStringSync('TAMPERED\n');
      final Map<String, Object?> json = _content(
        await client.call('deck_check', {
          'paths': <Object?>[mirrorPath],
        }),
      );
      expect(json['ok'], isFalse);
      final entry =
          (json['results']! as List<Object?>).single! as Map<String, Object?>;
      expect(entry['status'], 'mirror_stale');
    });

    test('aggregates several files: ok, stale, and orphan mirror, canon '
        'files first (TSTT-1)', () async {
      final bCanon = '${dir.path}/b.ctdeck';
      final bMirror = '${dir.path}/b.deck';
      final List<CardImage> bDeck = mirrorToDeck('STALE\n');
      File(bCanon).writeAsBytesSync(encodeCanon(bDeck));
      File(bMirror).writeAsStringSync('TAMPERED\n');
      final orphanMirror = '${dir.path}/c.deck';
      File(orphanMirror).writeAsStringSync('ORPHAN\n');

      final Map<String, Object?> json = _content(
        await client.call('deck_check', {
          'paths': <Object?>[dir.path],
        }),
      );
      expect(json['ok'], isFalse);
      expect(json['checked'], 3);
      expect(json['failure_count'], 2);
      final results = json['results']! as List<Object?>;
      final statuses = <String?>[
        for (final Object? r in results)
          (r! as Map<String, Object?>)['status'] as String?,
      ];
      // Canon files sort before the orphan mirror (deck_files.dart's
      // documented ordering), and within the canon files, a.ctdeck sorts
      // before b.ctdeck.
      expect(statuses, ['ok', 'mirror_stale', 'orphan_mirror']);
      expect((results[0]! as Map<String, Object?>)['path'], canonPath);
      expect((results[1]! as Map<String, Object?>)['path'], bCanon);
      expect((results[2]! as Map<String, Object?>)['path'], orphanMirror);
    });

    test('passes a fresh pair', () async {
      final Map<String, Object?> json = _content(
        await client.call('deck_check', {
          'paths': <Object?>[dir.path],
        }),
      );
      expect(json['ok'], isTrue);
      expect(json['failure_count'], 0);
      final results = json['results']! as List<Object?>;
      final entry = results.single! as Map<String, Object?>;
      expect(entry['status'], 'ok');
      expect(entry['path'], canonPath);
      expect(entry['mirror_path'], mirrorPath);
    });

    test('fails a stale mirror', () async {
      File(mirrorPath).writeAsStringSync('TAMPERED\n');
      final Map<String, Object?> json = _content(
        await client.call('deck_check', {
          'paths': <Object?>[dir.path],
        }),
      );
      expect(json['ok'], isFalse);
      expect(json['failure_count'], 1);
      final results = json['results']! as List<Object?>;
      final entry = results.single! as Map<String, Object?>;
      expect(entry['status'], 'mirror_stale');
      expect(entry['message'], contains('stale mirror'));
    });

    test('fails an orphan mirror', () async {
      File(canonPath).deleteSync();
      final Map<String, Object?> json = _content(
        await client.call('deck_check', {
          'paths': <Object?>[dir.path],
        }),
      );
      expect(json['ok'], isFalse);
      final entry =
          (json['results']! as List<Object?>).single! as Map<String, Object?>;
      expect(entry['status'], 'orphan_mirror');
    });

    test('fails a corrupt canon file', () async {
      File(canonPath).writeAsBytesSync([1, 2, 3]);
      final Map<String, Object?> json = _content(
        await client.call('deck_check', {
          'paths': <Object?>[canonPath],
        }),
      );
      expect(json['ok'], isFalse);
      final entry =
          (json['results']! as List<Object?>).single! as Map<String, Object?>;
      expect(entry['status'], 'unreadable');
    });

    test('rejects a path that does not exist', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_check', {
          'paths': <Object?>['${dir.path}/nowhere'],
        }),
      );
      expect(error['kind'], 'not_found');
    });

    test('rejects a directory with no deck files', () async {
      final empty = Directory('${dir.path}/empty')..createSync();
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_check', {
          'paths': <Object?>[empty.path],
        }),
      );
      expect(error['kind'], 'not_found');
      expect(error['message'], contains('no canon or mirror files'));
    });

    test('rejects an empty path list', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_check', {'paths': <Object?>[]}),
      );
      expect(error['kind'], 'invalid_argument');
    });
  });

  group('path confinement', () {
    test('rejects a path outside every declared root', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_read', {
          'path': '/mcp-confinement-test-should-not-exist.ctdeck',
        }),
      );
      expect(error['kind'], 'forbidden_path');
    });

    test('deck_check rejects a forbidden path among several', () async {
      final Map<String, Object?> error = _errorOf(
        await client.call('deck_check', {
          'paths': <Object?>[
            dir.path,
            '/mcp-confinement-test-should-not-exist',
          ],
        }),
      );
      expect(error['kind'], 'forbidden_path');
    });

    test(
      'a client that declares no roots falls back to the working directory',
      () async {
        final _McpClient plain = await _McpClient.start();
        await plain.initialize();
        try {
          // The committed payroll deck is inside the repository root, which
          // is the server's working directory when no roots are declared.
          final Map<String, Object?> ok = _content(
            await plain.call('deck_read', {
              'path': 'tests/90.05-payroll.ctdeck',
            }),
          );
          expect(ok['card_count'], 293);

          // A path outside the working directory is still rejected.
          final Map<String, Object?> error = _errorOf(
            await plain.call('deck_read', {'path': canonPath}),
          );
          expect(error['kind'], 'forbidden_path');
        } finally {
          await plain.close();
        }
      },
    );
  });

  test('an unknown tool is an error, not a crash', () async {
    final Map<String, Object?> result = await client.call('no_such_tool', {});
    expect(result['isError'], isTrue);
  });
}
