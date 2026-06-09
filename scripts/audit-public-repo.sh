#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

blockers=()
warnings=()
scanned=0

add_blocker() { blockers+=("$1"); }
add_warning() { warnings+=("$1"); }

while IFS= read -r -d '' file; do
  rel="${file#./}"
  scanned=$((scanned + 1))

  case "$rel" in
    .git/*|target/*|tmp/*|storage/*|uploads/*|media/*) continue ;;
  esac

  case "$rel" in
    pass-*|pass-*/*|*.bak|*.orig|*.rej|*.tmp|*.swp|*~|helper.txt|helper-*.txt|scratch.*|scratch/*|*.patch|*.patch.tmp)
      add_blocker "$rel looks like a local pass, backup, helper, or scratch artifact."
      ;;
  esac

  case "$rel" in
    .env|.env.*)
      if [[ "$rel" != ".env.example" ]]; then
        add_blocker "$rel is a local env file and must not be public."
      fi
      ;;
  esac

  case "$rel" in
    *secret*|*credential*|*private-key*|*seed-phrase*)
      add_blocker "$rel looks secret-related and should be reviewed before public commit."
      ;;
  esac

  case "$rel" in
    *.rs|*.toml|*.yml|*.yaml|*.sh|Dockerfile|.env.example)
      text="$(cat "$file")"
      if grep -Eqi 'Pass [0-9]+|This pass|pass-[0-9]+' <<<"$text"; then
        add_blocker "$rel contains pass/internal iteration wording."
      fi
      if grep -Eqi 'cloudjkt|spark\.user\.|/home/karyra|/root/|/home/' <<<"$text"; then
        add_blocker "$rel contains machine, staging, or private path details."
      fi
      if grep -Eqi 'BEGIN (RSA|OPENSSH|PRIVATE) KEY|AKIA[0-9A-Z]{16}|sk_live_|xox[baprs]-' <<<"$text"; then
        add_blocker "$rel appears to contain a secret token or private key."
      fi
      ;;
  esac
done < <(find . -type f -print0)

if [[ ! -f Cargo.toml ]]; then add_blocker "Cargo.toml is missing."; fi
if [[ ! -f Cargo.lock ]]; then add_blocker "Cargo.lock is missing; application repos should commit lockfiles."; fi
if [[ ! -f .env.example ]]; then add_blocker ".env.example is missing."; fi
if [[ ! -f scripts/check-public.sh ]]; then add_warning "scripts/check-public.sh is missing."; fi

if grep -q '^/target/' .gitignore 2>/dev/null; then :; else add_warning ".gitignore should ignore /target/."; fi
if grep -q '^pass-\*/' .gitignore 2>/dev/null; then :; else add_warning ".gitignore should ignore local pass folders."; fi

printf 'Spark API public repo audit
'
printf '===========================
'
printf 'Files scanned: %s
' "$scanned"
printf 'Warnings: %s
' "${#warnings[@]}"
printf 'Blockers: %s
' "${#blockers[@]}"

if ((${#warnings[@]})); then
  printf '
Warnings:
'
  for item in "${warnings[@]}"; do printf -- '- %s
' "$item"; done
fi

if ((${#blockers[@]})); then
  printf '
Blockers:
' >&2
  for item in "${blockers[@]}"; do printf -- '- %s
' "$item" >&2; done
  exit 1
fi

printf '
Public repo hygiene looks clean.
'
