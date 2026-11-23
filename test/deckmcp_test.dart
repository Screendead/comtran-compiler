import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:comtran/comtran.dart';
import 'package:test/test.dart';

/// A minimal MCP client: line-delimited JSON-RPC 2.0 over a subprocess.
///
/// When [_roots] is given, the client declares the `roots` capability and
/// answers the server's `roots/list` request with it, so the server's path
/// confinement (MCP-6) allows paths under any of them. With no [_roots], the
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
  late Directory dir;
  late Directory shared;
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
    await client.initialize();
    shared = Directory.systemTemp.createTempSync('deckmcp_shared');
    File('${shared.path}/bad.ctd').writeAsBytesSync([1, 2, 3]);
    Directory('${shared.path}/empty').createSync();
  });

  tearDownAll(() async {
    await client.close();
    shared.deleteSync(recursive: true);
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('deckmcp_test');
    canonPath = '${dir.path}/a.ctd';
    mirrorPath = '${dir.path}/a.ct';
    final List<CardImage> deck = mirrorToDeck(sample);
    File(canonPath).writeAsBytesSync(encodeCanon(deck));
    File(mirrorPath).writeAsStringSync(deckToMirror(deck));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('handshake', () {
    test('tools/list gives every tool with a schema and its hints', () async {
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
        final annotations = entry['annotations']! as Map<String, Object?>;
        final Object? name = entry['name'];
        final bool writes = name == 'deck_write' || name == 'deck_edit_cards';
        expect(
          annotations[writes ? 'destructiveHint' : 'readOnlyHint'],
          isTrue,
          reason: '$name',
        );
        if (name == 'deck_write') {
          expect(annotations['idempotentHint'], isTrue);
        }
      }
    });
  });

  group('deck_read', () {
    test(
      'reports the card count, the mirror and whether it is fresh',
      () async {
        final Map<String, Object?> json = _content(
          await client.call('deck_read', {'path': canonPath}),
        );
        expect(json['card_count'], 3);
        expect(json['mirror'], sample);
        expect(json['mirror_path'], mirrorPath);
        expect(json['mirror_status'], 'fresh');
        File(mirrorPath).writeAsStringSync('TAMPERED\n');
        expect(
          _content(
            await client.call('deck_read', {'path': canonPath}),
          )['mirror_status'],
          'stale',
        );
      },
    );

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

    test(
      'include_cards on an empty deck returns no cards, not an error',
      () async {
        final emptyPath = '${dir.path}/empty.ctd';
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
  });

  group('deck_write', () {
    test('writes the canon file and regenerates the mirror', () async {
      final path = '${dir.path}/b.ctd';
      const text = 'MOVE A TO B.\n! 5:0-2-8\n';
      final Map<String, Object?> json = _content(
        await client.call('deck_write', {'path': path, 'mirror': text}),
      );
      expect(json['card_count'], 2);
      expect(json['canon_bytes'], 12 + 120 * 2);
      expect(json['mirror'], text);
      expect(File('${dir.path}/b.ct').readAsStringSync(), text);
      expect(decodeCanon(File(path).readAsBytesSync()), mirrorToDeck(text));

      final Map<String, Object?> check = _content(
        await client.call('deck_check', {
          'paths': <Object?>[path],
        }),
      );
      expect(check['ok'], isTrue);
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
    for (final (String name, Map<String, Object?> edit, String mirror) in [
      (
        'inserts cards without touching the rest of the deck',
        {
          'start_card': 1,
          'insert_lines': ['NEW'],
        },
        'NEW\n$sample',
      ),
      (
        'deletes cards when insert_lines is empty',
        {'start_card': 3, 'delete_count': 1},
        'HELLO\n! 1:12-5-8 80:12-11\n',
      ),
      (
        'replaces a range in the middle of the deck',
        {
          'start_card': 2,
          'delete_count': 1,
          'insert_lines': ['REPLACED'],
        },
        'HELLO\nREPLACED\n\n',
      ),
      (
        'appends when start_card is one past the last card',
        {
          'start_card': 4,
          'insert_lines': ['LAST'],
        },
        '${sample}LAST\n',
      ),
    ]) {
      test(name, () async {
        final Map<String, Object?> json = _content(
          await client.call('deck_edit_cards', {'path': canonPath, ...edit}),
        );
        expect(json['card_count'], mirrorToDeck(mirror).length);
        expect(File(mirrorPath).readAsStringSync(), mirror);
      });
    }

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
  });

  group('card_code_info', () {
    // The character facts themselves are char_code_test.dart's; these rows
    // hold each query form to the right entry.
    for (final (Map<String, Object?> query, Map<String, Object?> want) in [
      (
        {'glyph': 'A'},
        {'bcd_octal': '21', 'canonical_card_code': '12-1', 'name': 'letter A'},
      ),
      (
        {'glyph': ' '},
        {'bcd_octal': '60', 'canonical_card_code': '', 'name': 'blank'},
      ),
      (
        {'card_code': '12-5-8'},
        {'bcd_octal': '37', 'glyph': null, 'is_canonical': true},
      ),
      (
        {'card_code': '12-2-8'},
        {
          'bcd_octal': '32',
          'canonical_card_code': '12-0',
          'is_canonical': false,
        },
      ),
      ({'card_code': '12-7-8'}, {'readable': false, 'bcd_octal': null}),
      ({'bcd_octal': '35'}, {'canonical_card_code': null, 'attested': false}),
    ]) {
      test('looks up $query', () async {
        final Map<String, Object?> json = _content(
          await client.call('card_code_info', query),
        );
        want.forEach((String key, Object? value) {
          expect(json[key], value, reason: key);
        });
      });
    }

    test('rejects an omitted arguments field instead of crashing', () async {
      // card_code_info has no required property, so schema validation lets
      // an absent "arguments" field through to the handler (MCP-4).
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

    test('aggregates several files: ok, stale, and orphan mirror, canon '
        'files first (TSTT-1)', () async {
      final bCanon = '${dir.path}/b.ctd';
      final bMirror = '${dir.path}/b.ct';
      final List<CardImage> bDeck = mirrorToDeck('STALE\n');
      File(bCanon).writeAsBytesSync(encodeCanon(bDeck));
      File(bMirror).writeAsStringSync('TAMPERED\n');
      final orphanMirror = '${dir.path}/c.ct';
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
      // documented ordering), and within the canon files, a.ctd sorts
      // before b.ctd.
      expect(statuses, ['ok', 'mirror_stale', 'orphan_mirror']);
      expect((results[0]! as Map<String, Object?>)['path'], canonPath);
      expect((results[1]! as Map<String, Object?>)['path'], bCanon);
      expect(
        (results[1]! as Map<String, Object?>)['message'],
        contains('stale mirror'),
      );
      expect((results[2]! as Map<String, Object?>)['path'], orphanMirror);
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
  });

  group('path confinement', () {
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
              'path': 'test/fixtures/90.05-payroll.ctd',
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

  group('the schema refuses', () {
    for (final (String name, String tool, Map<String, Object?> args) in [
      // The schema minimum stops this before readDeck's own check runs.
      (
        'a start_card below one',
        'deck_read',
        {'include_cards': true, 'start_card': 0},
      ),
      (
        'a max_cards below one',
        'deck_read',
        {'include_cards': true, 'max_cards': 0},
      ),
      ('a missing required argument', 'deck_read', {'path': null}),
      ('a card_index below one', 'deck_card', {'card_index': 0}),
      ('an unknown property', 'card_code_info', {'glyph': 'A', 'bogus': 1}),
    ]) {
      test(name, () async {
        final Map<String, Object?> result = await client.call(
          tool,
          {if (tool.startsWith('deck_')) 'path': canonPath, ...args}
            ..removeWhere((String key, Object? value) => value == null),
        );
        expect(result['isError'], isTrue);
        expect(result.containsKey('structuredContent'), isFalse);
      });
    }
  });

  group('a tool refuses', () {
    for (final (
          String name,
          String tool,
          Map<String, Object?> Function() args,
          String kind,
          String? message,
        )
        in [
          (
            'a start_card past the end of a non-empty deck',
            'deck_read',
            () => {'path': canonPath, 'include_cards': true, 'start_card': 4},
            'out_of_range',
            'past the last card',
          ),
          (
            'a missing file',
            'deck_read',
            () => {'path': '${dir.path}/none.ctd'},
            'not_found',
            'none.ctd',
          ),
          (
            'a path that is not a canon file',
            'deck_read',
            () => {'path': mirrorPath},
            'bad_extension',
            null,
          ),
          (
            'a file that is not canon',
            'deck_read',
            () => {'path': '${shared.path}/bad.ctd'},
            'format',
            'header',
          ),
          (
            'mirror text that is not in normal form',
            'deck_write',
            () => {
              'path': '${dir.path}/new.ctd',
              'mirror': 'TRAILING SPACE \n',
            },
            'format',
            'card 1 is not in normal form',
          ),
          (
            'a glyph outside the source set',
            'deck_write',
            () => {'path': '${dir.path}/new.ctd', 'mirror': 'A%B\n'},
            'format',
            'column 2',
          ),
          (
            'mirror text with no final newline',
            'deck_write',
            () => {'path': '${dir.path}/new.ctd', 'mirror': 'HELLO'},
            'format',
            'newline',
          ),
          (
            'a write target that is not a canon path',
            'deck_write',
            () => {'path': '${dir.path}/new.ct', 'mirror': 'HELLO\n'},
            'bad_extension',
            null,
          ),
          (
            'a write into a missing directory',
            'deck_write',
            () => {'path': '${dir.path}/nowhere/new.ctd', 'mirror': 'HELLO\n'},
            'not_found',
            null,
          ),
          (
            'a delete range past the end of the deck',
            'deck_edit_cards',
            () => {'path': canonPath, 'start_card': 2, 'delete_count': 5},
            'out_of_range',
            null,
          ),
          (
            'a start_card past card_count + 1',
            'deck_edit_cards',
            () => {'path': canonPath, 'start_card': 10},
            'out_of_range',
            null,
          ),
          (
            'a card_index past the end of the deck',
            'deck_card',
            () => {'path': canonPath, 'card_index': 4},
            'out_of_range',
            '1..3',
          ),
          (
            'a glyph outside the source set, looked up',
            'card_code_info',
            () => {'glyph': '%'},
            'unknown_glyph',
            null,
          ),
          (
            'a malformed card code',
            'card_code_info',
            () => {'card_code': '8-12'},
            'bad_card_code',
            null,
          ),
          ('no query', 'card_code_info', () => {}, 'invalid_argument', null),
          (
            'two queries',
            'card_code_info',
            () => {'glyph': 'A', 'bcd_octal': '21'},
            'invalid_argument',
            null,
          ),
          // A BCD code is exactly two octal digits, 00 to 77 (MCP-14).
          for (final bad in ['99', '021', '+21', '8', '1'])
            (
              'the BCD code $bad',
              'card_code_info',
              () => {'bcd_octal': bad},
              'invalid_argument',
              null,
            ),
          (
            'a path that does not exist',
            'deck_check',
            () => {
              'paths': ['${dir.path}/nowhere'],
            },
            'not_found',
            null,
          ),
          (
            'a directory with no deck files',
            'deck_check',
            () => {
              'paths': ['${shared.path}/empty'],
            },
            'not_found',
            'no canon or mirror files',
          ),
          (
            'an empty path list',
            'deck_check',
            () => {'paths': <Object?>[]},
            'invalid_argument',
            null,
          ),
          (
            'a path outside every declared root',
            'deck_read',
            () => {'path': '/mcp-confinement-test-should-not-exist.ctd'},
            'forbidden_path',
            null,
          ),
          (
            'a forbidden path among several',
            'deck_check',
            () => {
              'paths': [dir.path, '/mcp-confinement-test-should-not-exist'],
            },
            'forbidden_path',
            null,
          ),
        ]) {
      test(name, () async {
        final Map<String, Object?> error = _errorOf(
          await client.call(tool, args()),
        );
        expect(error['kind'], kind);
        if (message != null) {
          expect(error['message'], contains(message));
        }
        expect(File(mirrorPath).readAsStringSync(), sample);
        expect(File('${dir.path}/new.ctd').existsSync(), isFalse);
        expect(File('${dir.path}/new.ct').existsSync(), isFalse);
      });
    }
  });
}
