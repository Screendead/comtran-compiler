/**
 * Makes manual citations in Dart source clickable in VS Code.
 *
 * `manualCitations.ts` holds the pure logic (the citation regex, and
 * resolving a citation against `manual-map.json`). This module wraps that
 * logic in a `DocumentLinkProvider` and a `HoverProvider`, both registered
 * for the `dart` language in `extension.ts`.
 *
 * Two things must both be true for a citation to get a link or a hover:
 *
 * 1. `manual-map.json`, shipped at the extension root, loads and parses.
 * 2. The open document sits in a workspace folder that holds a
 *    `comtran-manuals` directory — the citation targets live there.
 *
 * Either failing is not an error: the provider returns no links and no
 * hovers, silently. A citation the map has no entry for (`J 90.06`, an
 * unknown F page) gets no link either, by the same rule.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import * as vscode from 'vscode';

import {
  Citation,
  ManualMap,
  ManualMapEntry,
  findCitationAt,
  findCitations,
  resolveCitation,
} from './manualCitations';

/** The document selector both providers register against. */
export const DART_SELECTOR: vscode.DocumentSelector = { language: 'dart' };

/** The name `manual-map.json` ships under, at the extension root. */
export const MANUAL_MAP_FILE_NAME = 'manual-map.json';

/** The directory name a workspace folder must hold to be the manuals
 * root. */
const MANUALS_DIRECTORY_NAME = 'comtran-manuals';

/**
 * Reads and parses `manual-map.json` from the extension's install
 * directory. Returns `undefined` (never throws) when the file is missing
 * or is not valid JSON — the extension ships the file, but a damaged or
 * trimmed install must not crash activation.
 */
export function loadManualMap(
  context: vscode.ExtensionContext,
): ManualMap | undefined {
  try {
    const mapPath = path.join(context.extensionUri.fsPath, MANUAL_MAP_FILE_NAME);
    const text = fs.readFileSync(mapPath, 'utf8');
    return JSON.parse(text) as ManualMap;
  } catch {
    return undefined;
  }
}

/**
 * The filesystem path of the first open workspace folder that holds a
 * `comtran-manuals` directory, or `undefined` when no open folder does.
 */
export function findManualsRoot(): string | undefined {
  const folders = vscode.workspace.workspaceFolders;
  if (folders === undefined) {
    return undefined;
  }
  for (const folder of folders) {
    const candidate = path.join(folder.uri.fsPath, MANUALS_DIRECTORY_NAME);
    if (fs.existsSync(candidate)) {
      return folder.uri.fsPath;
    }
  }
  return undefined;
}

/** The absolute file URI of [entry]'s target file under [manualsRoot], with
 * a `L<line>` fragment so VS Code opens it at the marker line. */
function targetUri(manualsRoot: string, entry: ManualMapEntry): vscode.Uri {
  return vscode.Uri.file(path.join(manualsRoot, entry.file)).with({
    fragment: `L${entry.line}`,
  });
}

/** The absolute file URI of [entry]'s page scan under [manualsRoot], or
 * `undefined` when the entry carries no scan. */
function scanUri(manualsRoot: string, entry: ManualMapEntry): vscode.Uri | undefined {
  return entry.scan === undefined
    ? undefined
    : vscode.Uri.file(path.join(manualsRoot, entry.scan));
}

function citationRange(
  document: vscode.TextDocument,
  citation: Citation,
): vscode.Range {
  return new vscode.Range(
    document.positionAt(citation.start),
    document.positionAt(citation.end),
  );
}

/** Turns every resolvable manual citation in a `dart` document into a
 * `DocumentLink` that opens the citation's target in the manual
 * conversion, at its marker line. */
export class ManualCitationLinkProvider implements vscode.DocumentLinkProvider {
  constructor(private readonly manualMap: ManualMap | undefined) {}

  provideDocumentLinks(document: vscode.TextDocument): vscode.DocumentLink[] {
    if (this.manualMap === undefined) {
      return [];
    }
    const manualsRoot = findManualsRoot();
    if (manualsRoot === undefined) {
      return [];
    }
    const links: vscode.DocumentLink[] = [];
    for (const citation of findCitations(document.getText())) {
      const entry = resolveCitation(this.manualMap, citation.key);
      if (entry === null) {
        continue;
      }
      const link = new vscode.DocumentLink(
        citationRange(document, citation),
        targetUri(manualsRoot, entry),
      );
      link.tooltip = entry.heading;
      links.push(link);
    }
    return links;
  }
}

/** Shows the heading a citation resolves to, with links to open the manual
 * text at its marker line and the page scan, when the map records one. */
export class ManualCitationHoverProvider implements vscode.HoverProvider {
  constructor(private readonly manualMap: ManualMap | undefined) {}

  provideHover(
    document: vscode.TextDocument,
    position: vscode.Position,
  ): vscode.Hover | undefined {
    if (this.manualMap === undefined) {
      return undefined;
    }
    const manualsRoot = findManualsRoot();
    if (manualsRoot === undefined) {
      return undefined;
    }
    const citation = findCitationAt(document.getText(), document.offsetAt(position));
    if (citation === null) {
      return undefined;
    }
    const entry = resolveCitation(this.manualMap, citation.key);
    if (entry === null) {
      return undefined;
    }
    const markdown = new vscode.MarkdownString(undefined);
    // Headings hold literal asterisks (card names like *FILE); appendText
    // escapes them so the renderer shows them verbatim.
    markdown.appendMarkdown('**');
    markdown.appendText(entry.heading);
    markdown.appendMarkdown('**\n\n');
    markdown.appendMarkdown(`[open text](${targetUri(manualsRoot, entry).toString()})`);
    const scan = scanUri(manualsRoot, entry);
    if (scan !== undefined) {
      markdown.appendMarkdown(` \\| [open scan](${scan.toString()})`);
    }
    return new vscode.Hover(markdown, citationRange(document, citation));
  }
}

/** Registers both providers for the `dart` language, loading
 * `manual-map.json` once. Call from `activate()`; both providers fail soft
 * (see the module doc comment) when the map or the workspace is not
 * available, so this is safe to call unconditionally. */
export function registerManualCitationProviders(
  context: vscode.ExtensionContext,
): void {
  const manualMap = loadManualMap(context);
  context.subscriptions.push(
    vscode.languages.registerDocumentLinkProvider(
      DART_SELECTOR,
      new ManualCitationLinkProvider(manualMap),
    ),
    vscode.languages.registerHoverProvider(
      DART_SELECTOR,
      new ManualCitationHoverProvider(manualMap),
    ),
  );
}
