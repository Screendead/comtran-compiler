/**
 * Writes the cross-language parity fixtures in `test/fixtures/`: one row per
 * punch pattern (0..4095) from `charCode.ts`'s forward rules, and one row
 * per BCD code (0..63) from its reverse rules. See
 * `test/fixtures/README.md` for the exact file format.
 *
 * These are the golden vectors a Dart consumer (`lib/src/chars/
 * char_code.dart`) must reproduce exactly to prove cross-language parity;
 * see the `VSC-5` review finding. Until that consumer and its CI gate land,
 * `test/charCodeVectors.test.js` guards only against this TypeScript port
 * drifting from itself.
 *
 * Run with `npm run vectors` after a change to `charCode.ts`;
 * `test/charCodeVectors.test.js` fails while either committed file is
 * stale.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

import {
  bcdFromPunches,
  cardCodeFromPunches,
  glyphFromBcd,
  isGlyphColumn,
  machineSpecialName,
  punchesFromBcd,
} from './charCode';

const fixturesDir = path.join(__dirname, '..', 'test', 'fixtures');

/** Quotes `value` as one CSV field: every field is quoted, no exceptions. */
function csvField(value: string): string {
  return `"${value.replace(/"/g, '""')}"`;
}

function csvRow(fields: readonly string[]): string {
  return fields.map(csvField).join(',') + '\n';
}

function writeCsv(name: string, text: string): void {
  const target = path.join(fixturesDir, name);
  fs.mkdirSync(fixturesDir, { recursive: true });
  fs.writeFileSync(target, text);
  process.stdout.write(`wrote ${path.relative(process.cwd(), target)}\n`);
}

function buildPunchVectors(): string {
  let text = csvRow(['punches', 'bcd', 'card_code', 'is_glyph_column']);
  for (let punches = 0; punches <= 0xfff; punches++) {
    const bcd = bcdFromPunches(punches);
    text += csvRow([
      String(punches),
      bcd === null ? '' : String(bcd),
      cardCodeFromPunches(punches),
      isGlyphColumn(punches) ? 'true' : 'false',
    ]);
  }
  return text;
}

function buildBcdVectors(): string {
  let text = csvRow(['bcd', 'punches', 'glyph', 'machine_special']);
  for (let bcd = 0; bcd <= 0x3f; bcd++) {
    const punches = punchesFromBcd(bcd);
    text += csvRow([
      String(bcd),
      punches === null ? '' : String(punches),
      glyphFromBcd(bcd) ?? '',
      machineSpecialName(bcd) ?? '',
    ]);
  }
  return text;
}

writeCsv('char-code-punch-vectors.csv', buildPunchVectors());
writeCsv('char-code-bcd-vectors.csv', buildBcdVectors());
