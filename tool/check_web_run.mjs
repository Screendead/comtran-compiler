// Runs the 90.05 sample through the built site's WebAssembly compiler and
// compares the run with test/goldens/90.05-payroll.report.
//
// test/web_run_test.dart holds the library to the golden on the Dart VM.
// This script holds the WebAssembly build itself, which the VM test cannot
// reach. It needs Node 22 or later, for WasmGC.
//
// From the repository root, after `dart run tool/build_web.dart`:
//
//     node tool/check_web_run.mjs

import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const site = (file) => pathToFileURL(`${process.cwd()}/web/${file}`);

const { compile, instantiate, invoke } = await import(site('main.mjs'));
const { SAMPLE } = await import(site('sample.js'));
const { TAPES } = await import(site('tapes.js'));

invoke(await instantiate(await compile(readFileSync('web/main.wasm')), {}));

const started = performance.now();
const result = JSON.parse(globalThis.comtranRun(SAMPLE, JSON.stringify(TAPES)));
const milliseconds = performance.now() - started;

const expected =
  'AT 199,14 STOP RUN\n' +
  readFileSync('test/goldens/90.05-payroll.report', 'utf8');

if (result.error || !result.ended || result.output !== expected) {
  console.error('The WebAssembly run does not print the report golden.');
  console.error(JSON.stringify(result, null, 2));
  process.exit(1);
}
console.log(
  `The WebAssembly run prints the report golden, in ${milliseconds.toFixed(0)} ms.`,
);
