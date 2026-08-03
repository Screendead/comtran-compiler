/**
 * Manual citations in COMTRAN Dart source: recognizing them and resolving
 * them against `manual-map.json`.
 *
 * This module has no `vscode` import. `manualLinks.ts` wraps it for the
 * DocumentLinkProvider and HoverProvider; `test/manualCitations.test.js`
 * exercises it directly.
 *
 * Two citation forms are recognized, both defined by CLAUDE.md section 8:
 *
 * - `J 02.03.02` — an IBM section code of two to four components.
 * - `F p. 42` and `F pp. 50-51` — a printed page of F28-8043, alone or as
 *   one contiguous range (a hyphen or an en dash).
 *
 * A citation the map has no entry for (`J 90.06`, an unknown F page) still
 * parses, but resolves to `null`: the caller gives it no link.
 */

/** One target the manual map points a citation key at. */
export interface ManualMapEntry {
  file: string;
  line: number;
  slug: string;
  heading: string;
  pdfPage?: number;
  scan?: string;
}

/** The shape of `manual-map.json` this module reads. */
export interface ManualMap {
  sections: Record<string, ManualMapEntry>;
}

/** An inclusive first-to-last printed page range, `from` alone when the
 * citation names a single page. */
export interface PageRange {
  from: number;
  to: number;
}

/** One citation found in a document's text. */
export interface Citation {
  /** The map key: `J:02.03.02` or `F:42`. */
  key: string;
  /** The matched text, verbatim. */
  text: string;
  /** The offset of the first character of the match. */
  start: number;
  /** The offset one past the last character of the match. */
  end: number;
  /** The page range of an F citation; absent for a J citation. */
  pages?: PageRange;
}

/**
 * A citation in its canonical form. Group 1 holds a J section code; groups
 * 2 to 5 hold the F abbreviation, the first page, the range dash and the
 * last page. The two lookaheads after the J code stop a longer code or a
 * lettered subsection (`J 02.07.F`) from matching a prefix of itself.
 */
const CITATION_SOURCE =
  '\\bJ (\\d{2}(?:\\.\\d{2}){1,3})(?!\\w)(?!\\.\\w)' +
  '|' +
  '\\bF (pp?)\\. (\\d+)(?:([-–—])(\\d+))?(?!\\w)';

/** Every canonical citation in [text], in order of appearance. */
export function findCitations(text: string): Citation[] {
  const pattern = new RegExp(CITATION_SOURCE, 'g');
  const citations: Citation[] = [];
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(text)) !== null) {
    citations.push(citationFromMatch(match));
  }
  return citations;
}

/** The citation at or touching [offset] in [text], or `null` when none
 * covers that position. */
export function findCitationAt(text: string, offset: number): Citation | null {
  for (const citation of findCitations(text)) {
    if (offset >= citation.start && offset <= citation.end) {
      return citation;
    }
  }
  return null;
}

function citationFromMatch(match: RegExpExecArray): Citation {
  const jCode = match[1];
  if (jCode !== undefined) {
    return {
      key: `J:${jCode}`,
      text: match[0],
      start: match.index,
      end: match.index + match[0].length,
    };
  }
  const from = Number.parseInt(match[3]!, 10);
  const to = match[5] === undefined ? from : Number.parseInt(match[5], 10);
  return {
    key: `F:${from}`,
    text: match[0],
    start: match.index,
    end: match.index + match[0].length,
    pages: { from, to },
  };
}

/** The map entry [key] resolves to in [map], or `null` when the map has no
 * entry for it. */
export function resolveCitation(
  map: ManualMap,
  key: string,
): ManualMapEntry | null {
  return map.sections[key] ?? null;
}
