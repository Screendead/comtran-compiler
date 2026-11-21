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
import hashlib
import json
import os
import re
import shlex
import subprocess
import sys

MAX_COMMITS = 2000
GIT_TIMEOUT_S = 25
MAX_REPORTED = 8

# sha256 of the lowercased surname and of first name + surname, so neither appears in the
# public repos this file is vendored into. The bare surname is also an English word, so it
# counts only when capitalised; the joined form (a username) counts in any case.
SURNAME_DIGEST = "b21a859f6d74709fbafa239f255cbf12f052613c758f680a746a38b443b11998"
FULL_NAME_DIGEST = "1fa2c8471e8c12a759ce19d892b49750985e12c1251edd384876c729aa2caed8"

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
DEVICE_WORDS = re.compile(r"(?i)udid|device|iphone")
MONEY = re.compile(
    r"(?<![\w\\$])(?:[£€]\s?\d[\d,]*(?:\.\d+)?"
    r"|\$(?:\d{1,3}(?:,\d{3})+|\d+\.\d{2}(?!\d)|\d{2,}(?![\w}])|\d(?=\s?(?:/|per\b|k\b|m\b|bn\b))))"
    r"|\b\d[\d,]*(?:\.\d+)?\s?(?:GBP|USD|EUR)\b"
)
# Money-shaped text in code (a compiler's edited-picture output, say) is not money.
CODE_SPAN = re.compile(r"`[^`]*`")
FENCE = re.compile(r"^\s*(```|~~~)")
COPYRIGHT = re.compile(r"(?i)copyright|©|\(c\)")
WORD = re.compile(r"[A-Za-z]+")
CAMEL = re.compile(r"[A-Z]?[a-z]+|[A-Z]+(?![a-z])")


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


def line_hits(line, prose, ctx):
    """(category, start, end) for each personal detail in one line."""
    for m in EMAIL.finditer(line):
        if not email_allowed(m, ctx):
            yield "email address", m.start(), m.end()
    for m in HOME_PATH.finditer(line):
        if m.group(2).lower() not in PLACEHOLDER_USERS:
            yield "local home path", m.start(), m.end()
    for m in UDID.finditer(line):
        yield "device UDID", m.start(), m.end()
    for m in HEX40.finditer(line):
        if DEVICE_WORDS.search(line[max(0, m.start() - 40):m.end() + 40]):
            yield "device UDID", m.start(), m.end()
    if not COPYRIGHT.search(line):
        for run in WORD.finditer(line):
            for part in CAMEL.finditer(run.group(0)):
                word = part.group(0)
                if len(word) == 6 and word[0].isupper():
                    digest, want = hashlib.sha256(word.lower().encode()).hexdigest(), SURNAME_DIGEST
                elif len(word) == 10:
                    digest, want = hashlib.sha256(word.lower().encode()).hexdigest(), FULL_NAME_DIGEST
                else:
                    continue
                if digest == want:
                    start = run.start() + part.start()
                    yield "owner's surname", start, start + len(word)
    if prose:
        code = [m.span() for m in CODE_SPAN.finditer(line)]
        for m in MONEY.finditer(line):
            if not any(a <= m.start() < b for a, b in code):
                yield "money amount", m.start(), m.end()


def allowed(line, start, end, ctx):
    for literal in ctx.allow:
        i = line.find(literal)
        while i != -1:
            if i <= start and end <= i + len(literal):
                return True
            i = line.find(literal, i + 1)
    return False


def scan_text(text, label, prose, ctx, out, numbered=None):
    """Appends (category, location, value) for each hit; location is label[:line]."""
    lines = text.splitlines()
    fenced = False
    for n, line in enumerate(lines, 1):
        if prose and FENCE.match(line):
            fenced = not fenced
        for category, start, end in line_hits(line, prose and not fenced, ctx):
            if not allowed(line, start, end, ctx):
                if numbered or (numbered is None and len(lines) > 1):
                    where = f"{label}:{n}" if numbered else f"{label} line {n}"
                else:
                    where = label
                out.append((category, where, line[start:end]))


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
        scan_text(message, f"commit {sha} message", True, ctx, out, numbered=False)
        path, n, in_header = None, 0, True
        for line in diff.splitlines():
            if line.startswith("diff --git "):
                path, in_header = None, True
            elif in_header and line.startswith("+++ "):
                path = None if line[4:] == "/dev/null" else line[4:].removeprefix("b/")
            elif line.startswith("@@"):
                in_header = False
                m = re.match(r"@@ -\S+ \+(\d+)", line)
                n = int(m.group(1)) if m else 0
            elif not in_header and path and line.startswith("+"):
                before = len(out)
                scan_text(line[1:], f"{path}:{n}", False, ctx, out, numbered=False)
                for i in range(before, len(out)):
                    category, where, value = out[i]
                    out[i] = (category, f"{where} (commit {sha})", value)
                n += 1


# ---- command parsing -------------------------------------------------------------------

SEPARATORS = {";", "&&", "||", "|", "&", "(", ")", "\n", "|&", ";;"}
WRAPPERS = {"command", "builtin", "exec", "time", "noglob", "nohup"}


def segments(command):
    lex = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>\n")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    tokens = list(lex)
    current = []
    for i, token in enumerate(tokens):
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
    for i, token in enumerate(tokens):
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
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t) or t in WRAPPERS:
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
    return os.path.normpath(os.path.join(base, os.path.expanduser(os.path.expandvars(path))))


def heredoc_bodies(command):
    pattern = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_]\w*)\1[^\n]*\n(.*?)\n\s*\2\s*(?:\n|\)|$)", re.S)
    return [m.group(3) for m in pattern.finditer(command)]


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
            print(f"privacy_check: cannot resolve push source {src!r}", file=sys.stderr)
    if not revs and not everything and not tags and len(positional) <= 1:
        revs.append("HEAD")
    return revs


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


def gh_values(args):
    found = []
    i = 0
    while i < len(args):
        a = args[i]
        name, value = a, None
        if a.startswith("--") and "=" in a:
            name, value = a.split("=", 1)
        for field, flags in GH_FIELDS.items():
            if name in flags:
                if value is None and i + 1 < len(args):
                    value = args[i + 1]
                    i += 1
                if value is not None:
                    found.append((field, value))
                break
        i += 1
    return found


def check_bash(command, cwd, out):
    if not re.search(r"\b(git|gh)\b", command):
        return
    try:
        parsed = list(segments(command))
    except ValueError as error:
        print(f"privacy_check: could not parse command ({error}); checking HEAD", file=sys.stderr)
        if re.search(r"\bgit\b.*\bpush\b", command, re.S):
            scan_commits(Context(cwd), ["HEAD"], out)
        return
    for tokens in parsed:
        tokens = strip_prefix(strip_redirections(tokens))
        if not tokens:
            continue
        program = os.path.basename(tokens[0])
        if program in ("cd", "pushd"):
            target = tokens[1] if len(tokens) > 1 and tokens[1] != "-" else "~"
            cwd = resolve(cwd, target)
        elif program == "git":
            check_git(tokens[1:], cwd, out)
        elif program == "gh":
            check_gh(tokens[1:], cwd, command, out)


def check_git(args, cwd, out):
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
    if i < len(args) and args[i] == "push":
        revs = push_revs(cwd, args[i + 1:])
        if revs:
            scan_commits(Context(cwd), revs, out)


def check_gh(args, cwd, command, out):
    while args and args[0] in ("-R", "--repo"):
        args = args[2:]
    if len(args) < 2 or args[1] not in GH_ACTIONS.get(args[0], ()):
        return
    kind, action = args[0], args[1]
    noun = "PR" if kind == "pr" else "issue"
    if action in ("comment", "review"):
        noun += " comment"
    ctx = Context(cwd)
    head = None
    for field, value in gh_values(args[2:]):
        if field == "title":
            scan_text(value, f"{noun} title", True, ctx, out)
        elif field == "body":
            scan_text(value, f"{noun} body", True, ctx, out)
        elif field == "head":
            head = value.split(":")[-1]
        elif value == "-":
            for body in heredoc_bodies(command):
                scan_text(body, f"{noun} body", True, ctx, out)
        else:
            try:
                with open(resolve(cwd, value), encoding="utf-8", errors="replace") as f:
                    scan_text(f.read(), f"{noun} body", True, ctx, out)
            except OSError as error:
                print(f"privacy_check: cannot read body file: {error}", file=sys.stderr)
    if kind == "pr" and action == "create":
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
    for category, where, _ in out:
        if (category, where) not in seen:
            seen.add((category, where))
            lines.append(f"- {category} at {where}")
    more = f"\n- ...and {len(lines) - MAX_REPORTED} more" if len(lines) > MAX_REPORTED else ""
    return (
        "Privacy check: this would publish personal details to GitHub.\n"
        + "\n".join(lines[:MAX_REPORTED]) + more
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
