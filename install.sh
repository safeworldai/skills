#!/usr/bin/env bash
# Install the safeworld CLI into ~/.local/bin from this repository's public Releases page.
# A person runs this script, one time per machine:
#
#   curl -fsSL https://raw.githubusercontent.com/safeworldai/skills/main/install.sh | bash
#
# No GitHub account is necessary. The script checks the SHA-256 of the download.
# It installs the newest release. The agent guide ships inside the CLI, so the newest CLI
# always has the guide that matches it. Set SAFEWORLD_CLI_VERSION (for example cli-v0.2.0)
# to pin a release, as a CI job must.
set -euo pipefail
REPO="${SAFEWORLD_CLI_REPO:-safeworldai/skills}"   # the public release channel; set it to use another mirror
DEST="${SAFEWORLD_CLI_DEST:-$HOME/.local/bin}"
VERSION="${SAFEWORLD_CLI_VERSION:-}"
if [ -z "$VERSION" ]; then
  # /releases/latest redirects to the newest release; its last path part is the tag.
  latest="$(curl -fsSLI --retry 3 -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")" \
    || { echo "cannot find the newest release of ${REPO}; set SAFEWORLD_CLI_VERSION" >&2; exit 2; }
  VERSION="${latest##*/}"
fi
case "$VERSION" in
  cli-v[0-9]*) ;;
  *) echo "unexpected release tag '$VERSION' (expected cli-vX.Y.Z); set SAFEWORLD_CLI_VERSION" >&2; exit 2 ;;
esac
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) target=aarch64-apple-darwin ;;
  Darwin-x86_64) target=x86_64-apple-darwin ;;
  Linux-x86_64) target=x86_64-unknown-linux-gnu ;;
  Linux-aarch64) target=aarch64-unknown-linux-gnu ;;
  *) echo "unsupported platform $(uname -s)-$(uname -m); on Windows, download the .zip from https://github.com/${REPO}/releases" >&2; exit 2 ;;
esac
semver="${VERSION#cli-v}"
asset="safeworld-${semver}-${target}.tar.gz"
base="https://github.com/${REPO}/releases/download/${VERSION}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
for file in "$asset" "$asset.sha256"; do
  curl -fsSL --retry 3 -o "$tmp/$file" "$base/$file" || { echo "download failed: $base/$file" >&2; exit 2; }
done
if command -v shasum >/dev/null 2>&1; then (cd "$tmp" && shasum -a 256 -c "$asset.sha256"); else (cd "$tmp" && sha256sum -c "$asset.sha256"); fi
tar -xzf "$tmp/$asset" -C "$tmp"
mkdir -p "$DEST"
install -m 0755 "$tmp"/safeworld-*/safeworld "$DEST/safeworld"
"$DEST/safeworld" --version
echo "installed to $DEST/safeworld"
case ":$PATH:" in
  *":$DEST:"*) ;;
  *) echo "$DEST is not on PATH. Add this line to your shell profile: export PATH=\"$DEST:\$PATH\"" ;;
esac
