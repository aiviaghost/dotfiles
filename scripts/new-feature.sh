#!/usr/bin/env bash
#
# new-feature.sh — spin up a feature worktree across the frontend and backend repos.
#
# Usage: ./new-feature.sh <feature-name>
#        ./new-feature.sh --remove <feature-name>
#
# For each repo it creates a git worktree at .claude/worktrees/<feature-name>
# on a new branch <feature-name> (branched off main), opens a kitty terminal in
# each worktree, and opens VS Code on the backend worktree.
#
# With --remove it instead removes the <feature-name> worktree from both repos.

set -euo pipefail

REMOVE=0
FORCE=0
FEATURE=""
for arg in "$@"; do
  case "$arg" in
    --remove) REMOVE=1 ;;
    --force) FORCE=1 ;;
    -*) echo "error: unknown flag '$arg'" >&2; exit 1 ;;
    *) FEATURE="$arg" ;;
  esac
done

if [[ -z "$FEATURE" ]]; then
  echo "Usage: $(basename "$0") [--remove [--force]] <feature-name>" >&2
  exit 1
fi

if [[ "$FORCE" == 1 && "$REMOVE" != 1 ]]; then
  echo "error: --force only applies together with --remove" >&2
  exit 1
fi

# Directory this script lives in — the parent of frontend/ and backend/.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_BRANCH="main"

# Create (or reuse) a worktree at <repo>/.claude/worktrees/<feature> and echo its path.
create_worktree() {
  local repo="$1"
  local repo_path="$ROOT/$repo"
  local wt_path="$repo_path/.claude/worktrees/$FEATURE"

  if [[ ! -d "$repo_path/.git" ]]; then
    echo "error: $repo_path is not a git repository" >&2
    return 1
  fi

  if [[ -d "$wt_path" ]]; then
    echo "  $repo: worktree already exists at $wt_path — reusing it" >&2
  elif git -C "$repo_path" show-ref --verify --quiet "refs/heads/$FEATURE"; then
    # Branch exists already: attach a worktree to it instead of creating the branch.
    echo "  $repo: branch '$FEATURE' exists — checking it out into a new worktree" >&2
    git -C "$repo_path" worktree add "$wt_path" "$FEATURE" >&2
  else
    git -C "$repo_path" worktree add -b "$FEATURE" "$wt_path" "$BASE_BRANCH" >&2
  fi

  echo "$wt_path"
}

# Remove the worktree at <repo>/.claude/worktrees/<feature> and delete the local
# branch. Warns and continues (rather than aborting) if the worktree has
# uncommitted/untracked changes or the branch can't be deleted.
remove_worktree() {
  local repo="$1"
  local repo_path="$ROOT/$repo"
  local wt_path="$repo_path/.claude/worktrees/$FEATURE"

  if [[ ! -d "$repo_path/.git" ]]; then
    echo "  $repo: not a git repository — skipping" >&2
    return 0
  fi

  if [[ -d "$wt_path" ]]; then
    local -a remove_cmd=(git -C "$repo_path" worktree remove)
    [[ "$FORCE" == 1 ]] && remove_cmd+=(--force)
    remove_cmd+=("$wt_path")

    if "${remove_cmd[@]}" >&2; then
      echo "  $repo: removed worktree at $wt_path" >&2
    else
      echo "  $repo: WARNING — could not remove worktree at $wt_path" >&2
      echo "  $repo:           (likely uncommitted or untracked changes; re-run with --force," >&2
      echo "  $repo:           or 'git -C $repo_path worktree remove --force $wt_path')" >&2
      return 0
    fi
  else
    echo "  $repo: no worktree at $wt_path — skipping worktree removal" >&2
  fi

  # Delete the local branch, if it still exists.
  if git -C "$repo_path" show-ref --verify --quiet "refs/heads/$FEATURE"; then
    if git -C "$repo_path" branch -D "$FEATURE" >&2; then
      echo "  $repo: deleted local branch '$FEATURE'" >&2
    else
      echo "  $repo: WARNING — could not delete local branch '$FEATURE'" >&2
    fi
  fi
}

# Copy the repo's .env into the freshly created worktree, if one exists.
# .env is typically gitignored, so it won't be present in the new worktree.
copy_env() {
  local repo="$1"
  local wt_path="$2"
  local src="$ROOT/$repo/.env"

  if [[ ! -f "$src" ]]; then
    echo "  $repo: no .env at $src — skipping copy" >&2
    return 0
  fi

  if [[ -f "$wt_path/.env" ]]; then
    echo "  $repo: .env already exists in worktree — leaving it untouched" >&2
    return 0
  fi

  cp "$src" "$wt_path/.env"
  echo "  $repo: copied .env into worktree" >&2
}

# Open a detached kitty window sitting in the given directory.
open_terminal() {
  local dir="$1"
  setsid kitty --directory "$dir" >/dev/null 2>&1 < /dev/null &
  disown
}

if [[ "$REMOVE" == 1 ]]; then
  echo "Removing feature '$FEATURE'..."
  remove_worktree frontend
  remove_worktree backend
  echo "Done."
  exit 0
fi

echo "Setting up feature '$FEATURE'..."

FE_WT="$(create_worktree frontend)"
BE_WT="$(create_worktree backend)"

echo "  copying .env files..."
copy_env frontend "$FE_WT"
copy_env backend "$BE_WT"

echo "  opening terminals..."
open_terminal "$FE_WT"
open_terminal "$BE_WT"

echo "  opening VS Code on backend worktree..."
setsid code "$BE_WT" >/dev/null 2>&1 < /dev/null &
disown

echo "Done."
echo "  frontend: $FE_WT"
echo "  backend:  $BE_WT"
