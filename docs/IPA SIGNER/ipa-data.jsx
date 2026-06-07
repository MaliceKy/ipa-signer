// ipa-data.jsx — mock content for the IPA Signer prototype (exported to window)
(function () {
  // tint colors are used as per-app accents (GET button, monogram bg)
  const APPS = [
    { id: 'provenance', name: 'Provenance', developer: 'Provenance Team', version: '3.0.2', versionDate: '2026-05-28', sizeBytes: 78_400_000, tint: '#E8453C', cat: 'Emulators', source: 'OpenRetro Repo', bundleId: 'org.provenance-emu.provenance', desc: 'Multi-system retro console emulator with a polished native library UI.' },
    { id: 'utm', name: 'UTM', developer: 'Turing Software', version: '4.6.4', versionDate: '2026-06-01', sizeBytes: 142_800_000, tint: '#7B61FF', cat: 'Utilities', source: 'OpenRetro Repo', bundleId: 'com.utmapp.UTM', desc: 'Run full virtual machines — Windows, Linux and more — on your iPhone.' },
    { id: 'flux', name: 'Flux Player', developer: 'Aria Labs', version: '1.9.0', versionDate: '2026-05-19', sizeBytes: 33_100_000, tint: '#0A84FF', cat: 'Media', source: 'Aria Apps', bundleId: 'io.arialabs.flux', desc: 'A gorgeous local media player with gapless playback and AirPlay.' },
    { id: 'nestor', name: 'Nestor', developer: 'Pixelware', version: '2.4.1', versionDate: '2026-04-30', sizeBytes: 21_700_000, tint: '#34C759', cat: 'Emulators', source: 'OpenRetro Repo', bundleId: 'com.pixelware.nestor', desc: '8-bit console emulator with save states and controller support.' },
    { id: 'tinker', name: 'Tinker', developer: 'Lo-Fi Tools', version: '0.8.3', versionDate: '2026-05-12', sizeBytes: 12_400_000, tint: '#FF9F0A', cat: 'Tweaks', source: 'Lo-Fi Tweaks', bundleId: 'fi.lofi.tinker', desc: 'Customize system toggles, fonts and haptics without a jailbreak.' },
    { id: 'beacon', name: 'Beacon', developer: 'Northwind', version: '5.2.0', versionDate: '2026-06-03', sizeBytes: 48_900_000, tint: '#FF375F', cat: 'Utilities', source: 'Aria Apps', bundleId: 'co.northwind.beacon', desc: 'Self-hosted file sync and remote access, end-to-end encrypted.' },
    { id: 'cassette', name: 'Cassette', developer: 'Tape Deck Inc.', version: '3.7.2', versionDate: '2026-05-22', sizeBytes: 27_300_000, tint: '#BF5AF2', cat: 'Media', source: 'Aria Apps', bundleId: 'com.tapedeck.cassette', desc: 'Offline-first music player with a tactile, skeuomorphic deck.' },
    { id: 'gridrunner', name: 'GridRunner', developer: 'Hexbyte', version: '1.2.5', versionDate: '2026-03-18', sizeBytes: 9_800_000, tint: '#64D2FF', cat: 'Games', source: 'Lo-Fi Tweaks', bundleId: 'com.hexbyte.gridrunner', desc: 'A neon arcade shooter built for one-handed play.' },
    { id: 'almanac', name: 'Almanac', developer: 'Field Notes Co.', version: '2.0.0', versionDate: '2026-05-09', sizeBytes: 18_600_000, tint: '#30D158', cat: 'Utilities', source: 'OpenRetro Repo', bundleId: 'com.fieldnotes.almanac', desc: 'Hyperlocal weather, tides and golden-hour tracking.' },
    { id: 'forge', name: 'Forge', developer: 'Anvil Studio', version: '4.1.0', versionDate: '2026-06-05', sizeBytes: 56_200_000, tint: '#FF9500', cat: 'Tweaks', source: 'Lo-Fi Tweaks', bundleId: 'studio.anvil.forge', desc: 'Theme engine for icons, widgets and the lock screen.' },
  ];

  const SOURCES = [
    { id: 's1', name: 'OpenRetro Repo', url: 'https://raw.githubusercontent.com/mrdrvt99/Altstore-Repository/main/apps.json', appCount: 4 },
    { id: 's2', name: 'Aria Apps', url: 'https://aria.dev/altstore/apps.json', appCount: 3 },
    { id: 's3', name: 'Lo-Fi Tweaks', url: 'https://lofi.fi/repo/apps.json', appCount: 3 },
    { id: 's4', name: 'Mirror — backup', url: 'https://cdn.example.net/old/apps.json', appCount: 0, error: 'Could not reach host (timeout)' },
  ];

  // installed history — the Library tab
  const LIBRARY = [
    { id: 'l1', appId: 'provenance', name: 'Provenance', tint: '#E8453C', version: '3.0.2', sizeBytes: 78_400_000, installedAt: '2026-06-05T14:22:00', sourceName: 'OpenRetro Repo', bundleId: 'org.provenance-emu.provenance',
      history: [ { version: '3.0.2', date: '2026-06-05', size: 78_400_000 }, { version: '2.9.0', date: '2026-04-11', size: 76_100_000 }, { version: '2.7.3', date: '2026-02-02', size: 74_900_000 } ] },
    { id: 'l2', appId: 'flux', name: 'Flux Player', tint: '#0A84FF', version: '1.9.0', sizeBytes: 33_100_000, installedAt: '2026-06-04T09:10:00', sourceName: 'Aria Apps', bundleId: 'io.arialabs.flux',
      history: [ { version: '1.9.0', date: '2026-06-04', size: 33_100_000 }, { version: '1.8.2', date: '2026-05-01', size: 32_400_000 } ] },
    { id: 'l3', appId: 'tinker', name: 'Tinker', tint: '#FF9F0A', version: '0.8.3', sizeBytes: 12_400_000, installedAt: '2026-05-29T18:47:00', sourceName: 'Lo-Fi Tweaks', bundleId: 'fi.lofi.tinker',
      history: [ { version: '0.8.3', date: '2026-05-29', size: 12_400_000 } ] },
    { id: 'l4', appId: 'beacon', name: 'Beacon', tint: '#FF375F', version: '5.1.4', sizeBytes: 48_100_000, installedAt: '2026-05-20T11:05:00', sourceName: 'Aria Apps', bundleId: 'co.northwind.beacon', updateAvailable: '5.2.0',
      history: [ { version: '5.1.4', date: '2026-05-20', size: 48_100_000 }, { version: '5.0.0', date: '2026-03-30', size: 47_200_000 } ] },
  ];

  // GitHub Actions workflow steps for the Sign screen
  const SIGN_STEPS = [
    'Build zsign',
    'Restore certificate & provisioning profile',
    'Download unsigned IPA',
    'Sign IPA',
    'Generate OTA manifest',
    'Publish signed IPA + manifest to a Release',
  ];

  // ── formatting helpers ──
  function fmtSize(bytes) {
    if (bytes == null) return '';
    const mb = bytes / 1_000_000;
    if (mb >= 1000) return (mb / 1000).toFixed(2) + ' GB';
    if (mb >= 100) return Math.round(mb) + ' MB';
    return mb.toFixed(1) + ' MB';
  }
  function fmtDate(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  }
  function relTime(iso) {
    const then = new Date(iso).getTime();
    const now = new Date('2026-06-06T20:00:00').getTime();
    const m = Math.round((now - then) / 60000);
    if (m < 60) return m + 'm ago';
    const h = Math.round(m / 60);
    if (h < 24) return h + 'h ago';
    const dd = Math.round(h / 24);
    return dd === 1 ? 'Yesterday' : dd + 'd ago';
  }

  window.IPA_DATA = { APPS, SOURCES, LIBRARY, SIGN_STEPS };
  window.IPA_FMT = { fmtSize, fmtDate, relTime };
})();
