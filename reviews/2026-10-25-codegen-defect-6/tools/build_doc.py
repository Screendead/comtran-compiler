"""Build index.html for review/2026-10-25-codegen-defect-6.

Reads the captures in evidence/, the crops in crops/ and house.css, and
writes a standalone index.html beside this directory. Every image is a
data: URI. Run: python3 tools/build_doc.py (from anywhere).
"""

import base64
import html
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

MASTER = "fca3157"
PROTO = "6cda03b"
PROTO_FULL = "6cda03b6b10e3c2132c0d3d0f03652b6a3a34fbb"
TESTS = 1444
BLOB = f"https://github.com/Screendead/comtran-compiler/blob/{MASTER}"

CSS = open(os.path.join(HERE, "house.css")).read()


def img(name):
    data = base64.b64encode(open(os.path.join(REC, "crops", name), "rb").read()).decode()
    return f'<img src="data:image/png;base64,{data}" alt="">'


def ev(name):
    return open(os.path.join(REC, "evidence", name)).read()


def tail_from(text, marker):
    i = text.find(marker)
    return text[i:].rstrip()


def diag_line(text):
    m = re.search(r"^ +10,01 .*$", text, re.M)
    return m.group(0) if m else "(no line)"


def report(text):
    return text[text.find("TAPE1 REPORT"):].split("exit")[0].strip().replace("\n\n", "\n")


e = html.escape
caps = {s: ev(f"reopen-{s}.txt") for s in ("sev1", "sev3", "sev4")}
today = ev(f"reopen-today-{MASTER}.txt")
proc = re.search(r" +\*PROCEDURE\n(.*?)\n\n", caps["sev4"], re.S).group(1)

SEV = [
    ("sev1", "1", "OPEN kept", "The program runs. The reopen rewinds TAPE1 and the second write overwrites the first."),
    ("sev3", "3", "OPEN deleted", "The FILE after the close is a no-operation (D6.3). The tape keeps ONE; TWO is lost with no message."),
    ("sev4", "4", "OPEN kept", "As severity 1 in the deck. J 02.01.02 and D7.6 then forbid the run; our <code>--run</code> does not yet apply that gate."),
]
sev_rows = "".join(
    f'<tr><td class="mono">{n}</td><td>{what}</td><td><pre class="words">{e(diag_line(caps[k]))}</pre></td>'
    f'<td><pre class="words">{e(report(caps[k]))}</pre><p class="why">{why}</p></td></tr>'
    for k, n, what, why in SEV
)

page = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Codegen defect 6</title>
<style>{CSS}
a {{ color:var(--ink); text-decoration-color:var(--rule); }}
td pre.words {{ min-height:0; white-space:pre; }}
.lst {{ font-family:var(--mono); font-size:.74rem; line-height:1.45; margin:.4rem 0 1rem;
        border:1px solid var(--hair); padding:.5rem .7rem; background:var(--raised);
        white-space:pre; overflow-x:auto; }}
blockquote {{ margin:.3rem 0 .9rem; padding:.1rem 0 .1rem 1rem; border-left:3px solid var(--rule); }}
</style>
</head>
<body>
<main>

<header>
<button id="theme" type="button" aria-label="Switch light or dark">Light / dark</button>
<p class="eyebrow">Review record &middot; codegen defect 6 &middot; evidence 2026-10-25 &middot; master at {MASTER} &middot; prototype at {PROTO} (local)</p>
<h1>A reopen after CLOSE ALL FILES: what the message says, how severe it is, and how far the compiler looks</h1>
<p class="standfirst">J forbids the reopen. D6.3 tells us to diagnose it where the text shows it. Today the compiler is silent,
and the run quietly overwrites the tape. Three choices are yours; the id is settled.</p>
</header>

<section>
<div class="answer">
<ol>
<li><strong>Today it compiles clean and loses data.</strong> The probe below opens TAPE1, writes ONE, closes all, opens all,
writes TWO. On master the listing says <code>NO ERRORS</code>; the run reopens TAPE1 at its start and the tape ends holding
only TWO.</li>
<li><strong>Id: <code>948,00</code>, ours, default mode.</strong> Settled by D9.7 and the next free id after 947.</li>
<li><strong>Text: your call.</strong> Recommended, and built: <code>-OPEN ALL FILES- FOLLOWS -CLOSE ALL FILES-. FILES CLOSED BY THAT
FORM MAY NOT BE REOPENED. (NON-HISTORICAL.)</code> The proposed <code>'NAME.1'</code> form has no name to print for OPEN ALL FILES.</li>
<li><strong>Severity: your call. Recommended: 4, OPEN kept.</strong> D9.2's class C4 is &ldquo;a program that cannot run correctly&rdquo;.
One catch: <code>comtranc --run</code> runs any punched deck today, at every severity below 5. The J 02.01.02 gate that D7.6 records is not built,
so until it is, 1, 3 and 4 all run.</li>
<li><strong>Scope: your call. Recommended: the straight run, OPEN ALL FILES only.</strong> A named OPEN refuses at code generation today,
so it has no site.</li>
<li><strong>Prototype</strong> at <code>{PROTO}</code>, local only: {TESTS} tests pass, every golden is unchanged, and the sample's
<code>CLOSE ALL FILES, STOP RUN.</code> stays silent.</li>
</ol>
</div>
</section>

<section class="item" id="evidence">
<div class="itemhead"><span class="chip done">Settled</span><h2>The evidence</h2></div>
<figure><div class="scan">{img("j-02.04.06-close-all-files.png")}</div>
<figcaption>J 02.04.06, PDF p. 24, items 8 and 9. Crop of comtran-manuals/J28-6169/images/page-024.png, box (180, 130, 1080, 790).
The conversion (02-compiler.md:520) matches the scan word for word.</figcaption></figure>
<figure><div class="scan">{img("j-90.04.01-msgs-138-139.png")}</div>
<figcaption>J 90.04.01, PDF p. 184. 138 and 139 are the only catalog entries on OPEN or CLOSE. Both concern a missing file name;
neither fits a reopen. The page is skewed, so the edge rows clip.</figcaption></figure>
<p>D6.3 (<a href="{BLOB}/docs/design/decisions.md#L972">decisions.md:972</a>, Locked):</p>
<blockquote>Reopening after <code>CLOSE ALL FILES</code> is forbidden by J: diagnose it when it is statically determinable; otherwise no
object-time message, because none is attested — a runtime message for reopen-after-CLOSE-ALL-FILES is available only under
--pedantic and is marked non-historical.</blockquote>
<p>Its Implementation line (<a href="{BLOB}/docs/design/decisions.md#L976">:976</a>): &ldquo;diagnostics (statically determinable reopen after
CLOSE ALL FILES only)&rdquo;. M5-4 as amended (<a href="{BLOB}/docs/design/m5-io.md#L205">m5-io.md:205</a>): &ldquo;A close-all and then an
open-all therefore read the file from its start. &hellip; J forbids a reopen after CLOSE ALL FILES, so no program may depend on it.&rdquo;
The OPEN emitter (<a href="{BLOB}/lib/src/codegen/procedure.dart#L1512">procedure.dart:1512</a>) emits <code>TSX SYS)175,4</code> and checks nothing.</p>
<p>The probe program, as listed:</p>
<pre class="lst">{e(proc)}</pre>
</section>

<section class="item" id="id">
<div class="itemhead"><span class="chip done">Settled</span><h2>1. The id: 948,00</h2></div>
<p>No 90.04 message fits, so the message is ours: an id outside 0&ndash;209 and a text ending <code>(NON-HISTORICAL.)</code> (D9.7;
<code>Message.ours</code>, <a href="{BLOB}/lib/src/lexer/messages.dart#L23">messages.dart:23</a>). The highest id in use is 947. Unlike 946 and 947, 948 issues in the
default mode, because D6.3 puts the static diagnosis there. D11.4 then fixes its severity in both modes.</p>
</section>

<section class="item needs" id="text">
<div class="itemhead"><span class="chip call">Your call</span><h2>2. The text</h2></div>
<div class="opt pick"><h3>A. One text for the ALL FILES form (built, recommended)</h3>
<p><code>-OPEN ALL FILES- FOLLOWS -CLOSE ALL FILES-. FILES CLOSED BY THAT FORM MAY NOT BE REOPENED. (NON-HISTORICAL.)</code></p>
<p class="consequence">The keyword style of 138 and 139, and J's own words. Fits the only form that can reach the check today. To reverse: one string and one checklist row.</p></div>
<div class="opt"><h3>B. The proposed text with a file name</h3>
<p><code>-OPEN- OF 'NAME.1' FOLLOWS -CLOSE ALL FILES-. A FILE CLOSED BY THAT FORM MAY NOT BE REOPENED. (NON-HISTORICAL.)</code></p>
<p class="consequence">OPEN ALL FILES has no operand. <code>Message.substitute</code> replaces nothing when the operand list is empty
(<a href="{BLOB}/lib/src/lexer/messages.dart#L40">messages.dart:40</a>), so the listing would print <code>'NAME.1'</code> literally. It needs a named OPEN, which refuses today.</p></div>
<p>When named OPEN lands, it can take its own text then. Writing it now would be code with no caller (CLAUDE.md section 11).</p>
</section>

<section class="item needs" id="severity">
<div class="itemhead"><span class="chip call">Your call</span><h2>3. The severity</h2></div>
<p>The listing prints the severity in the CODE column. D7.6 and J 02.01.02 give it one effect below 5: above 1, the program
&ldquo;will be executed unless &hellip; the Compiler has encountered a source program error with a severity code greater than 1&rdquo;.
Each row is a real capture from the prototype with that one severity row changed. Severity 3 also deletes the OPEN's words
(<code>evidence/severity-3-delete-variant.diff</code>).</p>
<div class="scroll"><table>
<tr><th>Code</th><th>Deck</th><th>Listing line</th><th>Run under <code>--run --list-tapes</code>, today</th></tr>
{sev_rows}
</table></div>
<p>All three runs end at <code>AT 11,00 STOP RUN</code> with exit status 0. <code>_runObjectProgram</code>
(<a href="{BLOB}/bin/comtranc.dart#L364">comtranc.dart:364</a>) runs every deck the compiler punched; only severity 5 punches none.</p>
<div class="opt"><h3>1. Warn and keep the OPEN</h3>
<p class="consequence">D9.2's C1 is for code the compiler &ldquo;completes&rdquo; as intended; J says the reopen &ldquo;may not&rdquo; happen, so there is no intended code.
The program runs in both 1962 terms and ours, down the path M5-4 calls unreliable. To reverse: one table row.</p></div>
<div class="opt"><h3>3. Delete the OPEN</h3>
<p class="consequence">The deck no longer matches the source. The run then drops every later FILE in silence, which is worse than the reopen. Under
D9.2's largest-lost-unit rule one lost clause is C2 (as 25 OPERATION IGNORED is), so 3 is not even the class's own value. Adds a deletion
path the generator does not have. To reverse: a code change and a row.</p></div>
<div class="opt pick"><h3>4. Keep the OPEN, forbid the run (recommended)</h3>
<p class="consequence">C4, &ldquo;a program that cannot run correctly&rdquo;; ours at 940 and 941 already take C4 this way. The deck stays as written.
The run stops only once the 02.01.02 gate reaches <code>--run</code>; until then 4 differs from 1 in the printed digit alone. To reverse: one table row.</p></div>
</section>

<section class="item needs" id="scope">
<div class="itemhead"><span class="chip call">Your call</span><h2>4. How far the compiler looks</h2></div>
<div class="opt pick"><h3>(i) The straight run (built, recommended)</h3>
<p>Fire when an OPEN ALL FILES follows an unconditional CLOSE ALL FILES with nothing between that can change the path. In the walker:
the CLOSE sets a flag; any label clears it (a sentence label, an IF's OTHERWISE and join labels); so do GO TO, STOP RUN and END.
A DO does not, since control returns. This is the same boundary at which the register cache already clears
(<a href="{BLOB}/lib/src/codegen/procedure.dart#L422">procedure.dart:422</a>, &ldquo;A label ends the straight run&rdquo;).</p>
<p class="consequence">Every path to the OPEN passes the CLOSE, so the one false alarm is a CLOSE ALL that closed nothing. It misses a CLOSE inside a DO'd procedure, every loop, and any IF between the two, even one with no transfer in it: the IF's join label ends the run. <em>Corrected 2026-10-25: the first version named only the DO and the loop.</em>
18 lines. To widen later: replace the flag.</p></div>
<div class="opt"><h3>(ii) Text order anywhere</h3>
<p class="consequence">Fires on correct programs. <code>START. GO TO INIT. / FINI. CLOSE ALL FILES, STOP RUN. / INIT. OPEN ALL FILES, &hellip; GO TO FINI.</code>
never reopens, but its OPEN follows the CLOSE in the text. At severity 4 that forbids the run of a legal program. Not recommended at any severity above 1.</p></div>
<div class="opt"><h3>(iii) Control flow: every path to the OPEN passes a CLOSE ALL</h3>
<p class="consequence">Exact for its question, and adds the DO case. It needs a flow graph over GO TO, IF, DO and AT END that the generator does not build;
947's walk covers DO edges only. It still misses the likeliest real reopen, a loop (<code>LOOP. OPEN ALL FILES &hellip; CLOSE ALL FILES. GO TO LOOP.</code>),
because the first entry does not pass the CLOSE. Only a &ldquo;some path&rdquo; check catches the loop, and that one can fire on paths the data never takes.</p></div>
<p><strong>Named OPEN.</strong> <code>OPEN file</code> refuses today (<code>an OPEN naming files (notes section 7)</code>), so the
sub-question has no site. For the record: J binds &ldquo;files closed by this form&rdquo;, so a named OPEN of a file that was not open at the
CLOSE ALL is not forbidden by the text. STOP RUN's own close-all is not counted: nothing follows STOP RUN in a straight run.</p>
</section>

<section class="item" id="gate">
<div class="itemhead"><span class="chip done">Settled</span><h2>Found on the way: the run gate is missing</h2></div>
<p>D7.6 (Locked): &ldquo;On any maximum severity above 1: punch the deck but suppress automatic execution under LOAD.&rdquo;
<code>comtranc --run</code> does not apply it, for any message. The design record outranks the code (CLAUDE.md section 6), so this is a defect,
not a collision. It reaches past defect 6, so this record does not fix it. Recommended: list it in HANDOVER beside defect 6.</p>
</section>

<section class="item needs" id="answer">
<div class="itemhead"><span class="chip call">Your call</span><h2>Your answer</h2></div>
<fieldset class="pick"><legend>Text</legend>
<label><input type="radio" name="text" value="A" checked> <strong>A.</strong> Recommended. <code>-OPEN ALL FILES- FOLLOWS -CLOSE ALL FILES-. &hellip;</code> (built).</label>
<label><input type="radio" name="text" value="B"> <strong>B.</strong> The <code>'NAME.1'</code> form.</label>
<label><input type="radio" name="text" value="own"> <strong>My own wording</strong> (in the note).</label>
</fieldset>
<fieldset class="pick"><legend>Severity</legend>
<label><input type="radio" name="sev" value="4" checked> <strong>4, OPEN kept.</strong> Recommended.</label>
<label><input type="radio" name="sev" value="1"> <strong>1, OPEN kept.</strong></label>
<label><input type="radio" name="sev" value="3"> <strong>3, OPEN deleted.</strong></label>
</fieldset>
<fieldset class="pick"><legend>Scope</legend>
<label><input type="radio" name="scope" value="i" checked> <strong>(i)</strong> Recommended. The straight run (built).</label>
<label><input type="radio" name="scope" value="ii"> <strong>(ii)</strong> Text order anywhere.</label>
<label><input type="radio" name="scope" value="iii"> <strong>(iii)</strong> Every path through a flow graph.</label>
</fieldset>
<fieldset class="pick"><legend>The run gate</legend>
<label><input type="radio" name="gate" value="list" checked> <strong>List it</strong> in HANDOVER as its own defect. Recommended.</label>
<label><input type="radio" name="gate" value="with"> <strong>Build it</strong> in the same pull request as defect 6.</label>
</fieldset>
<p class="mono">Anything else:</p>
<textarea id="anote" aria-label="Your note"></textarea>
<p><button id="copy" type="button">Copy my answer</button></p>
<pre id="aout"></pre>
<p class="mono">Your answer lands in this record as a dated banner, in a second commit on this branch, and authorizes the pull request
that carries it (review-records rule 7).</p>
</section>

<footer>
<p>Record built 2026-10-25 on branch <code>review/2026-10-25-codegen-defect-6</code>. Master at <code>{MASTER}</code>. The prototype is
commit <code>{PROTO_FULL}</code> on the local branch <code>defect-6-proto</code>, not pushed; <code>evidence/prototype-{MASTER}..{PROTO}.diff</code>
holds it whole. <code>tools/build_doc.py</code> writes this page; <code>tools/crops.py</code> cuts the crops; <code>tools/probe.dart</code>
writes the three probe decks. Line links point at {MASTER}.</p>
</footer>
</main>
<script>
const $ = (s) => document.querySelector(s);
(function () {{
  const root = document.documentElement;
  try {{ const t = localStorage.getItem('theme'); if (t) root.dataset.theme = t; }} catch (e) {{}}
  $('#theme').addEventListener('click', () => {{
    const dark = root.dataset.theme ? root.dataset.theme === 'dark'
      : matchMedia('(prefers-color-scheme: dark)').matches;
    root.dataset.theme = dark ? 'light' : 'dark';
    try {{ localStorage.setItem('theme', root.dataset.theme); }} catch (e) {{}}
  }});
}})();
function answerText() {{
  const pick = (n) => (document.querySelector('input[name="' + n + '"]:checked') || {{}}).value || '(no choice)';
  const note = $('#anote').value.trim();
  return 'review/2026-10-25-codegen-defect-6\\n' +
    'Text: ' + pick('text') + '\\nSeverity: ' + pick('sev') + '\\nScope: ' + pick('scope') +
    '\\nRun gate: ' + pick('gate') + (note ? '\\nNote: ' + note : '');
}}
function refresh() {{ $('#aout').textContent = answerText(); }}
for (const i of document.querySelectorAll('input[type="radio"]')) i.addEventListener('change', refresh);
$('#anote').addEventListener('input', refresh);
$('#copy').addEventListener('click', async () => {{
  try {{ await navigator.clipboard.writeText(answerText()); $('#copy').textContent = 'Copied'; }}
  catch (e) {{ $('#copy').textContent = 'Copy failed: select the text below'; }}
  setTimeout(() => {{ $('#copy').textContent = 'Copy my answer'; }}, 2500);
}});
refresh();
</script>
</body>
</html>
"""
open(OUT, "w").write(page)
print(OUT)
