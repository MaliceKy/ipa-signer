// ipa-app.jsx — IPA Signer: navigation, theme, state, tweaks, device scaling
const { useState: useA, useEffect: useEA, useRef: useRA, useCallback: useCA, useMemo: useMA } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#0A84FF",
  "appearance": "system",
  "iconShape": "squircle",
  "signOutcome": "success",
  "signSpeed": "normal",
  "catalogState": "loaded"
}/*EDITMODE-END*/;

const ICON_RATIO = { squircle: 0.225, rounded: 0.32, circle: 0.5 };
const SPEED = { relaxed: 0.65, normal: 1, fast: 1.75 };

const TABS = [
  { id: 'catalog', label: 'Catalog', icon: 'catalog' },
  { id: 'upload',  label: 'Upload',  icon: 'upload' },
  { id: 'library', label: 'Library', icon: 'library' },
];

function useResolvedTheme(appearance) {
  const [sysDark, setSysDark] = useA(() => window.matchMedia('(prefers-color-scheme: dark)').matches);
  useEA(() => {
    const mql = window.matchMedia('(prefers-color-scheme: dark)');
    const fn = (e) => setSysDark(e.matches);
    mql.addEventListener('change', fn);
    return () => mql.removeEventListener('change', fn);
  }, []);
  return appearance === 'system' ? (sysDark ? 'dark' : 'light') : appearance;
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const theme = useResolvedTheme(t.appearance);

  // expose tweak-driven globals for AppIcon + sign engine
  window.__iconRatio = ICON_RATIO[t.iconShape] || 0.225;
  window.__signSpeed = SPEED[t.signSpeed] || 1;

  // ── data state ──
  const [sources, setSources] = useA(window.IPA_DATA.SOURCES);
  const [library, setLibrary] = useA(window.IPA_DATA.LIBRARY);
  const [ipaFiles, setIpaFiles] = useA([
    { id: 'f1', filename: 'Provenance-3.0.2.ipa', sizeBytes: 78_400_000, date: '2026-06-05' },
    { id: 'f2', filename: 'Flux-1.9.0.ipa', sizeBytes: 33_100_000, date: '2026-06-04' },
  ]);
  const [gh, setGh] = useA({ token: 'ghp_8Qx72fRfL0kZ', owner: 'MaliceKy', repo: 'ipa-signer', branch: 'main' });
  const [verifyState, setVerifyState] = useA({ status: 'idle' });
  const [adding, setAdding] = useA(false);
  const [refreshing, setRefreshing] = useA(false);

  const firstRun = !(gh.token && gh.owner && gh.repo);

  // catalog state driven by tweak
  const catalogLoading = t.catalogState === 'loading';
  const apps = t.catalogState === 'empty' ? [] : window.IPA_DATA.APPS;

  // ── navigation ──
  const [tab, setTab] = useA('catalog');
  const [stack, setStack] = useA([]);       // [{ type, data }]
  const push = (type, data) => setStack(s => [...s, { type, data, key: Math.random().toString(36).slice(2) }]);
  const pop = () => setStack(s => s.slice(0, -1));
  const replaceTop = (type, data) => setStack(s => [...s.slice(0, -1), { type, data, key: Math.random().toString(36).slice(2) }]);

  // first-run gate
  const booted = useRA(false);
  useEA(() => {
    if (!booted.current && firstRun) { push('settings'); booted.current = true; }
    booted.current = true;
  }, []);

  // ── sign flow ──
  const startSign = useCA((job) => {
    push('sign', { ...job, outcome: t.signOutcome, failStep: job.failStep });
  }, [t.signOutcome]);

  const signCatalog = (app) => startSign({ source: 'catalog', title: app.name, subtitle: `${app.developer} · v${app.version}`, tint: app.tint, sizeBytes: app.sizeBytes, app, version: app.version });
  const signFile = (file) => { pop(); startSign({ source: 'file', title: file.name, subtitle: `From Files · ${window.IPA_FMT.fmtSize(file.size)}`, sizeBytes: file.size, file, version: 'sideloaded' }); };
  const signUrl = (url) => { const fn = decodeURIComponent(url.split('/').pop().split('?')[0]); startSign({ source: 'url', title: fn, subtitle: 'From a direct URL', sizeBytes: 24_000_000, version: 'remote' }); };
  const signResign = (entry, version) => startSign({ source: 'catalog', title: entry.name, subtitle: `Re-sign · v${version}`, tint: entry.tint, sizeBytes: entry.sizeBytes, entry, version });

  const onInstalled = useCA((job) => {
    const now = '2026-06-06T20:18:00';
    const version = job.version && /^\d/.test(job.version) ? job.version : (job.app ? job.app.version : '1.0.0');
    const name = job.app ? job.app.name : (job.entry ? job.entry.name : job.title.replace(/[-_ ]?v?\d.*$/, '').replace(/\.ipa$/i, ''));
    const tint = job.tint || (job.app && job.app.tint) || '#0A84FF';
    const bundleId = job.app ? job.app.bundleId : (job.entry ? job.entry.bundleId : 'com.sideload.' + name.toLowerCase().replace(/\W/g, ''));
    const sourceName = job.app ? job.app.source : (job.entry ? job.entry.sourceName : 'Sideloaded');
    const sizeBytes = job.sizeBytes || 24_000_000;

    setLibrary(prev => {
      const idx = prev.findIndex(l => (job.app && l.appId === job.app.id) || (job.entry && l.id === job.entry.id) || l.name === name);
      if (idx >= 0) {
        const e = prev[idx];
        const hist = e.history[0] && e.history[0].version === version ? e.history : [{ version, date: now.slice(0,10), size: sizeBytes }, ...e.history];
        const updated = { ...e, version, installedAt: now, sizeBytes, updateAvailable: undefined, history: hist };
        return [updated, ...prev.filter((_, i) => i !== idx)];
      }
      return [{ id: 'l' + Math.random().toString(36).slice(2), appId: job.app ? job.app.id : name, name, tint, version, sizeBytes, installedAt: now, sourceName, bundleId, history: [{ version, date: now.slice(0,10), size: sizeBytes }] }, ...prev];
    });
    setIpaFiles(prev => {
      const filename = `${name.replace(/\s/g, '')}-${version}.ipa`;
      if (prev.some(f => f.filename === filename)) return prev;
      return [{ id: 'f' + Math.random().toString(36).slice(2), filename, sizeBytes, date: now.slice(0,10) }, ...prev];
    });
  }, []);

  // ── sources ──
  const addSource = (url, done) => {
    setAdding(true);
    setTimeout(() => {
      setAdding(false);
      const host = url.replace(/^https?:\/\//, '').split('/')[0];
      const ok = !/fail|broken/i.test(url);
      const name = ok ? (host.split('.')[0].replace(/^\w/, c => c.toUpperCase()) + ' Repo') : 'Unreachable Repo';
      setSources(s => [...s, { id: 's' + Math.random().toString(36).slice(2), name, url, appCount: ok ? Math.floor(Math.random() * 5 + 1) : 0, error: ok ? undefined : 'Could not parse apps.json' }]);
      window.showToast(ok ? 'Source added' : 'Source failed to load', { tone: ok ? 'ok' : 'error', icon: ok ? 'check-circle' : 'exclaim-circle' });
      done && done();
    }, 1400);
  };
  const deleteSource = (s) => { setSources(list => list.filter(x => x.id !== s.id)); window.showToast('Source removed', { icon: 'trash' }); };

  const refresh = () => { setRefreshing(true); setTimeout(() => { setRefreshing(false); window.showToast('Catalog refreshed', { icon: 'refresh' }); }, 1200); };

  // ── settings verify ──
  const verify = () => {
    setVerifyState({ status: 'verifying' });
    setTimeout(() => {
      if ((gh.token || '').length < 6) setVerifyState({ status: 'error', message: 'Bad credentials — check your token (401)' });
      else { setVerifyState({ status: 'ok' }); window.showToast('Saved & verified', { tone: 'ok', icon: 'check-circle' }); }
    }, 1300);
  };
  const disconnect = () => { setGh({ token: '', owner: '', repo: '', branch: 'main' }); setVerifyState({ status: 'idle' }); window.showToast('Disconnected from GitHub', { icon: 'trash' }); };

  const libVer = (id) => { const l = library.find(x => x.appId === id); return l ? l.version : null; };

  const trailing = { onSources: () => push('sources'), onSettings: () => push('settings') };

  // ── render layers ──
  const renderLayer = (layer) => {
    const d = layer.data || {};
    switch (layer.type) {
      case 'sources':  return <SourcesScreen key={layer.key} sources={sources} adding={adding} onAdd={addSource} onDelete={deleteSource} onBack={pop} />;
      case 'settings': return <SettingsScreen key={layer.key} appearance={t.appearance} onAppearance={(v) => setTweak('appearance', v)} gh={gh} setGh={setGh} verify={verify} verifyState={verifyState} sources={sources} onManageSources={() => push('sources')} onBack={pop} onDisconnect={disconnect} firstRun={firstRun} />;
      case 'appDetail': return <AppDetailScreen key={layer.key} app={d.app} installedVersion={libVer(d.app.id)} onBack={pop} onGet={(a) => { pop(); signCatalog(a); }} />;
      case 'libraryDetail': return <LibraryDetailScreen key={layer.key} entry={d.entry} onBack={pop} onResign={(e, v) => { pop(); signResign(e, v); }} onRemove={(e) => { setLibrary(l => l.filter(x => x.id !== e.id)); pop(); window.showToast('Removed from Library', { icon: 'trash' }); }} />;
      case 'filePicker': return <FilePicker key={layer.key} onPick={signFile} onClose={pop} />;
      case 'sign': return <SignScreen key={layer.key} job={d} gh={gh} onClose={pop} onInstalled={onInstalled} />;
      default: return null;
    }
  };

  // ── device scaling ──
  const [scale, setScale] = useA(1);
  useEA(() => {
    const fit = () => {
      const pad = 24;
      setScale(Math.min((window.innerWidth - pad) / 402, (window.innerHeight - pad) / 874, 1.15));
    };
    fit(); window.addEventListener('resize', fit);
    return () => window.removeEventListener('resize', fit);
  }, []);

  const dark = theme === 'dark';

  return (
    <div style={{ position: 'fixed', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden',
                  backgroundColor: dark ? '#0c0c0d' : '#e8e8ec' }}>
      <div style={{ transform: `scale(${scale})`, transformOrigin: 'center center' }}>
        <IOSDevice dark={dark}>
          <div className="ipa-app" data-theme={theme} style={{ '--accent': t.accent, height: '100%', position: 'relative', overflow: 'hidden' }}>
            {/* active tab */}
            <div style={{ position: 'absolute', inset: 0 }}>
              {tab === 'catalog' && <CatalogScreen apps={apps} library={library} loading={catalogLoading} refreshing={refreshing} onRefresh={refresh} onGet={signCatalog} onOpen={(a) => push('appDetail', { app: a })} trailing={trailing} />}
              {tab === 'upload' && <UploadScreen onPickFile={() => push('filePicker')} onSignUrl={signUrl} trailing={trailing} />}
              {tab === 'library' && <LibraryScreen library={library} ipaFiles={ipaFiles} onOpenApp={(l) => push('libraryDetail', { entry: l })} onResign={signResign} onDeleteIpa={(f) => { setIpaFiles(list => list.filter(x => x.id !== f.id)); window.showToast('IPA file deleted', { icon: 'trash' }); }} trailing={trailing} />}
            </div>

            {/* tab bar (hidden when a full layer is open) */}
            {stack.length === 0 && <TabBar tabs={TABS} active={tab} onChange={setTab} />}

            {/* pushed / modal layers */}
            {stack.map(renderLayer)}

            <ToastHost />
          </div>
        </IOSDevice>
      </div>

      <TweaksPanel>
        <TweakSection label="Theme" />
        <TweakColor label="Accent" value={t.accent} onChange={(v) => setTweak('accent', v)}
          options={['#0A84FF', '#34C759', '#FF9500', '#FF375F', '#BF5AF2', '#FF453A']} />
        <TweakRadio label="Appearance" value={t.appearance} options={['system', 'light', 'dark']} onChange={(v) => setTweak('appearance', v)} />
        <TweakSelect label="App icon shape" value={t.iconShape} options={['squircle', 'rounded', 'circle']} onChange={(v) => setTweak('iconShape', v)} />
        <TweakSection label="Sign demo" />
        <TweakRadio label="Outcome" value={t.signOutcome} options={['success', 'fail']} onChange={(v) => setTweak('signOutcome', v)} />
        <TweakRadio label="Speed" value={t.signSpeed} options={['relaxed', 'normal', 'fast']} onChange={(v) => setTweak('signSpeed', v)} />
        <TweakSection label="Catalog state" />
        <TweakSelect label="Data" value={t.catalogState} options={['loaded', 'loading', 'empty']} onChange={(v) => setTweak('catalogState', v)} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
