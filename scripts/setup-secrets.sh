#!/usr/bin/env bash
# Sets the three GitHub Actions secrets the signing workflow needs.
#
# Usage:
#   scripts/setup-secrets.sh /path/to/cert.p12 /path/to/profile.mobileprovision
#
# You'll be prompted for the .p12 password. Run it from inside the repo (it
# targets whatever repo `gh` resolves for the current directory), or set
# GH_REPO=MaliceKy/ipa-signer first.
set -euo pipefail

P12="${1:-}"
PROFILE="${2:-}"

if [[ -z "$P12" || -z "$PROFILE" ]]; then
  echo "Usage: $0 <cert.p12> <profile.mobileprovision>" >&2
  exit 1
fi
[[ -f "$P12" ]]     || { echo "No such file: $P12" >&2; exit 1; }
[[ -f "$PROFILE" ]] || { echo "No such file: $PROFILE" >&2; exit 1; }

read -r -s -p "Password for $P12: " P12_PASSWORD
echo

echo "Setting P12_BASE64…"
base64 -i "$P12" | gh secret set P12_BASE64

echo "Setting MOBILEPROVISION_BASE64…"
base64 -i "$PROFILE" | gh secret set MOBILEPROVISION_BASE64

echo "Setting P12_PASSWORD…"
printf '%s' "$P12_PASSWORD" | gh secret set P12_PASSWORD

echo
echo "Done. Current secrets:"
gh secret list
