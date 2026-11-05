#!/usr/bin/env bash
# Install the pinned safeworld CLI release into ~/.local/bin (the same tarball CI uses).
# Pin, never "latest": the CLI's flags and exit codes are the contract the skills script.
set -euo pipefail
VERSION="${SAFEWORLD_CLI_VERSION:-cli-v0.1.5}"
REPO="${SAFEWORLD_CLI_REPO:-safeworldai/customer-examples}"   # the mirror of safeworld-stack's CLI releases
DEST="${SAFEWORLD_CLI_DEST:-$HOME/.local/bin}"
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) target=aarch64-apple-darwin ;;
  Darwin-x86_64) target=x86_64-apple-darwin ;;
  Linux-x86_64) target=x86_64-unknown-linux-gnu ;;
  Linux-aarch64) target=aarch64-unknown-linux-gnu ;;
  *) echo "unsupported platform $(uname -s)-$(uname -m)" >&2; exit 2 ;;
esac
semver="${VERSION#cli-v}"
asset="safeworld-${semver}-${target}.tar.gz"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gh release download "$VERSION" --repo "$REPO" --pattern "$asset" --pattern "$asset.sha256" --dir "$tmp"
(cd "$tmp" && shasum -a 256 -c "$asset.sha256")
tar -xzf "$tmp/$asset" -C "$tmp"
mkdir -p "$DEST"
install -m 0755 "$tmp"/safeworld-*/safeworld "$DEST/safeworld"
"$DEST/safeworld" --version
echo "installed to $DEST/safeworld (add $DEST to PATH if needed)"
