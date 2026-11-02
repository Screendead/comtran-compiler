// Usage: node tools/extract_calls.js evidence/pitch-page.html > evidence/calls.json
// Evaluates the page's CALLS literal alone, so the record quotes the pitch verbatim.
const fs = require("fs");
const src = fs.readFileSync(process.argv[2], "utf8");
const start = src.indexOf("const CALLS = [");
const end = src.indexOf("\n];", start);
if (start < 0 || end < 0) throw new Error("CALLS literal not found");
const CALLS = new Function(src.slice(start, end + 3) + "\nreturn CALLS;")();
process.stdout.write(JSON.stringify(CALLS, null, 2) + "\n");
