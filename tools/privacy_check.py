#!/usr/bin/env python3
"""Claude Code PreToolUse hook: stops personal details from being published to GitHub.

Inspects `git push`, `gh pr|issue create/edit/comment/review/merge` and the GitHub MCP
tools that write text or files. On a hit it denies the tool call with a reason naming the
category and location, never the matched text.

Runs only in cloud sessions (CLAUDE_CODE_REMOTE=true) unless given --always, so a vendored
project copy stays quiet where a global hook already covers the machine.

A reviewed false positive is allowed by putting the exact text, one per line, in
`.privacy-allow` at the repo root.

Manual scan of history: privacy_check.py --scan DIR REV [MAX_COMMITS] [--show]
(--show prints matched text; keep that output off anything that is published).
"""
import bisect
import codecs
import json
import os
import re
import shlex
import subprocess
import sys

MAX_COMMITS = 2000
GIT_TIMEOUT_S = 25
MAX_REPORTED = 8

# The owner's surname and first name, rot13-encoded so neither is spelt out in the public
# repos this file is vendored into (nor trips this check). The bare surname is also an
# English word, so it counts only when capitalised; joined to the first name (a username)
# it counts in any case.
_SURNAME = codecs.decode("Yhfure", "rot13")
_FIRST = codecs.decode("Wnpx", "rot13")

MCP_TOOLS = {
    "create_pull_request", "update_pull_request", "add_issue_comment", "issue_write",
    "update_issue_comment", "create_or_update_file", "push_files",
    "add_comment_to_pending_review", "pull_request_review_write",
    "add_reply_to_pull_request_comment", "merge_pull_request",
}

EMAIL = re.compile(r"(?<![\w.%+-])([A-Za-z0-9][A-Za-z0-9._%+-]*)@((?:[A-Za-z0-9-]+\.)+([A-Za-z]{2,24}))(?![\w-])")
FILE_EXTENSIONS = {
    "png", "jpg", "jpeg", "gif", "svg", "pdf", "webp", "heic", "tiff", "ico", "icns", "mp4", "mov",
    "json", "swift", "js", "ts", "tsx", "jsx", "mjs", "py", "md", "txt", "html", "css", "metal", "plist",
    "lock", "log", "yml", "yaml", "toml", "sh", "zip", "csv", "wav", "mp3", "m4a", "ttf", "otf", "bin",
    "db", "sqlite", "xml", "rb", "kt", "java", "cpp", "mm", "tmp", "bak", "out",
}
# Service addresses, never a person's.
SERVICE_DOMAINS = re.compile(r"(^|\.)(github\.com|gserviceaccount\.com)$")
RESERVED_TLDS = {"test", "example", "invalid", "localhost", "local"}
HOME_PATH = re.compile(r"(?<![\w.~-])/(Users|home)/([A-Za-z0-9._-]+)")
PLACEHOLDER_USERS = {
    "user", "runner", "shared", "username", "name", "you", "me", "someone", "example", "your-name",
    "yourname", "foo", "x", "...", "<name>", "guest", "ubuntu", "admin",
}
UDID = re.compile(r"(?<![0-9A-Fa-f-])00008[0-9A-Fa-f]{3}-[0-9A-Fa-f]{16}(?![0-9A-Fa-f])")
HEX40 = re.compile(r"(?<![0-9A-Fa-f])[0-9a-fA-F]{40}(?![0-9A-Fa-f])")
MONEY = re.compile(
    r"(?<![\w\\$])(?:[£€]\s?\d[\d,]*(?:\.\d+)?"
    r"|\$(?:\d{1,3}(?:,\d{3})+|\d+\.\d{2}(?!\d)|\d{2,}(?![\w}])|\d(?=\s?(?:/|per\b|k\b|m\b|bn\b))))"
    r"|\b\d[\d,]*(?:\.\d+)?\s?(?:GBP|USD|EUR)\b"
)
# Money-shaped text in code (a compiler's edited-picture output, say) is not money.
CODE_SPAN = re.compile(r"`[^`]*`")
FENCE = re.compile(r"^\s*(```|~~~)")
COPYRIGHT = re.compile(r"(?i)copyright|©|\(c\)")


class Context:
    def __init__(self, cwd):
        self.cwd = cwd
        root = git(cwd, "rev-parse", "--show-toplevel")
        self.root = root.strip() if root else None
        self.own_email = (git(cwd, "config", "user.email") or "").strip().lower()
        self.allow = []
        if self.root:
            try:
                with open(os.path.join(self.root, ".privacy-allow"), encoding="utf-8") as f:
                    self.allow = [line.strip() for line in f if line.strip()]
            except OSError:
                pass


def git(cwd, *args):
    try:
        done = subprocess.run(
            ["git", "-C", cwd, *args], capture_output=True, timeout=GIT_TIMEOUT_S,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        print(f"privacy_check: git {args[0]}: {error}", file=sys.stderr)
        return None
    if done.returncode != 0:
        return None
    return done.stdout.decode("utf-8", "replace")


def email_allowed(match, ctx):
    local, domain, tld = match.group(1).lower(), match.group(2).lower(), match.group(3).lower()
    address = match.group(0).lower()
    if "noreply" in address or "no-reply" in address:
        return True
    if tld in RESERVED_TLDS or tld in FILE_EXTENSIONS:
        return True
    if re.search(r"(^|\.)example\.(com|org|net)$", domain):
        return True
    if local == "git" or SERVICE_DOMAINS.search(domain):
        return True
    return bool(ctx.own_email) and address == ctx.own_email


def positions(haystack, needle):
    i = haystack.find(needle)
    while i != -1:
        yield i
        i = haystack.find(needle, i + 1)


def text_hits(text, ctx):
    """(category, start, end) for each personal detail in text. Each detector is anchored on a
    literal found with str.find, so large pushes (hundreds of MB of data) stay fast."""
    for p in positions(text, "@"):
        for m in EMAIL.finditer(text, max(0, p - 64), p + 256):
            if m.start(2) - 1 == p and not email_allowed(m, ctx):
                yield "email address", m.start(), m.end()
    for prefix in ("/Users/", "/home/"):
        for p in positions(text, prefix):
            m = HOME_PATH.match(text, p)
            if m and m.group(2).lower() not in PLACEHOLDER_USERS:
                yield "local home path", m.start(), m.end()
    for p in positions(text, "00008"):
        m = UDID.match(text, p)
        if m:
            yield "device UDID", m.start(), m.end()
    lower = text.lower()
    seen = set()
    for word in ("udid", "device", "iphone"):
        for p in positions(lower, word):
            for m in HEX40.finditer(text, max(0, p - 300), p + 300):
                near = m.start() <= p + len(word) + 40 and m.end() >= p - 40
                inside = m.start() > max(0, p - 300) and m.end() < p + 300
                if near and inside and m.start() not in seen:
                    seen.add(m.start())
                    yield "device UDID", m.start(), m.end()
    joined = (_FIRST + _SURNAME).lower()
    named = set()
    for p in positions(lower, joined):
        named.add(p + len(_FIRST))
        if not COPYRIGHT.search(line_at(text, p)):
            yield "owner's surname", p, p + len(joined)
    for p in positions(lower, _SURNAME.lower()):
        word, before, after = text[p:p + len(_SURNAME)], text[p - 1:p], text[p + len(_SURNAME):p + len(_SURNAME) + 1]
        capitalised = word == _SURNAME and not ("a" <= after <= "z")
        upper = word == _SURNAME.upper() and not before.isalpha() and not after.isalpha()
        if (capitalised or upper) and p not in named and not COPYRIGHT.search(line_at(text, p)):
            yield "owner's surname", p, p + len(_SURNAME)


def line_at(text, pos):
    return text[text.rfind("\n", 0, pos) + 1:(text.find("\n", pos) + 1 or len(text) + 1) - 1]


def money_hits(text):
    fenced, offset = False, 0
    for line in text.split("\n"):
        if FENCE.match(line):
            fenced = not fenced
        elif not fenced:
            code = [m.span() for m in CODE_SPAN.finditer(line)]
            for m in MONEY.finditer(line):
                if not any(a <= m.start() < b for a, b in code):
                    yield "money amount", offset + m.start(), offset + m.end()
        offset += len(line) + 1


def allowed(line, start, end, ctx):
    for literal in ctx.allow:
        i = line.find(literal)
        while i != -1:
            if i <= start and end <= i + len(literal):
                return True
            i = line.find(literal, i + 1)
    return False


def scan_text(text, label, prose, ctx, out, numbered=None, labels=None):
    """Appends (category, location, value) for each hit. The location is labels[line] when
    given, else label, with the line number appended when numbered (default: if multi-line)."""
    hits = list(text_hits(text, ctx))
    if prose:
        hits += money_hits(text)
    if not hits:
        return
    starts = [0] + [m.end() for m in re.finditer("\n", text)]
    multi = len(starts) > 1
    for category, start, end in sorted(hits, key=lambda h: h[1]):
        i = bisect.bisect_right(starts, start) - 1
        line = line_at(text, start)
        if allowed(line, start - starts[i], end - starts[i], ctx):
            continue
        if labels:
            where = labels[i]
        elif numbered or (numbered is None and multi):
            where = f"{label}:{i + 1}" if numbered else f"{label} line {i + 1}"
        else:
            where = label
        out.append((category, where, text[start:end]))


def scan_commits(ctx, revs, out, exclude_remotes=True, max_count=MAX_COMMITS):
    args = ["log", "--no-color", "--no-ext-diff", "--no-textconv", "-p", "-U0",
            f"--max-count={max_count}", "--format=%x01%h%n%B%x02", *revs]
    if exclude_remotes:
        args += ["--not", "--remotes"]
    log = git(ctx.cwd, *args, "--")
    if log is None:
        print(f"privacy_check: could not read commits for {revs}", file=sys.stderr)
        return
    for chunk in log.split("\x01")[1:]:
        head, _, diff = chunk.partition("\x02")
        sha, _, message = head.partition("\n")
        scan_text(message.strip("\n"), f"commit {sha} message", True, ctx, out, numbered=False)
        scan_diff(diff, f"(commit {sha})", ctx, out)


def scan_diff(diff, suffix, ctx, out):
    """Scans the added lines of a unified diff."""
    added, labels = [], []
    path, n, in_header = None, 0, True
    for line in diff.split("\n"):
        if line.startswith("diff --git "):
            path, in_header = None, True
        elif in_header and line.startswith("+++ "):
            path = None if line[4:] == "/dev/null" else line[4:].removeprefix("b/")
        elif line.startswith("@@"):
            in_header = False
            m = re.match(r"@@ -\S+ \+(\d+)", line)
            n = int(m.group(1)) if m else 0
        elif not in_header and path and line.startswith("+"):
            added.append(line[1:])
            labels.append((path, n))
            n += 1
    if added:
        scan_text("\n".join(added), "", False, ctx, out,
                  labels=[f"{p}:{k} {suffix}" for p, k in labels])


def scan_worktree(ctx, include_untracked, out):
    """What a `git commit` earlier in the same Bash call is about to record."""
    diff = git(ctx.cwd, "diff", "--no-color", "--no-ext-diff", "--no-textconv", "-U0", "HEAD", "--")
    if diff:
        scan_diff(diff, "(uncommitted)", ctx, out)
    if not include_untracked:
        return
    for name in (git(ctx.cwd, "ls-files", "-z", "--others", "--exclude-standard") or "").split("\0"):
        try:
            with open(os.path.join(ctx.cwd, name), "rb") as f:
                data = f.read(1_000_001)
        except OSError:
            continue
        if name and len(data) <= 1_000_000 and b"\0" not in data:
            text = data.decode("utf-8", "replace")
            count = text.count("\n") + 1
            scan_text(text, name, False, ctx, out, labels=[f"{name}:{k} (uncommitted)" for k in range(1, count + 1)])


# ---- command parsing -------------------------------------------------------------------

SEPARATORS = {";", "&&", "||", "|", "&", "(", ")", "\n", "|&", ";;"}
PREFIX_WORDS = {
    "command", "builtin", "exec", "time", "noglob", "nohup",
    "do", "then", "else", "elif", "if", "while", "until", "{", "}", "!",
}
HEREDOC = re.compile(r"<<-?[ \t]*(['\"]?)([A-Za-z_]\w*)\1([^\n]*)\n(.*?)\n[ \t]*\2[ \t]*(?=\n|\)|$)", re.S)
HEREDOC_MARK = "__privacy_heredoc__"
UNRESOLVED = "unresolved directory"
UNPARSED = "command it could not parse"


def cut_heredocs(command):
    """The command with heredoc bodies replaced by a marker, and the bodies."""
    bodies = []

    def mark(m):
        bodies.append(m.group(4))
        return f"<< {HEREDOC_MARK}{m.group(3)}"

    return HEREDOC.sub(mark, command), bodies


def segments(command):
    lex = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>\n")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    current = []
    for token in lex:
        if token in SEPARATORS:
            if current:
                yield current
            current = []
        else:
            current.append(token)
    if current:
        yield current


def strip_redirections(tokens):
    out, skip = [], False
    for token in tokens:
        if skip:
            skip = False
            continue
        if token and set(token) <= set("<>&") and ("<" in token or ">" in token):
            if out and out[-1].isdigit():
                out.pop()
            skip = True
            continue
        out.append(token)
    return out


def strip_prefix(tokens):
    while tokens:
        t = tokens[0]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t) or t in PREFIX_WORDS:
            tokens = tokens[1:]
        elif t == "env":
            tokens = tokens[1:]
            while tokens and (tokens[0].startswith("-") or "=" in tokens[0]):
                tokens = tokens[1:]
        elif t == "nice":
            tokens = tokens[1:]
            if tokens[:1] == ["-n"]:
                tokens = tokens[2:]
            elif tokens and tokens[0].startswith("-"):
                tokens = tokens[1:]
        elif t == "taskpolicy":
            tokens = tokens[1:]
            while tokens and tokens[0].startswith("-"):
                tokens = tokens[2:] if tokens[0] in ("-c", "-t", "-l") else tokens[1:]
        else:
            break
    return tokens


def resolve(base, path):
    """The directory path names, or None when it holds an unexpanded variable or substitution."""
    if base is None:
        return None
    full = os.path.normpath(os.path.join(base, os.path.expanduser(os.path.expandvars(path))))
    if "$" in full or "`" in full or not os.path.isdir(full):
        return None
    return full


def push_revs(cwd, args):
    value_opts = {"-o", "--push-option", "--repo", "--receive-pack", "--exec"}
    positional, everything, tags = [], False, False
    i = 0
    while i < len(args):
        a = args[i]
        if a in value_opts:
            i += 2
            continue
        if a in ("--all", "--branches", "--mirror"):
            everything = True
        elif a == "--tags":
            tags = True
        elif a in ("-d", "--delete"):
            return []
        elif not a.startswith("-"):
            positional.append(a)
        i += 1
    revs = []
    if everything:
        revs.append("--branches")
    if tags:
        revs.append("--tags")
    for spec in positional[1:]:
        src = spec.lstrip("+").split(":", 1)[0]
        if not src:
            continue
        if "*" in src:
            revs.append("--branches")
        elif git(cwd, "rev-parse", "--verify", "-q", f"{src}^{{commit}}") is not None:
            revs.append(src)
        else:
            # Usually a variable or $(git branch --show-current): the current branch is the best guess.
            revs.append("HEAD")
    if not revs and len(positional) <= 1:
        revs.append("HEAD")
    return sorted(set(revs), key=revs.index)


GH_FIELDS = {
    "title": {"-t", "--title", "--subject"},
    "body": {"-b", "--body"},
    "body-file": {"-F", "--body-file"},
    "head": {"-H", "--head"},
}
GH_ACTIONS = {
    "pr": {"create", "edit", "comment", "review", "merge"},
    "issue": {"create", "edit", "comment"},
}


def option_values(args, fields):
    """(field, value) for each option in args named in fields; handles --opt=value."""
    found = []
    i = 0
    while i < len(args):
        a = args[i]
        name, value = a, None
        if a.startswith("--") and "=" in a:
            name, value = a.split("=", 1)
        for field, flags in fields.items():
            if name in flags:
                if value is None and i + 1 < len(args):
                    value = args[i + 1]
                    i += 1
                if value is not None:
                    found.append((field, value))
                break
        i += 1
    return found


def gh_values(args):
    return option_values(args, GH_FIELDS)


class BashState:
    def __init__(self, cwd):
        self.cwd = cwd
        self.committing = False
        self.adding = False
        self.messages = []
        self.commit_heredoc = False
        self.heredoc_label = None


def check_bash(command, cwd, out):
    if not re.search(r"\b(git|gh)\b", command):
        return
    stripped, bodies = cut_heredocs(command)
    try:
        parsed = list(segments(stripped))
    except ValueError:
        if re.search(r"\bgit\b.*\bpush\b|\bgh\s+(pr|issue)\s+(create|edit|comment|review|merge)\b", command, re.S):
            out.append((UNPARSED, "this Bash call", ""))
        return
    state = BashState(cwd)
    for tokens in parsed:
        tokens = strip_prefix(strip_redirections(tokens))
        if not tokens:
            continue
        program = os.path.basename(tokens[0])
        if program in ("cd", "pushd"):
            target = tokens[1] if len(tokens) > 1 and tokens[1] != "-" else "~"
            state.cwd = resolve(state.cwd, target)
        elif program == "git":
            check_git(tokens[1:], state, out)
        elif program == "gh":
            check_gh(tokens[1:], state, out)
    if state.heredoc_label:
        ctx = Context(cwd)
        for body in bodies:
            scan_text(body, state.heredoc_label, True, ctx, out)


def check_git(args, state, out):
    cwd = state.cwd
    i = 0
    while i < len(args):
        a = args[i]
        if a == "-C" and i + 1 < len(args):
            cwd = resolve(cwd, args[i + 1])
            i += 2
        elif a in ("-c", "--git-dir", "--work-tree", "--namespace"):
            i += 2
        elif a.startswith("-"):
            i += 1
        else:
            break
    command, rest = (args[i], args[i + 1:]) if i < len(args) else (None, [])
    if command == "add":
        state.adding = True
    elif command == "commit":
        state.committing = True
        for field, value in option_values(rest, {"message": {"-m", "--message"}, "file": {"-F", "--file"}}):
            if HEREDOC_MARK in value or (field == "file" and value == "-"):
                state.commit_heredoc = True
            if field == "message":
                state.messages.append(value)
        state.messages += [a[2:] for a in rest if a.startswith("-m") and len(a) > 2]
    elif command == "push":
        if cwd is None:
            out.append((UNRESOLVED, "git push", ""))
            return
        revs = push_revs(cwd, rest)
        if not revs:
            return
        ctx = Context(cwd)
        scan_commits(ctx, revs, out)
        if state.committing:
            # The commit made earlier in this same call does not exist yet.
            scan_worktree(ctx, state.adding, out)
            if state.commit_heredoc and not state.heredoc_label:
                state.heredoc_label = "commit message"
            for message in state.messages:
                scan_text(message, "commit message", True, ctx, out)


def check_gh(args, state, out):
    while args and args[0] in ("-R", "--repo"):
        args = args[2:]
    if len(args) < 2 or args[1] not in GH_ACTIONS.get(args[0], ()):
        return
    kind, action = args[0], args[1]
    noun = "PR" if kind == "pr" else "issue"
    if action in ("comment", "review"):
        noun += " comment"
    cwd = state.cwd or os.getcwd()
    ctx = Context(cwd)
    head = None
    for field, value in gh_values(args[2:]):
        if HEREDOC_MARK in value or (field == "body-file" and value == "-"):
            state.heredoc_label = f"{noun} body"
            value = value.replace(f"<< {HEREDOC_MARK}", "")
        if field == "title":
            scan_text(value, f"{noun} title", True, ctx, out)
        elif field == "body":
            scan_text(value, f"{noun} body", True, ctx, out)
        elif field == "head":
            head = value.split(":")[-1]
        elif value != "-":
            try:
                with open(os.path.join(cwd, os.path.expanduser(value)), encoding="utf-8", errors="replace") as f:
                    scan_text(f.read(), f"{noun} body", True, ctx, out)
            except OSError as error:
                print(f"privacy_check: cannot read body file: {error}", file=sys.stderr)
    if kind == "pr" and action == "create":
        if state.cwd is None:
            out.append((UNRESOLVED, "gh pr create", ""))
            return
        rev = head if head and git(cwd, "rev-parse", "--verify", "-q", head) else "HEAD"
        scan_commits(ctx, [rev], out)


def check_mcp(tool_input, cwd, out):
    ctx = Context(cwd)

    def walk(value, keys, file_path):
        if isinstance(value, dict):
            path = value.get("path") if isinstance(value.get("path"), str) else file_path
            for k, v in value.items():
                walk(v, keys + [k], path)
        elif isinstance(value, list):
            for i, v in enumerate(value):
                walk(v, keys + [str(i)], file_path)
        elif isinstance(value, str) and keys:
            key = keys[-1]
            if key == "content":
                scan_text(value, file_path or "file content", False, ctx, out, numbered=True)
            else:
                scan_text(value, ".".join(k for k in keys if not k.isdigit()) + " field", True, ctx, out)

    walk(tool_input, [], None)


def reason(event):
    out = []
    cwd = event.get("cwd") or os.getcwd()
    name = event.get("tool_name") or ""
    tool_input = event.get("tool_input") or {}
    if name == "Bash":
        check_bash(tool_input.get("command") or "", cwd, out)
    elif name.startswith("mcp__") and name.rsplit("__", 1)[-1] in MCP_TOOLS:
        check_mcp(tool_input, cwd, out)
    if not out:
        return None
    seen, lines = set(), []
    hint = ""
    if any(c == UNRESOLVED for c, _, _ in out):
        hint = "\nIt could not tell which repository a push is in: use a literal path with cd or git -C."
    if any(c == UNPARSED for c, _, _ in out):
        hint += "\nIt could not parse the command: split it into simpler commands."
    for category, where, _ in out:
        if (category, where) not in seen:
            seen.add((category, where))
            lines.append(f"- {category} at {where}")
    more = f"\n- ...and {len(lines) - MAX_REPORTED} more" if len(lines) > MAX_REPORTED else ""
    return (
        "Privacy check: this would publish personal details to GitHub.\n"
        + "\n".join(lines[:MAX_REPORTED]) + more + hint
        + "\nRemove them (amend or rebase unpushed commits if needed) and retry. If one is a reviewed "
        "false positive, add its exact text on its own line to .privacy-allow at the repo root."
    )


def scan_cli(argv):
    show = "--show" in argv
    argv = [a for a in argv if a != "--show"]
    directory, rev = argv[0], argv[1]
    max_count = int(argv[2]) if len(argv) > 2 else 300
    ctx = Context(os.path.abspath(directory))
    out = []
    scan_commits(ctx, [rev], out, exclude_remotes=False, max_count=max_count)
    for category, where, value in out:
        print(f"{category}\t{where}" + (f"\t{value}" if show else ""))
    print(f"{len(out)} hit(s)", file=sys.stderr)


def main():
    argv = sys.argv[1:]
    if argv[:1] == ["--scan"]:
        scan_cli(argv[1:])
        return
    if "--always" not in argv and os.environ.get("CLAUDE_CODE_REMOTE") != "true":
        return
    try:
        why = reason(json.load(sys.stdin))
        if why:
            print(json.dumps({
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": why,
                }
            }))
    except Exception as error:  # a crash must not block the call it guards
        print(f"privacy_check: {type(error).__name__}: {error}", file=sys.stderr)


if __name__ == "__main__":
    main()
