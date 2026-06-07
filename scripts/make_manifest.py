#!/usr/bin/env python3
"""Generate an OTA (itms-services) manifest.plist for a signed IPA.

Usage:
    make_manifest.py <signed.ipa> <https_ipa_url> [display_name_override]

Reads the app's Info.plist out of the IPA to fill in bundle id / version /
title, then prints the manifest plist to stdout.
"""
import plistlib
import sys
import zipfile


def read_info_plist(ipa_path: str) -> dict:
    with zipfile.ZipFile(ipa_path) as zf:
        # Payload/<App>.app/Info.plist
        candidates = [
            n for n in zf.namelist()
            if n.startswith("Payload/")
            and n.count("/") == 2
            and n.endswith(".app/Info.plist")
        ]
        if not candidates:
            raise SystemExit("Could not find Payload/*.app/Info.plist in IPA")
        with zf.open(candidates[0]) as f:
            return plistlib.load(f)


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    ipa_path, ipa_url = sys.argv[1], sys.argv[2]
    name_override = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else None

    info = read_info_plist(ipa_path)
    bundle_id = info.get("CFBundleIdentifier", "com.unknown.app")
    version = (
        info.get("CFBundleShortVersionString")
        or info.get("CFBundleVersion")
        or "1.0"
    )
    title = (
        name_override
        or info.get("CFBundleDisplayName")
        or info.get("CFBundleName")
        or bundle_id
    )

    manifest = {
        "items": [
            {
                "assets": [
                    {"kind": "software-package", "url": ipa_url},
                ],
                "metadata": {
                    "bundle-identifier": bundle_id,
                    "bundle-version": str(version),
                    "kind": "software",
                    "title": title,
                },
            }
        ]
    }
    sys.stdout.buffer.write(plistlib.dumps(manifest, fmt=plistlib.FMT_XML))


if __name__ == "__main__":
    main()
