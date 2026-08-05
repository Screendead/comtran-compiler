import { execFile } from 'node:child_process';
import * as fs from 'node:fs';
import * as path from 'node:path';

const CANON_EXTENSION = '.ctd';
const MIRROR_EXTENSION = '.ct';

/** How a `deckconv` run ended: `ok` on exit 0; otherwise `detail` holds
 * the tool's stderr (which names the offending card) or the spawn error. */
export interface DeckconvResult {
  readonly ok: boolean;
  readonly detail: string;
}

/** The mirror path of the canon file at `canonPath` (`X.ctd` → `X.ct`),
 * or null when the path does not end in `.ctd`. */
export function mirrorPathFor(canonPath: string): string | null {
  if (!canonPath.endsWith(CANON_EXTENSION)) {
    return null;
  }
  return canonPath.slice(0, -CANON_EXTENSION.length) + MIRROR_EXTENSION;
}

/** The canon path of the mirror at `mirrorPath` (`X.ct` → `X.ctd`), or
 * null when the path does not end in `.ct`. */
export function canonPathFor(mirrorPath: string): string | null {
  if (!mirrorPath.endsWith(MIRROR_EXTENSION)) {
    return null;
  }
  return mirrorPath.slice(0, -MIRROR_EXTENSION.length) + CANON_EXTENSION;
}

/** The nearest ancestor directory of `fsPath` holding a `pubspec.yaml` —
 * the directory `dart run comtran:deckconv` must run from. Returns null
 * when `fsPath` is not inside a Dart package. */
export function repoRootFor(fsPath: string): string | null {
  let dir = path.dirname(fsPath);
  for (;;) {
    if (fs.existsSync(path.join(dir, 'pubspec.yaml'))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) {
      return null;
    }
    dir = parent;
  }
}

const pairRuns = new Map<string, Promise<unknown>>();

/** True while `withPair` work for `key` is queued or in flight. */
export function pairBusy(key: string): boolean {
  return pairRuns.has(key);
}

/** Serializes `run` against all other work on the same deck pair, keyed
 * by the canon path. The two save directions and the canon write itself
 * must never interleave: two `deckconv` processes racing on one pair can
 * leave it stale or overwrite one side's edits. */
export function withPair<T>(key: string, run: () => Promise<T>): Promise<T> {
  const previous = pairRuns.get(key) ?? Promise.resolve();
  const next = previous.then(run, run);
  const tail = next.then(
    () => undefined,
    () => undefined,
  );
  pairRuns.set(key, tail);
  void tail.then(() => {
    if (pairRuns.get(key) === tail) {
      pairRuns.delete(key);
    }
  });
  return next;
}

/** Runs `dart run comtran:deckconv <args>` from `root`. Never rejects: a
 * non-zero exit, a missing Dart SDK, and a 60-second hang all come back
 * as `ok: false`. */
export function runDeckconv(
  root: string,
  args: readonly string[],
): Promise<DeckconvResult> {
  return new Promise((resolve) => {
    execFile(
      'dart',
      ['run', 'comtran:deckconv', ...args],
      { cwd: root, timeout: 60_000 },
      (error, _stdout, stderr) => {
        if (error === null) {
          resolve({ ok: true, detail: '' });
          return;
        }
        const detail = stderr.trim();
        resolve({ ok: false, detail: detail === '' ? error.message : detail });
      },
    );
  });
}
