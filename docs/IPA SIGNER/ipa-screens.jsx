// ipa-screens.jsx — Catalog, Upload, Library (exported to window)
const { useState: useS3, useMemo: useMemo3 } = React;
const { fmtSize, fmtDate, relTime } = window.IPA_FMT;

function metaLine(parts) { return parts.filter(Boolean).join('  ·  '); }

/* ─────────────────────────────────────────────────────────────
   App card row
   ───────────────────────────────────────────────────────────── */
function AppRow({ app, last, installedVersion, onGet, onOpen }) {
  const installed = installedVersion != null;
  const upToDate = installed && installedVersion === app.version;
  return (
    <Row last={last} leftInset={84} onClick={() => onOpen(app)} style={{ padding: '12px 16px', gap: 14 }}>
      <AppIcon name={app.name} tint={app.tint} size={56} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="t-headline" style={{ color: 'var(--label)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{app.name}</div>
        <div className="t-footnote sec" style={{ marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{app.developer}</div>
        <div className="t-caption ter" style={{ marginTop: 3 }}>{metaLine([app.version && 'v' + app.version, fmtSize(app.sizeBytes), app.cat])}</div>
      </div>
      <button className="pressable" onClick={(e) => { e.stopPropagation(); onGet(app); }} style={{
        height: 32, minWidth: 74, padding: '0 16px', borderRadius: 16,
        background: 'var(--fill)', color: upToDate ? 'var(--label-secondary)' : (app.tint || 'var(--accent)'),
        fontWeight: 700, fontSize: 15, letterSpacing: 0.2, textTransform: 'uppercase',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4,
      }}>
        {upToDate ? 'OPEN' : (installed ? 'UPDATE' : 'GET')}
      </button>
    </Row>
  );
}

function SkeletonRow({ last }) {
  return (
    <Row last={last} leftInset={84} style={{ padding: '12px 16px', gap: 14 }}>
      <div className="skeleton" style={{ width: 56, height: 56, borderRadius: 13 }} />
      <div style={{ flex: 1 }}>
        <div className="skeleton" style={{ width: '52%', height: 15, borderRadius: 5 }} />
        <div className="skeleton" style={{ width: '34%', height: 12, borderRadius: 5, marginTop: 8 }} />
        <div className="skeleton" style={{ width: '44%', height: 11, borderRadius: 5, marginTop: 8 }} />
      </div>
      <div className="skeleton" style={{ width: 74, height: 32, borderRadius: 16 }} />
    </Row>
  );
}

/* ─────────────────────────────────────────────────────────────
   Catalog tab
   ───────────────────────────────────────────────────────────── */
function CatalogScreen({ apps, library, loading, refreshing, onRefresh, onGet, onOpen, trailing }) {
  const [q, setQ] = useS3('');
  const filtered = useMemo3(() => {
    const s = q.trim().toLowerCase();
    if (!s) return apps;
    return apps.filter(a => a.name.toLowerCase().includes(s) || a.developer.toLowerCase().includes(s));
  }, [q, apps]);
  const libVer = (id) => { const l = library.find(x => x.appId === id); return l ? l.version : null; };

  let body;
  if (loading) {
    body = <Group>{[0,1,2,3,4].map(i => <SkeletonRow key={i} last={i===4} />)}</Group>;
  } else if (apps.length === 0) {
    body = <EmptyState icon="catalog" title="No apps yet" message="Add a source from the folder icon to browse installable apps."
             action={<TextBtn icon="folder" onClick={trailing.onSources}>Manage Sources</TextBtn>} />;
  } else if (filtered.length === 0) {
    body = <EmptyState icon="search" title="No results" message={`Nothing matches “${q}”. Try a different name or developer.`} />;
  } else {
    body = (
      <div className="fade-in">
        <SectionHeader>{filtered.length} app{filtered.length !== 1 ? 's' : ''}</SectionHeader>
        <Group>
          {filtered.map((a, i) => (
            <AppRow key={a.id} app={a} last={i === filtered.length - 1}
              installedVersion={libVer(a.id)} onGet={onGet} onOpen={onOpen} />
          ))}
        </Group>
        <div className="t-caption ter" style={{ textAlign: 'center', padding: '18px 0 0' }}>Aggregated from your sources · Pull to refresh</div>
      </div>
    );
  }

  return (
    <Screen title="Catalog"
      trailing={<>
        <ChromeBtn icon="folder" onClick={trailing.onSources} />
        <ChromeBtn icon="gear" onClick={trailing.onSettings} />
      </>}
      search={<SearchBar value={q} onChange={setQ} placeholder="Search apps & developers" />}
      onRefresh={onRefresh} refreshing={refreshing} bottomInset={92}>
      {body}
    </Screen>
  );
}

/* ─────────────────────────────────────────────────────────────
   Upload tab
   ───────────────────────────────────────────────────────────── */
function UploadScreen({ onPickFile, onSignUrl, trailing }) {
  const [url, setUrl] = useS3('');
  const valid = /^https?:\/\/.+\.ipa(\?.*)?$/i.test(url.trim());
  const submitUrl = () => {
    if (!url.trim()) return;
    if (!valid) { window.showToast('Enter a direct link ending in .ipa', { tone: 'error', icon: 'exclaim-circle' }); return; }
    onSignUrl(url.trim());
  };
  return (
    <Screen title="Upload"
      trailing={<>
        <ChromeBtn icon="folder" onClick={trailing.onSources} />
        <ChromeBtn icon="gear" onClick={trailing.onSettings} />
      </>}
      bottomInset={92}>
      {/* drop zone */}
      <div style={{ padding: '4px 16px 0' }}>
        <button className="pressable" onClick={onPickFile} style={{
          width: '100%', textAlign: 'center', borderRadius: 16,
          background: 'var(--bg-elevated)', boxShadow: '0 0 0 1.5px var(--separator-strong)',
          padding: '34px 24px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0,
        }}>
          <div style={{
            width: 64, height: 64, borderRadius: 18, marginBottom: 14,
            background: 'color-mix(in srgb, var(--accent) 14%, transparent)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="doc" size={30} stroke={1.8} color="var(--accent)" />
          </div>
          <div className="t-title3" style={{ color: 'var(--label)' }}>Pick an .ipa from Files</div>
          <div className="t-subhead sec" style={{ maxWidth: 250, textWrap: 'pretty', marginTop: 5 }}>Sign an IPA already on your device.</div>
        </button>
      </div>

      {/* divider */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '26px 28px 22px' }}>
        <div style={{ flex: 1, height: 0.5, background: 'var(--separator-strong)' }} />
        <span className="t-footnote ter">or from a direct URL</span>
        <div style={{ flex: 1, height: 0.5, background: 'var(--separator-strong)' }} />
      </div>

      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <Field value={url} onChange={setUrl} placeholder="https://…/app.ipa" icon="link" mono onEnter={submitUrl} />
        <Btn kind="primary" icon="download-circle" onClick={submitUrl} disabled={!url.trim()}>Sign from URL</Btn>
        <div className="t-footnote sec" style={{ textAlign: 'center', padding: '4px 12px 0', textWrap: 'pretty' }}>
          The link must point directly to an <span style={{ fontFamily: 'var(--mono)', fontSize: 12 }}>.ipa</span> file. Signing runs remotely, then installs over-the-air.
        </div>
      </div>
    </Screen>
  );
}

/* ─────────────────────────────────────────────────────────────
   Library tab — installed apps + stored ipa files
   ───────────────────────────────────────────────────────────── */
function LibraryScreen({ library, ipaFiles, onOpenApp, onResign, onDeleteIpa, trailing }) {
  const totalBytes = library.reduce((s, l) => s + l.sizeBytes, 0) + ipaFiles.reduce((s, f) => s + f.sizeBytes, 0);
  const updates = library.filter(l => l.updateAvailable);

  if (library.length === 0 && ipaFiles.length === 0) {
    return (
      <Screen title="Library"
        trailing={<><ChromeBtn icon="folder" onClick={trailing.onSources} /><ChromeBtn icon="gear" onClick={trailing.onSettings} /></>}
        bottomInset={92}>
        <EmptyState icon="library" title="Nothing installed yet"
          message="Apps you sign and install will be logged here with their version history." />
      </Screen>
    );
  }

  return (
    <Screen title="Library"
      trailing={<><ChromeBtn icon="folder" onClick={trailing.onSources} /><ChromeBtn icon="gear" onClick={trailing.onSettings} /></>}
      bottomInset={92}>
      {/* summary */}
      <div style={{ padding: '2px 16px 18px', display: 'flex', gap: 12 }}>
        <StatCard label="Installed" value={library.length} sub="apps" />
        <StatCard label="Storage used" value={fmtSize(totalBytes).split(' ')[0]} sub={fmtSize(totalBytes).split(' ')[1] + ' on device'} />
      </div>

      {updates.length > 0 && (
        <div className="fade-in" style={{ marginBottom: 16 }}>
          <SectionHeader>Updates available</SectionHeader>
          <Group>
            {updates.map((l, i) => (
              <Row key={l.id} last={i === updates.length - 1} leftInset={72}>
                <AppIcon name={l.name} tint={l.tint} size={44} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="t-callout" style={{ fontWeight: 600 }}>{l.name}</div>
                  <div className="t-footnote sec tabular">{l.version} → {l.updateAvailable}</div>
                </div>
                <Btn kind="primary" size="sm" full={false} onClick={() => onResign(l, l.updateAvailable)} style={{ height: 30 }}>Update</Btn>
              </Row>
            ))}
          </Group>
        </div>
      )}

      <SectionHeader>Installed apps</SectionHeader>
      <Group>
        {library.map((l, i) => (
          <Row key={l.id} last={i === library.length - 1} leftInset={72} onClick={() => onOpenApp(l)}>
            <AppIcon name={l.name} tint={l.tint} size={44} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="t-callout" style={{ fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{l.name}</div>
              <div className="t-footnote sec tabular">v{l.version} · {fmtSize(l.sizeBytes)} · {relTime(l.installedAt)}</div>
            </div>
            {l.updateAvailable && <span style={{ width: 8, height: 8, borderRadius: 4, background: 'var(--accent)' }} />}
            <Icon name="chevron-right" size={16} stroke={2.4} color="var(--label-tertiary)" />
          </Row>
        ))}
      </Group>

      <div style={{ height: 22 }} />
      <SectionHeader>On-device .ipa files</SectionHeader>
      {ipaFiles.length === 0 ? (
        <Group><Row last><span className="t-callout sec">No stored IPA files</span></Row></Group>
      ) : (
        <Group>
          {ipaFiles.map((f, i) => (
            <Row key={f.id} last={i === ipaFiles.length - 1} leftInset={60}>
              <div style={{ width: 36, height: 36, borderRadius: 9, background: 'var(--fill)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon name="doc" size={19} stroke={1.9} color="var(--label-secondary)" />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="t-callout" style={{ fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', fontFamily: 'var(--mono)', fontSize: 14 }}>{f.filename}</div>
                <div className="t-footnote sec tabular">{fmtSize(f.sizeBytes)} · {fmtDate(f.date)}</div>
              </div>
              <button className="pressable" onClick={() => onDeleteIpa(f)} style={{ color: 'var(--label-tertiary)', padding: 6 }}>
                <Icon name="trash" size={20} stroke={1.9} />
              </button>
            </Row>
          ))}
        </Group>
      )}
      <SectionFooter>Signed IPA files are cached on device so you can reinstall without re-signing.</SectionFooter>
    </Screen>
  );
}

function StatCard({ label, value, sub }) {
  return (
    <div style={{ flex: 1, background: 'var(--bg-elevated)', borderRadius: 14, boxShadow: '0 0 0 0.5px var(--separator)', padding: '14px 16px' }}>
      <div className="t-footnote sec" style={{ textTransform: 'uppercase', letterSpacing: 0.3, fontWeight: 600 }}>{label}</div>
      <div className="t-title1 tabular" style={{ marginTop: 4, color: 'var(--label)' }}>{value}</div>
      <div className="t-footnote ter">{sub}</div>
    </div>
  );
}

Object.assign(window, { CatalogScreen, UploadScreen, LibraryScreen });
