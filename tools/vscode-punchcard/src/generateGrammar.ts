/**
 * Writes `syntaxes/comtran-deck.tmLanguage.json` from the grammar builder,
 * and `package.json`'s `contributes.configurationDefaults` from the column
 * tables. Run with `npm run grammar` after a change to `columns.ts` or
 * `grammar.ts`; `test/grammar.test.js` fails while either committed value is
 * stale.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

import { configurationDefaults } from './columns';
import { buildGrammar } from './grammar';

const root = path.join(__dirname, '..');

function writeGrammar(): void {
  const target = path.join(root, 'syntaxes', 'comtran-deck.tmLanguage.json');
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, JSON.stringify(buildGrammar(), null, 2) + '\n');
  process.stdout.write(`wrote ${path.relative(process.cwd(), target)}\n`);
}

function writePackageConfigurationDefaults(): void {
  const target = path.join(root, 'package.json');
  const pkg = JSON.parse(fs.readFileSync(target, 'utf8'));
  pkg.contributes.configurationDefaults = configurationDefaults();
  fs.writeFileSync(target, JSON.stringify(pkg, null, 2) + '\n');
  process.stdout.write(`wrote ${path.relative(process.cwd(), target)}\n`);
}

writeGrammar();
writePackageConfigurationDefaults();
