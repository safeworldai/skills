#!/usr/bin/env bash
# Preflight for the safeworld-platform skill. Run it first, every session.
# It stops at the first missing thing and says how to get it. Exit 2 means something is missing.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail() { printf 'preflight: %s\n' "$1" >&2; exit 2; }

[ -n "${SAFEWORLD_API_URL:-}" ] || fail "SAFEWORLD_API_URL is unset. Export your organization's SafeWorld API base URL (SafeWorld gives it to you with your account)."
[ -n "${SAFEWORLD_API_KEY:-}" ] || fail "SAFEWORLD_API_KEY is unset. Mint an API key in the SafeWorld web app under Settings → API Keys (copy it once), then: export SAFEWORLD_API_KEY=<key>. Never write it into a file in the repo."
for tool in jq curl ffmpeg; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is not installed. The CLI decodes suite clips with ffmpeg 5.1 or later; jq and curl read the API listings."
done
command -v safeworld >/dev/null 2>&1 || fail "the safeworld CLI is not on PATH. Run: $here/install_safeworld_cli.sh (then put ~/.local/bin on PATH)."

printf '%s' "$SAFEWORLD_API_KEY" | "$here/sw" auth login --api-key-stdin >/dev/null \
  || fail "auth login failed. Check SAFEWORLD_API_URL ($SAFEWORLD_API_URL) and that the key is current."
"$here/sw" auth status
printf 'preflight: ok (%s)\n' "$(safeworld --version 2>/dev/null | head -1)"
