# IPA Signer — Front-End Design Brief

A spec of everything the app currently does, written so a designer can redesign
the UI from scratch. **The current look (Liquid Glass) is being thrown out.**
Design a clean, native-feeling iOS app — think Apple's own **App Store**,
**Settings**, and **TestFlight**: crisp cards, SF-style typography, generous
spacing, subtle depth, no gimmicks.

---

## 1. What the app is

A **private, single-user iOS app** that signs `.ipa` files using the user's
Apple Developer certificate and installs them on the iPhone — all from the phone.
The actual signing runs remotely on GitHub Actions; the app is a polished client
that:

1. Lets the user pick an IPA (from a browsable catalog, a file, or a URL).
2. Kicks off a remote signing job and shows live progress.
3. Installs the signed result over-the-air.

The user is **the only user**. No onboarding, accounts, social, or multi-user
anything. Optimize for a fast, premium, native feel.

---

## 2. Platform & constraints

- **iPhone only**, portrait. iOS 17+ (designed for iOS 26 aesthetics).
- Light, Dark, and System themes are all required.
- Everything is one-handed reachable; primary actions near the bottom.
- No desktop/tablet layouts needed.

---

## 3. Information architecture (navigation)

A **bottom tab bar** with 2 tabs, plus 2 toolbar buttons in the top bar:

- **Tab 1 — Catalog** (browse apps from repos)
- **Tab 2 — Upload** (sign a file or URL)
- **Top-right toolbar:** Sources (manage repos) + Settings — both push full screens.

A **Sign screen** is pushed modally/fullscreen whenever a signing job starts.

```
┌─────────────────────────────┐
│  Catalog        [📁] [⚙️]    │  ← top bar: title + Sources + Settings
│                              │
│  [ search apps        ]      │
│  ┌──────────────────────┐    │
│  │ icon  Name      [GET] │    │  ← app cards
│  │       dev · v · size  │    │
│  └──────────────────────┘    │
│           …                  │
│                              │
│   [ Catalog ]  [ Upload ]    │  ← bottom tab bar
└─────────────────────────────┘
```

---

## 4. Screens & every element

### 4.1 Catalog tab
Browse installable apps aggregated from all configured AltStore-style repos.

- **Search bar** at top — filters by app name or developer (live).
- **List of app cards**, each showing:
  - App **icon** (remote image; needs a placeholder/fallback)
  - **Name** (bold)
  - Secondary line: **developer · version · size** (any subset that exists)
  - A **GET** button (right side) → starts signing that app
- Card tint: each app may carry a **tint color** (hex) from the repo — used as an
  accent (e.g. the GET button text). Optional.
- **Pull to refresh** reloads all sources.
- **States:**
  - Loading (spinner)
  - Empty ("No apps yet. Add a source from the folder icon.")
  - Populated list

### 4.2 Upload tab
Sign an IPA the user already has, or a direct link.

- A large **"Pick an .ipa from Files"** drop-zone card (taps into the iOS file
  picker). Subtitle: "Sign an IPA already on your device."
- Divider: "— or from a direct URL —"
- A **URL text field** (`https://…/app.ipa`) + a **"Sign from URL"** button.
- Picking a non-`.ipa` shows an error toast.

### 4.3 Sources screen (pushed from 📁)
Manage the AltStore-style repository URLs.

- **Add field** at top: URL input (`https://…/apps.json`) + **"Add source"** button
  (shows a spinner while validating/fetching).
- **List of sources**, each card showing:
  - Source **name** (parsed from the repo JSON)
  - Subtitle: **"N apps"** on success, or **"Failed: <reason>"** in red on error
  - A **delete** (trash) button
- **States:** loading, empty ("No sources yet…"), populated.
- Example source URL the user uses:
  `https://raw.githubusercontent.com/mrdrvt99/Altstore-Repository/main/apps.json`

### 4.4 Settings screen (pushed from ⚙️)
Two sections:

**APPEARANCE**
- A **segmented control**: System / Light / Dark (persists immediately).

**GITHUB CONNECTION**
- **Personal access token** field (obscured) — the GitHub PAT.
- **Repo owner** field (e.g. `MaliceKy`)
- **Repo name** field (e.g. `ipa-signer`)
- **Branch** field (default `main`)
- A primary **"Save & verify"** button — saves to the iOS Keychain and pings the
  GitHub API; shows green "Saved & verified ✓" or a red error message.
- This screen is also the **first-run gate**: if no token/owner/repo is set, the
  app opens straight here.

### 4.5 Sign screen (the centerpiece — needs the most love)
Pushed when a signing job starts. Drives one job end-to-end. This is where the
app should feel **alive and premium**.

**Top: progress card**
- A **phase label** (Uploading / Starting / Queued / Signing / Signed / Failed)
  with a matching status dot/spinner and color.
- A big **percentage** (e.g. `62%`), tabular figures.
- A **horizontal progress bar** (determinate). On error it goes indeterminate/red.
- An **ETA / status line**: `Uploading 40%`, `~18s remaining`, `Almost done…`,
  or `Done`.
- Colors: in-progress = blue accent, success = green, error = red.

**Middle: live console**
- Header "Console" + a **copy console** button.
- A scrolling, **monospace** log that shows:
  - The **live workflow steps** pulled from GitHub Actions, each with a status
    icon: queued (○), in-progress (⟳), success (✓), skipped (⊘), failed (✗).
    Example step names: "Build zsign", "Restore certificate & provisioning
    profile", "Download unsigned IPA", "Sign IPA", "Generate OTA manifest",
    "Publish signed IPA + manifest to a Release".
  - Plus the app's own log lines ("Uploading 7.7 MB…", "Triggered: …", etc.).
- Text is **selectable**.

**Bottom: actions (depend on state)**
- **Success →** a prominent **"Install on this device"** button (green).
- **Failure →** a **"Copy error"** button (red) + a "Open run on GitHub" link.
- **In progress →** optional "Open run on GitHub" link.
- Top-right of the screen: a **share/copy** icon that copies the full log
  (steps + log + error + run URL).

**Progress phases the design must cover, in order:**
1. **Uploading** (only when signing a local file) — real upload % (0→~25%).
2. **Starting** — triggering the workflow (~25%).
3. **Queued** — waiting for a runner.
4. **Signing** — steps run; bar advances via time estimate + step completion.
5. **Signed** — 100%, green, Install button appears.
6. **Failed** — red, error text + copy.

---

## 5. Data shown (models)

**Catalog app** (per card):
- `name`, `iconUrl`, `developer`, `version`, `versionDate`, `sizeBytes`
  (display as MB/GB), `description`, `bundleId`, `tintColor` (hex), `sourceName`.

**Source**:
- `name`, `url`, `appCount`, `error?`.

**Sign job state**:
- `phase`, `percent` (0–100), `etaText`, `steps[]` (name + status + result),
  `logLines[]`, `error?`, `runUrl?`.

---

## 6. Component inventory (for a design system)

- Tab bar (2 tabs: Catalog, Upload) with active/inactive icons
- Top nav bar with title + 1–2 trailing icon buttons + back button on pushed screens
- App card (icon + 2 lines + trailing pill button)
- Source card (icon + 2 lines + trailing delete)
- Search bar
- Text field (normal + obscured/password)
- Segmented control (3 options)
- Primary button (full-width pill) — normal, loading (spinner), and colored
  success/danger variants
- Secondary/tertiary text button (with leading icon)
- Determinate progress bar + circular spinner
- Status pill / phase chip with color states (blue / green / red / amber)
- Monospace console block (scrolling, selectable) with per-line status icons
- Toast/snackbar (e.g. "Log copied", "Please pick a .ipa file")
- Empty states (illustration/icon + message)

---

## 7. States to design for every screen
- **Loading** (initial + refreshing)
- **Empty** (no sources, no apps)
- **Error** (source failed to load, token invalid, sign failed)
- **Success** (verified, signed)
- **Light & Dark** variants of all of the above

---

## 8. Tone / aesthetic direction
- Native iOS, Apple-grade polish. Reference: App Store, TestFlight, Settings.
- SF Pro typography, generous padding, rounded cards, soft shadows/separators.
- One accent color (currently iOS blue `#0A84FF`) + semantic green/red/amber.
- Motion: subtle, purposeful (progress, state transitions). No gimmicky physics.
- **Do not** use heavy glassmorphism/blur as the primary language — it was tried
  and rejected. Clean and legible first.
