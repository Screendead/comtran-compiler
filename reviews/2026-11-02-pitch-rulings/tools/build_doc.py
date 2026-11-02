#!/usr/bin/env python3
"""Build index.html for the retrofit record of the 2026-11-02 pitch page.

Reads evidence/calls.json (extracted from evidence/pitch-page.html by
tools/extract_calls.js) and, once Jack has answered, evidence/picks.json.
Round two reads evidence/calls-round2.json and the crops in crops/; round three reads evidence/calls-round3.json.
Writes a standalone index.html beside tools/. Run from anywhere.
"""
import base64
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
.flag { border-left:3px solid var(--stamp); padding-left:.8rem; }
"""


def e(s):
    return html.escape(s, quote=False)


def ruling_block(cid, open_note=None):
    r = RULINGS.get(cid)
    if r is None:
        if not RULINGS:
            return ""
        return ('<div class="ruling open"><p class="tag">No ruling &middot; still open</p>'
                f"<p>{open_note or OPEN_NOTE}</p></div>")
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


def section(label, cid, c, anchor, head, evidence=""):
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
    ev = f'<span class="label-k">Evidence</span>\n{evidence}' if evidence else ""
    return f"""<section class="item needs" id="{anchor}">
<div class="itemhead"><span class="chip call">Your call</span><h2>{label}. {c['title']}</h2></div>
{head}
{'<span class="label-k">The question, as pitched</span>' if evidence else ''}
<p>{c['why']}</p>
{built}
{ev}
{opts}
{rec}
</section>"""


def round1(n, cid):
    late = (f'<p class="mono">Added to the page by commit <code>{PITCH_SHA[:7]}</code>, after the first nine calls. '
            f"The final page source shows it as CALL {ORDER.index(cid)}.</p>") if cid in ADDED_LATE else ""
    return section(f"Call {n}", cid, calls[cid], f"call-{cid}", ruling_block(cid) + "\n" + late)


# Round two: the page as rewritten by commit ROUND2_SHA on archive/pitch-2026-11-02.
ROUND2_SHA = "33cc8a88669c54d193707cec57d016d45a1fd3db"
ROUND2_AT = "14:28:30Z"
calls2 = {c["id"]: c for c in json.load(open(os.path.join(REC, "evidence", "calls-round2.json")))}
ORDER2 = ["confirm4", "subscripts2", "typos3", "headdash", "nameless", "d21", "other2"]
W2_MERGE = "2cf337fdb0f884f33acf7e190f7454792730ebc6"
PR181_HEAD = "ebf4a63df3f472d5667df2ee8aa8d34e47ed3554"
PR182_HEAD = "0a87165fa4f2fc283b1ec04406c8ac97e1e88fce"
WALK_BANNER = "01f6f93"


def crop(name, caption):
    data = base64.b64encode(open(os.path.join(REC, "crops", name), "rb").read()).decode()
    return (f'<figure><div class="scan"><img src="data:image/png;base64,{data}" alt="{e(caption)}"></div>'
            f"<figcaption>{caption} <code>crops/{name}</code>, cut by <code>tools/make_crops.py</code>.</figcaption></figure>")


def commit(sha, text=None):
    return f'<a href="{REPO}/commit/{sha}"><code>{text or sha[:7]}</code></a>'


def tree(sha, path, text=None):
    return f'<a href="{REPO}/blob/{sha}/{path}"><code>{text or path}</code></a>'


EVIDENCE2 = {
    "confirm4": f"""<p>Two rules in J28-6169 bear on the premise. They are separate rules.</p>
<ul>
<li><strong>The deck.</strong> J 02.01.01, on the NODECK option: &ldquo;If the severity code is 5, a deck will not be
produced.&rdquo; Any lower code punches a deck.</li>
<li><strong>The run.</strong> J 90.04.02: &ldquo;Any code above 1 does prevent running of the object program immediately
after compilation.&rdquo;</li>
</ul>
<p>Under our severity table, the verbatim 1960 deck draws a highest code of 4, and the FILE&nbsp;IN refusal draws 3.
Both are our choice (D7.5); no 1962 severity value survives (J 90.04.01). With either code, J punches a deck and does
not run it. The walkthrough record says so, and its ruling banner is commit {WALK_BANNER} on
<code>review/2026-10-25-m6s2-deck-walkthrough</code>.</p>
<p>The round-one pitch of call 4 said the opposite: &ldquo;The 1962 compiler printed its listing but refused to punch an
object deck for it.&rdquo; Call 4 above carries the correction note.</p>
<p><strong>PR #182</strong> (open, head {commit(PR182_HEAD)}) applies the listing reading to M6-9 in
{tree(PR182_HEAD, "docs/design/m6-acceptance.md")}. Its text: &ldquo;A refusal does not say that the 1962 processor refused
the deck. J punches a deck at severity 3 and does not run it ([J 90.04.02]). The pitch page of 2026-11-02 said the 1962
compiler refused to punch a deck. That statement is wrong, and the walkthrough record shows it.&rdquo; The page's
&ldquo;Built&rdquo; line calls this &ldquo;PR in progress&rdquo;; PR #182 is that pull request.</p>
<p>{INFERRED} The PR #182 sentence cites J 90.04.02 for the deck as well as the run. The deck rule is J 02.01.01.
It also names severity 3 only; the verbatim deck's code is 4. Neither changes the reading.</p>""",
    "subscripts2": f"""<p><strong>PR #181</strong> (&ldquo;Diagnose a function call in a subscript&rdquo;, open, head
{commit(PR181_HEAD)}). Its description, verbatim:</p>
<blockquote><p>Jack's ruling of 2026-11-02 (call 7, review/2026-11-02-pitch-rulings) asked for messages on three subscript
terms. Only one was silent:</p>
<ul><li>A function call in a subscript, alone or inside an index expression, drew nothing; it now draws 71,00 (F p. 31
allows a name, a literal or an index expression). The SET and ADD target walk is now pinned by a test.</li>
<li><code>TAB CELL ('A')</code> already draws 912,00 and <code>TAB CELL (ZERO)</code> already draws 192,00, both from the
parser. The audit that called them silent read only semantic diagnostics. A new test pins both for whole runs. 79 and 182
are not added; that part goes back to Jack, and M3-20's amendment says so.</li></ul></blockquote>
<p>So the round-one ruling on call 7 (&ldquo;79, 182, 71&rdquo;) rested on an audit that missed two messages the
parser already issues. This call asks whether those two messages stand.</p>""",
    "typos3": f"""<p>The three words, as the 150-dpi scans print them:</p>
{crop("j-p116-indicies.png", "J 06.02.05, PDF p. 116: &ldquo;the programmers' indicies or relative unit assignment&rdquo;.")}
{crop("j-p116-synonomous.png", "J 06.02.05, PDF p. 116: &ldquo;OU, OU1, OU2, are synonomous&rdquo;.")}
{crop("j-p171-in-not-used.png", "J 90.02.32, PDF p. 171, SYS)283: &ldquo;the 'ON ERROR' option in not used&rdquo;, with &ldquo;not&rdquo; underlined.")}
<p>What the conversions say:</p>
<ul>
<li><code>comtran-manuals/J28-6169/06-systems-maintenance.md</code>, conversion note: &ldquo;The word &lsquo;standart&rsquo;
(PDF p.121, step 2) and &lsquo;synonomous&rsquo; (PDF p.116) and &lsquo;indicies&rsquo; (PDF p.116) and &lsquo;Mimimum&rsquo;
(PDF p.110, item 1) are reproduced exactly as printed in the source (apparent period typos/spelling variants), per the
fidelity rule.&rdquo;</li>
<li><code>comtran-manuals/J28-6169/90.02-generated-code.md</code>, conversion note: &ldquo;PDF 171 (SYS)283):
&lsquo;...whenever the &#x27;ON ERROR&#x27; option in not used...&rsquo; &mdash; printed as &lsquo;in not used&rsquo; (with
&lsquo;not&rsquo; underlined in the original) rather than &lsquo;is not used.&rsquo;&rdquo;</li>
</ul>
<p>The rules, in {tree(W2_MERGE, "docs/design/web-copy.md")} at the W2 merge: E3 marks a genuine typo <code>[sic]</code>
when the scan prints it, a note or the definition calls it a typo, and it is not a period spelling. E4: &ldquo;Never mark an
authentic period spelling <code>[sic]</code>.&rdquo; The list <code>typos</code> in
{tree(W2_MERGE, "tool/web_sources_source.dart")} holds eleven words: &ldquo;throught&rdquo;, &ldquo;at lease&rdquo;,
&ldquo;lables&rdquo;, &ldquo;dinsity&rdquo;, &ldquo;Parentheis&rdquo;, &ldquo;alwyas&rdquo;, &ldquo;Mimimum&rdquo;,
&ldquo;standart&rdquo;, &ldquo;Appox-Max&rdquo;, &ldquo;depending of&rdquo; and &ldquo;bu&rdquo;. W2 is PR #178, merged
2026-11-02 at 14:27:15Z as {commit(W2_MERGE)}.</p>
<p><strong>Not the whole open set.</strong> E3 lists six words that wait for Jack. The page pitches three of them. The other
three are not on the page: &ldquo;MIMIMUM&rdquo; (PDF p. 72, an option word of the <code>$LOAD</code> card), &ldquo;a fixed
number or words&rdquo; (PDF p. 54) and &ldquo;if of the following form&rdquo; (PDF p. 124). They stay unmarked whatever
this call decides.</p>
<p>{INFERRED} &ldquo;Standart&rdquo; and &ldquo;Mimimum&rdquo; carry the same note wording as &ldquo;synonomous&rdquo; and
&ldquo;indicies&rdquo;, and W2 marks them. The note alone therefore does not separate the marked words from these two.</p>""",
    "headdash": f"""<p>Counted on the W2 merge {commit(W2_MERGE)} by <code>tools/count_dashes.sh</code>; the output, with the 21
headings listed, is <code>evidence/dash-counts.txt</code>:</p>
<div class="scroll"><table>
<tr><th>Measure</th><th>Count</th></tr>
<tr><td>Em dashes in the language definition before W2</td><td>1051</td></tr>
<tr><td>Em dashes after W2</td><td>107</td></tr>
<tr><td>Removed by W2 (the page's &ldquo;944&rdquo;)</td><td>944</td></tr>
<tr><td>Headings that keep one</td><td>21</td></tr>
<tr><td>Contents lines that keep one</td><td>10</td></tr>
</table></div>
<p>Rule D5 in {tree(W2_MERGE, "docs/design/web-copy.md")} lists the five places the reference keeps the mark, among them
&ldquo;a heading and the contents entry that repeats it, because the heading text sets an anchor that other files link
to&rdquo;. The same file holds the open item: &ldquo;Twenty-one headings of the language definition keep an em dash, and
ten contents entries repeat them. A heading sets the anchor that other files link to, so a change to one needs a change to
each link in the same pull request. Until Jack rules, the headings keep the mark.&rdquo;</p>
<p><code>test/web_copy_test.dart</code> enforces the list, and caps the dashes in citation parentheses at 42
(<code>citationDashCap</code>).</p>""",
    "nameless": """<p>Carried over from round one, unanswered. The page's text for this call is identical to round one's
(<code>evidence/calls.json</code> and <code>evidence/calls-round2.json</code> compare equal for this id). Round one holds
it as call 10, above.</p>""",
    "d21": """<p>Carried over from round one, unanswered. The page's text for this call is identical to round one's
(<code>evidence/calls.json</code> and <code>evidence/calls-round2.json</code> compare equal for this id). Round one holds
it as call 11, above. The open item has waited since 6 September.</p>""",
    "other2": """<p>The page's free-text box for round two, as round one's call 9 was. Not one of the six calls.</p>""",
}
ROUND1_NO = {"nameless": 10, "d21": 11}
OPEN_NOTE2 = ("Put to Jack on the pitch page on 2026-11-02. No answer is recorded here yet.")


def round2(i, cid):
    c = calls2[cid]
    label = f"Round two, call {i}" if cid != "other2" else "Round two, the free-text box"
    head = ('<div class="ruling open"><p class="tag">Open &middot; put 2026-11-02</p>'
            f"<p>{OPEN_NOTE2}</p></div>")
    if cid in ROUND1_NO:
        head += (f'<p class="mono">Also round one, <a href="#call-{cid}">call {ROUND1_NO[cid]}</a>.</p>')
    return section(label, cid, c, f"call-r2-{cid}", head, EVIDENCE2[cid])


ROUND2 = f"""<section id="round-two">
<h2>Second round, put 2026-11-02</h2>
<div class="prov"><span class="label">Provenance</span>
<p>Jack's first-round answers led to new work, and the work raised new questions. Commit {ROUND2_SHA[:7]} on local branch
<code>archive/pitch-2026-11-02</code>, timed {ROUND2_AT}, rewrote <a href="{PAGE_URL}">the pitch page</a> as a second
round: four new calls, plus calls 10 and 11 of round one, which had no answer. The page was the channel again; this record
was not. Its source is <code>evidence/pitch-page-round2.html</code>, and <code>tools/extract_calls.js</code> evaluates its
<code>CALLS</code> literal into <code>evidence/calls-round2.json</code>. Every question, option and recommendation below
is the page's own text. The evidence under each call is this record's.</p>
<p>The page also carries a free-text box. It is listed last, for parity with round one's call 9.</p>
</div>
</section>"""


# Round three: the page as rewritten by commit ROUND3_SHA on archive/pitch-2026-11-02. HEADDASH_SHA added the
# #192 build line; the CALLS literal is unchanged from there to PAGE3_SHA, the copy carried as evidence.
ROUND3_SHA = "5f22c54580bd147a47e896003899a34ef60cb60d"
ROUND3_AT = "16:42:52Z"
HEADDASH_SHA = "aba5359331d84650bb0d34a1b512a87b5e5029ea"
HEADDASH_AT = "16:45:19Z"
PAGE3_SHA = "09ceda9459018e340af4d8ecc7753a9ed0e833a6"
PAGE3_AT = "18:02:42Z"
calls3 = {c["id"]: c for c in json.load(open(os.path.join(REC, "evidence", "calls-round3.json")))}
ORDER3 = ["confirm4", "subscripts2", "typos3", "headdash", "defect5", "nameless", "d21", "w3", "w4", "other3"]
PR181_MERGE = "7031c9cb0efa2b5f5e69a6b5228a032c8d5b3fa7"
PR182_HEAD_FINAL = "23f3ea32551f7fdc2f2767144d476a5c2d6342e5"
PR182_MERGE = "dba709d81a33763883b8e659cacfb6c8cde6bbd1"
DRAFTS = {  # call id: (PR number, head at the time of this record, read with gh on 2026-11-02)
    "headdash": (192, "886ab93ed8c0e973dd09e1e08b7477527c72654f"),
    "defect5": (185, "e62e838671698833ae79dc41eeb4726ad3e65f11"),
    "nameless": (183, "861348f3892e1e74a80a3a2ee5034db4579e03f3"),
    "d21": (184, "72d922cfdefb92026274f71efa6119c644cde355"),
    "w3": (189, "deab5343302d07269939d66ec5c67fd964e7ffe4"),
    "w4": (188, "a31994d31b4ad41dc9234a93daab715b38ddec82"),
}
CARRIED = {"confirm4": 1, "subscripts2": 2, "typos3": 3, "headdash": 4, "nameless": 5, "d21": 6}
UNCHANGED = ("<p><strong>Carried over from round two, unchanged.</strong> The page's text for this call is identical to "
             "round two's (<code>evidence/calls-round2.json</code> and <code>evidence/calls-round3.json</code> compare "
             "equal for this id). Round two's evidence for it, above, still applies.</p>")


def draft(cid, page_gives_head=True):
    n, sha = DRAFTS[cid]
    how = ("The page gives the same head." if page_gives_head
           else f"{INFERRED} The page gives no head for #{n}; this one was read with <code>gh</code> on 2026-11-02.")
    return (f'<p><strong>Draft PR <a href="{REPO}/pull/{n}">#{n}</a></strong>, open, head {commit(sha)} at the time of '
            f"this record. {how} Not merged.</p>")


EVIDENCE3 = {
    "confirm4": UNCHANGED + f"""<p><strong>Superseded since round two.</strong> Round two's evidence names PR #182 as open at
head {commit(PR182_HEAD)}. PR #182 has since merged: final head {commit(PR182_HEAD_FINAL)}, merge commit
{commit(PR182_MERGE)}. The page's &ldquo;Built&rdquo; line still says &ldquo;PR in progress&rdquo;; its status list, outside
the calls, says &ldquo;the listing reading is in the record (#182, merged)&rdquo;.</p>""",
    "subscripts2": UNCHANGED + f"""<p><strong>Superseded since round two.</strong> The question says PR #181 is &ldquo;in
review&rdquo;. It has since merged, at head {commit(PR181_HEAD)}, merge commit {commit(PR181_MERGE)}. The page's status
list, outside the calls, says so (&ldquo;#181, merged&rdquo;).</p>""",
    "typos3": UNCHANGED,
    "headdash": f"""<p><strong>Carried over from round two, updated with a built prototype.</strong> The question, the
recommendation and the option titles are unchanged. Two fields changed, by commit {commit(HEADDASH_SHA)} at
{HEADDASH_AT}, three minutes after round three went up:</p>
<ul>
<li><strong>Built.</strong> Round two: &ldquo;Counted on the merged W2. Not changed.&rdquo; Round three: built as draft #192.</li>
<li><strong>The <code>change</code> option.</strong> Round two: &ldquo;Rename 21 headings, sweep the repository for each
old anchor, and let a test catch any link left behind. About an hour.&rdquo; Round three: &ldquo;Merge #192&rdquo;, with the
ten contents links repointed.</li>
</ul>
{draft("headdash", page_gives_head=False)}
<p>Round two's dash counts (<code>evidence/dash-counts.txt</code>) still describe master: #192 is not merged.</p>""",
    "defect5": f"""<p><strong>New in round three.</strong></p>
{draft("defect5")}
<p>Only option A is built. The listing line under option B is the page's illustration; option C is marked &ldquo;Not
built; the sample is illustrative.&rdquo;</p>""",
    "nameless": f"""<p><strong>Carried over from round two, rewritten, with a built prototype.</strong> Every field
changed. The recommendation did not: <code>196</code> in all three rounds.</p>
<ul>
<li><strong>Title.</strong> Round two: &ldquo;A BEGIN SECTION with no name: diagnose it, and with which message?&rdquo;</li>
<li><strong>Built.</strong> Round two: probed on master, not built. Round three: option <code>196</code> built as draft #183.</li>
<li><strong>Options.</strong> Round two gave each option one sentence and no listing line. Round three gives each a
listing line and says whether it was checked. The new-message option is now <code>950</code> (round two: <code>9xx</code>).
Under <code>196</code>, round two said later ENDs &ldquo;may draw 65&rdquo;; the built prototype draws msg 64. The
<code>leave</code> option now states that it means generating code no sample shows.</li>
</ul>
{draft("nameless")}
<p>Only option <code>196</code> is built. The lines under <code>192</code> and <code>950</code> come, as the page says, from
a throwaway patch and were not checked. The lines under <code>leave</code> are master today.</p>""",
    "d21": f"""<p class="flag"><strong>The recommendation reversed.</strong> Rounds one and two recommended
<code>refuse</code> (<a href="#call-r2-d21">round two, call 6</a>; <a href="#call-d21">round one, call 11</a>). Round three
recommends <code>first</code>, and builds it as draft #184. The page's reason: both rulings of 2026-11-02 came after the
2026-09-06 recommendation to refuse, and the text of msg 141 (&ldquo;FIRST USED&rdquo;) counts as the manual showing what
the 1962 compiler did. The recommendation below says which reading of the evidence leads to <code>refuse</code> instead.</p>
<ul>
<li><strong>Title.</strong> Round two: &ldquo;Two PROGRAM.START labels: obey D2.1, or keep the generator's refusal?&rdquo;</li>
<li><strong>Built.</strong> Round two pointed at <code>review/2026-09-06-m4s4-machine-assembly</code>, item 5. Round three:
<code>first</code> built as #184, plus the verbatim D2.1 amendment text for <code>refuse</code>, on no branch yet.</li>
<li><strong>Options.</strong> Same two keys, order swapped. Round two gave each one sentence (<code>refuse</code>:
&ldquo;No code change. The listing still shows message 141.&rdquo;). Round three gives each its listing lines and its cost
to undo.</li>
</ul>
{draft("d21")}""",
    "w3": f"""<p><strong>New in round three.</strong></p>
{draft("w3")}
<p>Only option A is built. The line under it is the page's example of one mark the compiler sends.</p>""",
    "w4": f"""<p><strong>New in round three.</strong></p>
{draft("w4")}
<p>{INFERRED} The draft builds the run button, which the question reports as working. None of the four tutorial forms in
the options is built: the call is about the page the tutorial lives on.</p>""",
    "other3": """<p>The page's free-text box for round three, as in rounds one and two. Not one of the nine calls.</p>""",
}
OPEN_NOTE3 = "Put to Jack on the pitch page on 2026-11-02. No answer is recorded here yet."


def round3(i, cid):
    c = calls3[cid]
    label = f"Round three, call {i}" if cid != "other3" else "Round three, the free-text box"
    head = ('<div class="ruling open"><p class="tag">Open &middot; put 2026-11-02</p>'
            f"<p>{OPEN_NOTE3}</p></div>")
    if cid in CARRIED:
        head += f'<p class="mono">Also round two, <a href="#call-r2-{cid}">call {CARRIED[cid]}</a>.</p>'
    return section(label, cid, c, f"call-r3-{cid}", head, EVIDENCE3[cid])


ROUND3 = f"""<section id="round-three">
<h2>Third round, put 2026-11-02</h2>
<div class="prov"><span class="label">Provenance</span>
<p>Commit {ROUND3_SHA[:7]} on local branch <code>archive/pitch-2026-11-02</code>, timed {ROUND3_AT}, rewrote
<a href="{PAGE_URL}">the pitch page</a> as a third round of nine calls. Six carry over from round two, which had no answer
recorded: three unchanged (<code>confirm4</code>, <code>subscripts2</code>, <code>typos3</code>) and three changed
(<code>headdash</code>, <code>nameless</code>, <code>d21</code>), each now backed by a built prototype. Three are new:
<code>defect5</code>, <code>w3</code> and <code>w4</code>. Commit {HEADDASH_SHA[:7]} at {HEADDASH_AT} added the #192 build
line to <code>headdash</code>. The page's <code>CALLS</code> literal is unchanged from there to {PAGE3_SHA[:7]} at
{PAGE3_AT}; the later commits change only the status lists around the calls. The page at {PAGE3_SHA[:7]} is
<code>evidence/pitch-page-round3.html</code>, and <code>tools/extract_calls.js</code> evaluates its literal into
<code>evidence/calls-round3.json</code>. Every question, option and recommendation below is the page's own text. The
evidence under each call is this record's.</p>
<p><strong>Read first:</strong> round three reverses the recommendation on two PROGRAM.START labels, from
<code>refuse</code> to <code>first</code> (<a href="#call-r3-d21">call 7</a>).</p>
<p>The free-text box is listed last, as in rounds one and two.</p>
</div>
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
<li><strong>A second round of six calls followed the same day</strong>, on the same page, at {ROUND2_AT}
(<a href="#round-two">below</a>). Four are new; two are calls 10 and 11, still unanswered. All six carry
<code>YOUR CALL</code>, with the page's options and recommendation and this record's evidence. One corrects the premise
of call 4; one reports that two of call 7's three subscripts already drew messages.</li>
<li><strong>A third round of nine calls followed</strong>, on the same page, at {ROUND3_AT}
(<a href="#round-three">below</a>). Six carry over from round two: three unchanged, and three updated with a built
prototype. Three are new: defect 5, W3 and W4. All nine carry <code>YOUR CALL</code>. On two PROGRAM.START labels, the
recommendation reverses from <code>refuse</code> to <code>first</code>.</li>
</ol>"""

body = "\n\n".join(round1(i + 1, cid) for i, cid in enumerate(ORDER))
body2 = "\n\n".join(round2(i + 1, cid) for i, cid in enumerate(ORDER2))
body3 = "\n\n".join(round3(i + 1, cid) for i, cid in enumerate(ORDER3))

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
a permanent home, with the question as asked and, in its second commit, the answer as given. A later commit adds the
page's second round of six calls, put the same afternoon, and a later one its third round of nine.</p>
</header>

<section>
<div class="prov"><span class="label">Provenance</span>
<p><strong>No review record existed when these questions were put.</strong> They were put to Jack on the interactive
pitch page <a href="{PAGE_URL}">{PAGE_URL}</a>, built on 2026-11-02. He answered there: one click per call, which the
page saved to its own database with a timestamp.</p>
<p>This record was built after the fact, on 2026-11-02, from two sources: the page source, committed on local branch
<code>archive/pitch-2026-11-02</code> at <code>{PITCH_SHA[:7]}</code> and carried here as
<code>evidence/pitch-page.html</code>; and, for the answers, the page's saved picks. Do not read it as a review that happened.</p>
<p>The second round was put the same way, on the same page, from commit <code>{ROUND2_SHA[:7]}</code> of the same branch.
Its section was added to this record afterwards, on 2026-11-02, with the evidence for each call. The third round
followed the same way, from commit <code>{ROUND3_SHA[:7]}</code>.</p>
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

{ROUND2}

{body2}

{ROUND3}

{body3}

<footer>
<p>Retrofit record built 2026-11-02 on branch <code>review/2026-11-02-pitch-rulings</code>. Pitch page source:
<code>archive/pitch-2026-11-02</code> at <code>{PITCH_SHA}</code> (local branch, not pushed; a copy is
<code>evidence/pitch-page.html</code>). <code>tools/extract_calls.js</code> evaluates the page's <code>CALLS</code> literal into
<code>evidence/calls.json</code>, so every question, option and recommendation above is the page's own text.
Round two: the same branch at <code>{ROUND2_SHA}</code>, copied as <code>evidence/pitch-page-round2.html</code> and
extracted to <code>evidence/calls-round2.json</code>. <code>tools/make_crops.py</code> cuts the three crops from the
J28-6169 scans; <code>tools/count_dashes.sh</code> writes <code>evidence/dash-counts.txt</code>.
Round three: the same branch at <code>{PAGE3_SHA}</code>, copied as <code>evidence/pitch-page-round3.html</code> and
extracted to <code>evidence/calls-round3.json</code>.
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
