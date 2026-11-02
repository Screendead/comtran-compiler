#!/usr/bin/env python3
"""Build index.html for the retrofit record of the 2026-11-02 pitch page.

Reads evidence/calls.json (extracted from evidence/pitch-page.html by
tools/extract_calls.js) and, once Jack has answered, evidence/picks.json.
Writes a standalone index.html beside tools/. Run from anywhere.
"""
import html
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REC = os.path.dirname(HERE)
OUT = os.path.join(REC, "index.html")

PAGE_URL = "https://claude.ai/artifact/VF2SjodMseA7aQMekdqRqw"
PITCH_SHA = "48136bec11e50c017bf9e8bda5b97bc55423bb6c"
EARLIER_SHA = "3dea94e"
REPO = "https://github.com/Screendead/comtran-compiler"

calls = {c["id"]: c for c in json.load(open(os.path.join(REC, "evidence", "calls.json")))}

# The numbering Jack saw: the nine calls of the page before 48136be, then the
# two calls that commit added. The final page source renders nameless as CALL 9,
# d21 as CALL 10 and "Anything else" as CALL 11.
ORDER = ["merges", "defects", "defect6", "compile", "dangling", "w2copy",
         "subscripts", "m7", "other", "nameless", "d21"]
ADDED_LATE = {"nameless", "d21"}

# Jack's rulings, keyed by call id: how each saved pick is read.
PICKS = {d["id"]: {**d["data"], "version": d["version"]}
         for d in json.load(open(os.path.join(REC, "evidence", "picks.json")))}
INFERRED = '<span class="inferred">our reading</span>'
RESAVED = ("<p class=\"mono\">Pick version {v}: the page saved this call {v} times. Only the last value survives; "
           "the earlier ones are not recorded.</p>")
RULINGS = {
    "merges": f"""<p><strong>Read as:</strong> merge the waiting routine pull requests in the pitched order: #145, #157, #158, #166,
then #121, #161, #165, #162, #164, #172, #173, #174, #176 and W2 (#178).</p>
<p>{INFERRED} W2 (#178) was built to the recommended option of call 6. Jack picked a different option there, so #178 needs
the call 6 change before it merges. Every merge to master deploys the public site.</p>""",
    "defects": """<p><strong>Read as:</strong> handle defects 1 to 11. Generate the correct words wherever the manuals attest them.
Merge #167 (defects 1&ndash;2), #168 (8&ndash;11) and #169 (3&ndash;4) one at a time, each with one more review round.
Defect 10 keeps the 1962 behaviour, under his ruling of 2026-10-25 (boundary A).</p>
<p>The same ruling is a dated banner on <code>review/2026-10-25-codegen-defects-1-2</code> and
<code>review/2026-10-25-codegen-defects-8-11</code>.</p>""",
    "defect6": f"""<p><strong>Read as:</strong> message 948,00 at severity 4. The OPEN stays in the object code. The check fires on the
straight run only (#170).</p>
<p>{INFERRED} The option carried the message text shown above. That text is text option A of
<code>review/2026-10-25-codegen-defect-6</code>, so the pick also chooses text A. That record carries the same banner.</p>""",
    "compile": """<p><strong>Read as:</strong> &ldquo;compile&rdquo; in the rule of 2026-09-14 means the diagnostic listing. The two
refusals stay, and take new labels. No code is invented for the sites the 1962 compiler flagged.</p>
<p>The same ruling is a dated banner on <code>review/2026-10-25-m6s2-deck-walkthrough</code> (its option 1).</p>
<p><strong>Correction, 2026-11-02, added after the ruling.</strong> The question as pitched (below, unchanged) says: &ldquo;The 1962
compiler printed its listing but refused to punch an object deck for it.&rdquo; The walkthrough record it links says the
opposite, in its 30-second version, item 3: &ldquo;So, under our severity table, J punches a deck and does not run it.&rdquo;
Its opening says the same: the processor &ldquo;would have printed a full listing of 55 messages, and punched an object
deck, and refused to run it.&rdquo; The walkthrough is right on its own evidence (J 02.01.01: only a code of 5 stops the deck).
So the pitch misstated the premise of call 4. Jack had the walkthrough linked from the call. This record does not judge
whether the misstatement changed his answer; it is flagged here so that he can.</p>""",
    "dangling": """<p><strong>Read as:</strong> a new message 949,00, class 1, issued under <code>--pedantic</code> only (#177).
Default output and the goldens do not change.</p>""",
    "w2copy": """<p><strong>Against the recommendation.</strong> <strong>Read as:</strong> mark every genuine manual typo [sic] on the
generated transcription pages, and strip the em dashes from the language reference.</p>
<p>W2 (#178) as built follows the recommended option, so it does not yet do either.</p>""" + RESAVED.format(v=2),
    "subscripts": """<p><strong>Read as:</strong> diagnose all three. Message 79 for an alphameric literal subscript, 182 for ZERO,
71 for a function term. Amend M3-20 to match.</p>""",
    "m7": """<p><strong>Against the recommendation.</strong> <strong>Read as:</strong> M7 opens the sealed 1963 compiler after the web
track, W3 and W4. The seal of D0.9 holds until then.</p>""" + RESAVED.format(v=2),
    "other": """<p><strong>Read as:</strong> a statement of fact about the custom domain, not a new call.</p>
<p><strong>A check the same day disagrees.</strong> At 13:35Z on 2026-11-02, from Jack's machine, no A or CNAME record for
<code>comtran.screendead.com</code> resolved, and the repository's Pages setting had <code>cname: null</code>
(<code>evidence/dns-check.txt</code>). This record does not settle which is current.</p>""" + RESAVED.format(v=3),
}

CSS = open(os.path.join(HERE, "house.css")).read() + """
.ruling { border:1px solid var(--settled); border-left-width:4px; padding:.7rem 1rem; margin:.6rem 0 1rem; }
.ruling .tag { font-family:var(--mono); font-size:.72rem; letter-spacing:.08em; text-transform:uppercase; color:var(--settled); margin:0 0 .4rem; }
.ruling blockquote { margin:.4rem 0; padding-left:.8rem; border-left:2px solid var(--rule); }
.ruling.open { border-color:var(--stamp); }
.ruling.open .tag { color:var(--stamp); }
.prov { background:var(--raised); border:1px solid var(--rule); border-left:3px solid var(--muted); padding:.9rem 1.1rem; }
.prov .label { font-family:var(--mono); font-size:.68rem; letter-spacing:.14em; text-transform:uppercase; color:var(--muted); display:block; margin-bottom:.3rem; }
.prov p:last-child { margin:0; }
.opt .rec { font-family:var(--mono); font-size:.62rem; letter-spacing:.12em; text-transform:uppercase; color:var(--stamp); margin-left:.5rem; }
.opt .key { font-family:var(--mono); font-size:.72rem; color:var(--muted); }
.opt pre, .ruling pre { font-family:var(--mono); font-size:.74rem; white-space:pre-wrap; margin:.3rem 0 .4rem; background:var(--raised); border:1px solid var(--hair); padding:.4rem .55rem; }
.label-k { font-family:var(--mono); font-size:.64rem; letter-spacing:.12em; text-transform:uppercase; color:var(--muted); display:block; margin:.6rem 0 .15rem; }
a { color:var(--ink); text-decoration-color:var(--rule); }
"""


def e(s):
    return html.escape(s, quote=False)


def ruling_block(cid):
    r = RULINGS.get(cid)
    if r is None:
        if not RULINGS:
            return ""
        return ('<div class="ruling open"><p class="tag">No ruling &middot; still open</p>'
                f"<p>{OPEN_NOTE}</p></div>")
    p = PICKS[cid]
    c = calls[cid]
    if c.get("free"):
        said = f"&ldquo;{e(p['note'])}&rdquo;"
    else:
        opt = next(o for o in c["opts"] if o["k"] == p["choice"])
        said = f"<strong>{opt['t']}</strong> <span class=\"key\">(pick <code>{e(opt['k'])}</code>)</span>"
    return f"""<div class="ruling">
<p class="tag">Jack's ruling &middot; 2026-11-02 &middot; saved {e(p['at'])} &middot; pick version {p['version']}</p>
<blockquote>{said}</blockquote>
{r}
</div>"""


def section(n, cid):
    c = calls[cid]
    late = (f'<p class="mono">Added to the page by commit <code>{PITCH_SHA[:7]}</code>, after the first nine calls. '
            f"The final page source shows it as CALL {ORDER.index(cid)}.</p>") if cid in ADDED_LATE else ""
    built = f'<span class="label-k">Built, as pitched</span><p>{c["built"]}</p>' if c.get("built") else ""
    if c.get("free"):
        opts = ('<span class="label-k">Options</span><p>A free-text box. No options and no recommendation.</p>')
        rec = ""
    else:
        items = []
        for o in c["opts"]:
            tag = '<span class="rec">Recommended</span>' if o.get("rec") else ""
            pre = f"<pre>{o['pre']}</pre>" if o.get("pre") else ""
            items.append(f"""<div class="opt{' pick' if o.get('rec') else ''}">
<h3>{o['t']}{tag}</h3>
<p class="key">pick <code>{e(o['k'])}</code></p>
<p class="consequence">{o['d']}</p>{pre}
</div>""")
        opts = '<span class="label-k">Options, as pitched</span>' + "\n".join(items)
        rec = f'<span class="label-k">Recommendation, as pitched</span><p>{c["recwhy"]}</p>'
    return f"""<section class="item needs" id="call-{cid}">
<div class="itemhead"><span class="chip call">Your call</span><h2>Call {n}. {c['title']}</h2></div>
{ruling_block(cid)}
{late}
<p>{c['why']}</p>
{built}
{opts}
{rec}
</section>"""


OPEN_NOTE = ("No pick for this call is saved on the page. It remains a question for Jack, with the recommendation "
             "below as pitched.")

TOP = f"""<section>
<div class="ruling">
<p class="tag">Jack's rulings &middot; 2026-11-02 &middot; given on the pitch page</p>
<p>Jack answered on <a href="{PAGE_URL}">the pitch page</a> by clicking one option per call. The page saved each pick with a
timestamp, from 13:05:08Z to 13:16:38Z (<code>evidence/picks.json</code>, read back from the page's database the same day).</p>
<ol>
<li><strong>Merges:</strong> all, in the pitched order.</li>
<li><strong>Defects 1&ndash;11:</strong> handle them; defect 10 keeps the 1962 behaviour (ruling of 2026-10-25).</li>
<li><strong>Defect 6:</strong> message 948,00, severity 4, OPEN kept, straight run only.</li>
<li><strong>&ldquo;Compile&rdquo;:</strong> the diagnostic listing. The refusals stay, relabelled.</li>
<li><strong>Dangling continuation:</strong> new message 949,00, class 1, <code>--pedantic</code> only.</li>
<li><strong>W2 copy rules:</strong> mark every genuine manual typo [sic] and strip the em dashes from the reference. <em>Against the recommendation.</em></li>
<li><strong>Three silent subscripts:</strong> diagnose all three (79, 182, 71), amending M3-20.</li>
<li><strong>M7:</strong> after the web track (W3, W4). <em>Against the recommendation.</em></li>
<li><strong>Anything else:</strong> &ldquo;The subdomain is live and already points at the GitHub pages site.&rdquo; A check the same day found no DNS record (call 9).</li>
<li><strong>Nameless BEGIN SECTION:</strong> <em>no pick saved; open.</em></li>
<li><strong>Two PROGRAM.START labels:</strong> <em>no pick saved; open.</em></li>
</ol>
<p>In the chat the same day, Jack wrote: &ldquo;i have answered all the questions.&rdquo; The page holds no saved pick for calls 10
and 11. Commit <code>{PITCH_SHA[:7]}</code>, which added them, is timed 13:16:32Z; his first pick was saved at 13:05:08Z. Both
calls stay open, with their recommendations as pitched.</p>
<p class="mono">The per-call chips below are unchanged: they show the questions as put to him. Each answered call carries
its ruling under its heading.</p>
</div>
</section>"""
SUMMARY = f"""<ol>
<li><strong>Eleven calls were put to Jack on 2026-11-02</strong>, on an interactive pitch page, not in a review record.
This record carries each call as the page put it: the question, the options, the recommendation.</li>
<li><strong>All eleven carry <code>YOUR CALL</code>.</strong> Each one waits for Jack.</li>
<li><strong>Nine calls were on the page from the start.</strong> Calls 10 and 11 were added by commit <code>{PITCH_SHA[:7]}</code> at 13:16:32Z.</li>
</ol>"""

body = "\n\n".join(section(i + 1, cid) for i, cid in enumerate(ORDER))

page = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Pitch rulings, November</title>
<style>{CSS}</style>
</head>
<body>
<main>

<header>
<button id="theme" type="button" aria-label="Switch light or dark">Light / dark</button>
<p class="eyebrow">Review record &middot; retrofit &middot; evidence 2026-11-02 &middot; pitch source at {PITCH_SHA[:7]}</p>
<h1>The eleven calls of the 2 November pitch page</h1>
<p class="standfirst">A retrofit. The calls were put on an interactive page and answered there. This record gives them
a permanent home, with the question as asked and, in its second commit, the answer as given.</p>
</header>

<section>
<div class="prov"><span class="label">Provenance</span>
<p><strong>No review record existed when these questions were put.</strong> They were put to Jack on the interactive
pitch page <a href="{PAGE_URL}">{PAGE_URL}</a>, built on 2026-11-02. He answered there: one click per call, which the
page saved to its own database with a timestamp.</p>
<p>This record was built after the fact, on 2026-11-02, from two sources: the page source, committed on local branch
<code>archive/pitch-2026-11-02</code> at <code>{PITCH_SHA[:7]}</code> and carried here as
<code>evidence/pitch-page.html</code>; and, for the answers, the page's saved picks. Do not read it as a review that happened.</p>
</div>
</section>

{TOP}

<section>
<div class="answer">
{SUMMARY}
</div>
</section>

<section>
<p class="mono">Numbering. The record numbers the calls as the page showed them before <code>{PITCH_SHA[:7]}</code>:
calls 1 to 8, then &ldquo;Anything else&rdquo; as call 9. The two calls added later are 10 and 11. The final page
source renders those two as CALL 9 and CALL 10, and &ldquo;Anything else&rdquo; as CALL 11.
<code>evidence/pitch-page-{EARLIER_SHA}.html</code> is the nine-call page.</p>
</section>

{body}

<footer>
<p>Retrofit record built 2026-11-02 on branch <code>review/2026-11-02-pitch-rulings</code>. Pitch page source:
<code>archive/pitch-2026-11-02</code> at <code>{PITCH_SHA}</code> (local branch, not pushed; a copy is
<code>evidence/pitch-page.html</code>). <code>tools/extract_calls.js</code> evaluates the page's <code>CALLS</code> literal into
<code>evidence/calls.json</code>, so every question, option and recommendation above is the page's own text.
<code>tools/build_doc.py</code> writes this page; edit it, not the HTML.</p>
</footer>

</main>
<script>
(() => {{
  const root = document.documentElement;
  document.getElementById('theme').addEventListener('click', () => {{
    const dark = root.dataset.theme ? root.dataset.theme === 'dark'
      : matchMedia('(prefers-color-scheme: dark)').matches;
    root.dataset.theme = dark ? 'light' : 'dark';
  }});
}})();
</script>
</body>
</html>
"""

with open(OUT, "w", encoding="utf-8") as fh:
    fh.write(page)
