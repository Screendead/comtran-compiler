#!/usr/bin/env bash
# Stop hook: do not end a turn while commits exist only on this machine.
# Jack's rule (2026-11-20): push every branch before work stops, so the
# cloud Launchpad refresh can read the work on GitHub. See CLAUDE.md.
#
# It checks the branch checked out here, and recent local branches that no
# other worktree has checked out (another session owns those). It blocks the
# stop once and names each branch. If the same turn tries to stop again, it
# lets it stop and shows Jack what is still unpushed, so it cannot loop.

input=$(cat 2>/dev/null)
second=0
case "$input" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) second=1 ;; esac

cd "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
remote=origin
git remote get-url "$remote" >/dev/null 2>&1 || remote=$(git remote | head -n 1)
[ -n "$remote" ] || exit 0

default=$(git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null)
default=${default#"$remote"/}
if [ -z "$default" ]; then
  for b in main master; do
    if git show-ref --verify --quiet "refs/remotes/$remote/$b"; then default=$b; break; fi
  done
fi

here=$(git symbolic-ref -q --short HEAD 2>/dev/null)
# Branches checked out in other worktrees belong to other sessions.
others=$(git worktree list --porcelain 2>/dev/null | awk -v top="$(git rev-parse --show-toplevel)" '
  /^worktree /{wt=substr($0,10)} /^branch /{b=substr($0,8); sub("^refs/heads/","",b); if (wt!=top) print b}')

now=$(date +%s)
window=$((3 * 86400))
lines=""
add() { lines="$lines
  - $1"; }

if [ -z "$here" ]; then
  n=$(git rev-list --count HEAD --not --remotes 2>/dev/null || echo 0)
  [ "$n" -gt 0 ] && add "detached HEAD: $n commit(s) not on GitHub. Push: git push $remote HEAD:refs/heads/wip/<short-name>"
fi

while IFS='|' read -r br ts track; do
  [ -n "$br" ] || continue
  case "$track" in *gone*) continue ;; esac
  if [ "$br" != "$here" ]; then
    printf '%s\n' "$others" | grep -qxF "$br" && continue
    [ $((now - ts)) -le $window ] || continue
  fi
  n=$(git rev-list --count "refs/heads/$br" --not --remotes 2>/dev/null || echo 0)
  [ "$n" -gt 0 ] || continue
  if [ -n "$default" ] && [ "$br" = "$default" ]; then
    add "$br (the default branch): $n commit(s) not on GitHub. Do not push $br itself. Push: git push $remote $br:refs/heads/wip/<short-name>"
  else
    add "$br: $n commit(s) not on GitHub. Push: git push -u $remote $br"
  fi
done < <(git for-each-ref --format='%(refname:short)|%(committerdate:unix)|%(upstream:track)' refs/heads)

[ -n "$lines" ] || exit 0

if [ "$second" = 1 ]; then
  text="Unpushed work is still only on this Mac:$lines"
  esc=$(printf '%s' "$text" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN{ORS="\\n"} {print}')
  printf '{"systemMessage": "%s"}\n' "$esc"
  exit 0
fi

cat >&2 <<EOF
Push before you stop (Jack's rule, 2026-11-20; see CLAUDE.md). These branches have commits that are only on this machine:$lines
Push each one now, then finish your turn. Never force-push. This rule overrides any older line that says to keep commits local or to ask before you push a branch. If a branch has an open PR and its CI must not run yet, or a required pre-push check fails, push the commits to wip/<branch> instead. If the sandbox blocks git push, run it outside the sandbox. If a push fails, tell Jack the error and stop.
EOF
exit 2
