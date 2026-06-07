# IPA Signer

A private, single-user iOS app that signs `.ipa` files **in GitHub Actions**
(using your Apple Developer certificate) and installs the signed result on your
iPhone over-the-air. Inspired by AppDB / Feather / AppSign, but with all signing
done in CI — nothing runs on your Mac after the initial bootstrap.

```
iPhone (this app)                 GitHub Actions (Ubuntu)
  pick / browse IPA  ──trigger──▶  download → zsign → manifest
  poll run status    ◀──status──   publish signed IPA + manifest to a Release
  tap "Install"  ──itms-services──▶ iOS installs the signed app
```

## How it works

1. You give the app an IPA (pick from Files, or browse a catalog source).
2. The app triggers the `Sign IPA` workflow via the GitHub API, passing a unique
   `run_tag`. (Uploaded IPAs are first pushed to a throwaway Release so CI can
   download them.)
3. CI builds [`zsign`](https://github.com/zhlynn/zsign), signs the IPA with your
   `.p12` + `.mobileprovision` (stored as repo secrets), generates an OTA
   `manifest.plist`, and publishes both as assets on a Release tagged `run_tag`.
4. The app polls the run, finds it by name (`sign-<run_tag>`), and once it
   succeeds opens `itms-services://…/manifest.plist` to install.

---

## One-time setup

### 1. Create the signing repo
Create a GitHub repo (e.g. `ipa-signer`) and push this project to it.

> **OTA install requires the signed Release assets to be reachable without
> auth.** The simplest path is a **public** repo. The signed IPAs are locked to
> *your* device UDID, so they won't install on anyone else's device — but the
> binaries are technically downloadable. If that bothers you, switch hosting to
> GitHub Pages or an on-device server later (see "Privacy" below).

### 2. Register your device & build a provisioning profile
On the [Apple Developer site](https://developer.apple.com/account):
- **Certificates** → create an **iOS Distribution** (or Development) certificate.
- Export it from Keychain Access as a `.p12` (right-click the cert → Export).
  Set a password.
- **Devices** → register your iPhone's **UDID** (get it via Finder/Xcode, or
  `idevice_id -l`).
- **Profiles** → create an **Ad Hoc** distribution profile that includes your
  certificate and your device. Download the `.mobileprovision`.
  - Use a **wildcard App ID** (`*`) so the same profile signs any IPA, *unless*
    the app needs special entitlements (push, app groups, etc.), in which case
    make a profile per bundle id.

### 3. Add the secrets to the repo
Base64-encode the two files and set them as **Actions secrets**:

| Secret                   | Value                                   |
| ------------------------ | --------------------------------------- |
| `P12_BASE64`             | base64 of your `.p12`                   |
| `P12_PASSWORD`           | the password you set when exporting     |
| `MOBILEPROVISION_BASE64` | base64 of your `.mobileprovision`       |

Set them with the CLI:
```bash
gh secret set P12_BASE64 < <(base64 -i cert.p12)
gh secret set MOBILEPROVISION_BASE64 < <(base64 -i profile.mobileprovision)
gh secret set P12_PASSWORD            # paste when prompted
```

### 4. Create a Personal Access Token for the app
Fine-grained PAT scoped to **only this repo** with:
- **Actions**: Read and write
- **Contents**: Read and write

Paste it into the app's **Settings** along with the repo owner and name.

### 5. Bootstrap-install this app onto your phone (once)
This signer app is itself an IPA, so the first install needs a one-time push from
your Mac. Any of:
- `flutter build ipa` then install via Xcode / Apple Configurator, **or**
- Sideloadly / AltStore.

After that, the app re-signs *itself* through this same pipeline before the
profile expires (1 year for paid accounts).

---

## Using it
1. **Settings** → enter PAT, owner, repo, and any catalog source URLs.
   (Catalog sources are AltStore-style JSON: `{ "name": ..., "apps": [...] }`.)
2. **Upload** tab → pick an `.ipa` from Files, or paste a direct URL.
   **Catalog** tab → browse sources and tap an app.
3. Watch the sign log; when it shows **Signed ✓**, tap **Install on this device**.
4. First launch of a newly installed app: trust the certificate at
   *Settings → General → VPN & Device Management*.

---

## Notes & limits
- **Profile expiry**: Ad Hoc profiles last 1 year (paid account). Re-sign apps
  after renewing the profile + updating the `MOBILEPROVISION_BASE64` secret.
- **Entitlements**: zsign reuses entitlements from the provisioning profile. A
  wildcard profile can't grant push/app-groups/etc.; use a matching App ID
  profile for apps that need them.
- **Privacy**: signed IPAs live on public Release assets (see step 1). They only
  install on your registered UDID. To avoid public hosting entirely you'd move
  to a Feather-style on-device HTTPS server — not implemented in this slice.
- **This is a personal tool.** Only sign apps you have the right to install.

## Repo layout
- `.github/workflows/sign-ipa.yml` — the signing pipeline (zsign + release).
- `scripts/make_manifest.py` — builds the OTA manifest from the signed IPA.
- `lib/services/` — config (keychain), GitHub API client, catalog parser.
- `lib/screens/` — settings, home (catalog/upload), sign+install.
