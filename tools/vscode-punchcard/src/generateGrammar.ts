/**
 * Writes `syntaxes/comtran-deck.tmLanguage.json` from the grammar builder.
 * Run with `npm run grammar` after a change to `columns.ts` or `grammar.ts`;
 * `test/grammar.test.js` fails while the committed file is stale.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

import { buildGrammar } from './grammar';

const target = path.join(
  __dirname,
  '..',
  'syntaxes',
  'comtran-deck.tmLanguage.json',
);
fs.mkdirSync(path.dirname(target), { recursive: true });
fs.writeFileSync(target, JSON.stringify(buildGrammar(), null, 2) + '\n');
process.stdout.write(`wrote ${path.relative(process.cwd(), target)}\n`);
