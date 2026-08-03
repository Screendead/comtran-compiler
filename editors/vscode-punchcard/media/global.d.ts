// Ambient declaration for the webview API global, so `checkJs` can
// type-check `punchcard.js` without a runtime dependency. VS Code injects
// this function into the webview's global scope; there is no npm package
// for it.

interface VsCodeApi {
  getState(): unknown;
  setState(state: unknown): void;
  postMessage(message: unknown): void;
}

declare function acquireVsCodeApi(): VsCodeApi;
