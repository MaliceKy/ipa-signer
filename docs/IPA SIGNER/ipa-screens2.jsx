// ipa-screens2.jsx — AppDetail, LibraryDetail, FilePicker, Sources, Settings
const { useState: useS4 } = React;
const F2 = window.IPA_FMT;

/* ─────────────────────────────────────────────────────────────
   Info grid row (label / value)
   ───────────────────────────────────────────────────────────── */
function InfoRow({ label, value, mono, last }) {
  return (
    <Row last={last}>
      <span className="t-body" style={{ flex: 1, color: 'var(--label)' }}>{label}</span>
      <span className="t-body sec" style={{ fontFamily: mono ? 'var(--mono)' : 'inherit', fontSize: mono ? 14 : 17, textAlign: 'right', maxWidth: '60%', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{value}</span>
    </Row>
  );
}

/* ─────────────────────────────────────────────────────────────
   App detail (pushed from Catalog)
   ───────────────────────────────────────────────────────────── */
function AppDetailScreen({ app, installedVersion, onBack, onGet }) {
  const installed = installedVersion === app.version;
  return (
    <Layer variant="push">
      <Screen title={app.name} large={false} leading={<BackBtn onClick={onBack} label="Catalog" />} bottomInset={20}>
        {/* hero */}
        <div style={{ display: 'flex', gap: 16, alignItems: 'center', padding: '8px 16px 20px' }}>
          <AppIcon name={app.name} tint={app.tint} size={92} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="t-title2" style={{ color: 'var(--label)' }}>{app.name}</div>
            <div className="t-subhead sec" style={{ marginTop: 2 }}>{app.developer}</div>
            <div style={{ marginTop: 12 }}>
              <Btn kind="primary" size="md" full={false} icon="download-circle"
                onClick={() => onGet(app)} style={{ background: app.tint || 'var(--accent)' }}>
                {installed ? 'Re-sign' : 'GET'}
              </Btn>
            </div>
          </div>
        </div>

        {/* stat strip */}
        <div style={{ display: 'flex', margin: '0 16px 22px', background: 'var(--bg-elevated)', borderRadius: 14, boxShadow: '0 0 0 0.5px var(--separator)' }}>
          {[['Version', 'v' + app.version], ['Size', F2.fmtSize(app.sizeBytes)], ['Category', app.cat]].map((s, i) => (
            <div key={i} style={{ flex: 1, textAlign: 'center', padding: '12px 6px', borderLeft: i ? '0.5px solid var(--separator)' : 'none' }}>
              <div className="t-footnote sec" style={{ textTransform: 'uppercase', letterSpacing: 0.3, fontWeight: 600 }}>{s[0]}</div>
              <div className="t-callout tabular" style={{ marginTop: 3, fontWeight: 600, color: 'var(--label)' }}>{s[1]}</div>
            </div>
          ))}
        </div>

        <SectionHeader>About</SectionHeader>
        <Group><Row last><span className="t-body" style={{ color: 'var(--label)', textWrap: 'pretty' }}>{app.desc}</span></Row></Group>

        <div style={{ height: 22 }} />
        <SectionHeader>Information</SectionHeader>
        <Group>
          <InfoRow label="Source" value={app.source} />
          <InfoRow label="Updated" value={F2.fmtDate(app.versionDate)} />
          <InfoRow label="Bundle ID" value={app.bundleId} mono last />
        </Group>
      </Screen>
    </Layer>
  );
}

/* ─────────────────────────────────────────────────────────────
   Library detail (pushed) — version history
   ───────────────────────────────────────────────────────────── */
function LibraryDetailScreen({ entry, onBack, onResign, onRemove }) {
  return (
    <Layer variant="push">
      <Screen title={entry.name} large={false} leading={<BackBtn onClick={onBack} label="Library" />} bottomInset={20}>
        <div style={{ display: 'flex', gap: 16, alignItems: 'center', padding: '8px 16px 20px' }}>
          <AppIcon name={entry.name} tint={entry.tint} size={92} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="t-title2" style={{ color: 'var(--label)' }}>{entry.name}</div>
            <div className="t-subhead sec tabular" style={{ marginTop: 2 }}>Installed v{entry.version}</div>
            {entry.updateAvailable && <div style={{ marginTop: 8 }}><Pill tone="blue" icon="download-circle">Update to {entry.updateAvailable}</Pill></div>}
          </div>
        </div>

        <div style={{ padding: '0 16px 22px' }}>
          <Btn kind="primary" icon="refresh"
            onClick={() => onResign(entry, entry.updateAvailable || entry.version)}>
            {entry.updateAvailable ? `Update to ${entry.updateAvailable}` : 'Re-sign & reinstall'}
          </Btn>
        </div>

        <SectionHeader>Information</SectionHeader>
        <Group>
          <InfoRow label="Installed" value={F2.fmtDate(entry.installedAt)} />
          <InfoRow label="Source" value={entry.sourceName} />
          <InfoRow label="Bundle ID" value={entry.bundleId} mono last />
        </Group>

        <div style={{ height: 22 }} />
        <SectionHeader>Version history</SectionHeader>
        <Group>
          {entry.history.map((h, i) => (
            <Row key={i} last={i === entry.history.length - 1}>
              <div style={{ width: 30, display: 'flex', justifyContent: 'center' }}>
                <span style={{ width: 9, height: 9, borderRadius: 5, background: i === 0 ? 'var(--green)' : 'var(--label-quaternary)' }} />
              </div>
              <div style={{ flex: 1 }}>
                <div className="t-callout tabular" style={{ fontWeight: 600, color: 'var(--label)' }}>v{h.version}{i === 0 && <span className="t-caption" style={{ color: 'var(--green)', fontWeight: 600, marginLeft: 8 }}>CURRENT</span>}</div>
                <div className="t-footnote sec tabular">{F2.fmtDate(h.date)} · {F2.fmtSize(h.size)}</div>
              </div>
            </Row>
          ))}
        </Group>

        <div style={{ height: 28 }} />
        <Group>
          <Row last onClick={() => onRemove(entry)} style={{ justifyContent: 'center' }}>
            <span className="t-body" style={{ color: 'var(--red)', fontWeight: 400 }}>Remove from Library</span>
          </Row>
        </Group>
      </Screen>
    </Layer>
  );
}

/* ─────────────────────────────────────────────────────────────
   File picker (modal) — Files-like sheet
   ───────────────────────────────────────────────────────────── */
const FAKE_FILES = [
  { name: 'Provenance-3.0.2.ipa', size: 78_400_000, ext: 'ipa' },
  { name: 'Flux-1.9.0-signed.ipa', size: 33_100_000, ext: 'ipa' },
  { name: 'Beacon-5.2.0.ipa', size: 48_900_000, ext: 'ipa' },
  { name: 'screenshot.png', size: 2_100_000, ext: 'png' },
  { name: 'Resume.pdf', size: 380_000, ext: 'pdf' },
  { name: 'GridRunner.zip', size: 9_800_000, ext: 'zip' },
];
function FilePicker({ onPick, onClose }) {
  return (
    <Layer variant="modal">
      <Screen title="Files" large={false}
        leading={<button className="pressable" onClick={onClose} style={{ color: 'var(--accent)', fontSize: 17, padding: '6px 8px' }}>Cancel</button>}
        bottomInset={20}>
        <SectionHeader>On My iPhone — Downloads</SectionHeader>
        <Group>
          {FAKE_FILES.map((f, i) => {
            const isIpa = f.ext === 'ipa';
            return (
              <Row key={i} last={i === FAKE_FILES.length - 1} leftInset={60}
                onClick={() => isIpa ? onPick(f) : window.showToast('Please pick a .ipa file', { tone: 'error', icon: 'exclaim-circle' })}>
                <div style={{ width: 36, height: 36, borderRadius: 9, background: isIpa ? 'color-mix(in srgb, var(--accent) 16%, transparent)' : 'var(--fill)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Icon name="doc" size={19} stroke={1.9} color={isIpa ? 'var(--accent)' : 'var(--label-secondary)'} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="t-callout" style={{ fontWeight: 500, fontFamily: 'var(--mono)', fontSize: 14, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', color: isIpa ? 'var(--label)' : 'var(--label-secondary)' }}>{f.name}</div>
                  <div className="t-footnote ter tabular">{F2.fmtSize(f.size)}</div>
                </div>
                {isIpa && <Icon name="chevron-right" size={16} stroke={2.4} color="var(--label-tertiary)" />}
              </Row>
            );
          })}
        </Group>
        <SectionFooter>Only .ipa files can be signed. Tapping another file type shows an error.</SectionFooter>
      </Screen>
    </Layer>
  );
}

/* ─────────────────────────────────────────────────────────────
   Sources screen (pushed)
   ───────────────────────────────────────────────────────────── */
function SourcesScreen({ sources, onAdd, onDelete, onBack, adding }) {
  const [url, setUrl] = useS4('');
  const submit = () => {
    const u = url.trim();
    if (!u) return;
    if (!/^https?:\/\/.+/i.test(u)) { window.showToast('Enter a valid repo URL', { tone: 'error', icon: 'exclaim-circle' }); return; }
    onAdd(u, () => setUrl(''));
  };
  return (
    <Layer variant="push">
      <Screen title="Sources" leading={<BackBtn onClick={onBack} label="Catalog" />} bottomInset={20}>
        <SectionHeader>Add a source</SectionHeader>
        <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Field value={url} onChange={setUrl} placeholder="https://…/apps.json" icon="link" mono onEnter={submit} />
          <Btn kind="primary" icon="plus" onClick={submit} loading={adding} disabled={!url.trim()}>Add source</Btn>
        </div>
        <SectionFooter>AltStore-style repositories. Each repo’s apps appear in the Catalog.</SectionFooter>

        <div style={{ height: 22 }} />
        <SectionHeader>{sources.length} source{sources.length !== 1 ? 's' : ''}</SectionHeader>
        {sources.length === 0 ? (
          <EmptyState icon="folder" title="No sources yet" message="Add a repository URL above to start browsing apps." />
        ) : (
          <Group>
            {sources.map((s, i) => (
              <Row key={s.id} last={i === sources.length - 1} leftInset={60}>
                <div style={{ width: 36, height: 36, borderRadius: 9, background: s.error ? 'color-mix(in srgb, var(--red) 14%, transparent)' : 'var(--fill)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <Icon name="folder" size={19} stroke={1.9} color={s.error ? 'var(--red)' : 'var(--label-secondary)'} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="t-callout" style={{ fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.name}</div>
                  {s.error
                    ? <div className="t-footnote" style={{ color: 'var(--red)' }}>Failed: {s.error}</div>
                    : <div className="t-footnote sec">{s.appCount} app{s.appCount !== 1 ? 's' : ''}</div>}
                  <div className="t-caption ter" style={{ fontFamily: 'var(--mono)', fontSize: 11, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.url.replace(/^https?:\/\//, '')}</div>
                </div>
                <button className="pressable" onClick={() => onDelete(s)} style={{ color: 'var(--red)', padding: 6, alignSelf: 'center' }}>
                  <Icon name="trash" size={20} stroke={1.9} />
                </button>
              </Row>
            ))}
          </Group>
        )}
      </Screen>
    </Layer>
  );
}

/* ─────────────────────────────────────────────────────────────
   Settings screen (pushed) — appearance + GitHub connection + repos
   ───────────────────────────────────────────────────────────── */
function SettingsScreen({ appearance, onAppearance, gh, setGh, verify, verifyState, sources, onManageSources, onBack, onDisconnect, firstRun }) {
  const canVerify = gh.token && gh.owner && gh.repo;
  return (
    <Layer variant="push">
      <Screen title="Settings"
        leading={firstRun ? <span style={{ width: 60 }} /> : <BackBtn onClick={onBack} label="Catalog" />}
        bottomInset={20}>
        {firstRun && (
          <div style={{ padding: '0 16px 20px' }}>
            <div style={{ background: 'color-mix(in srgb, var(--accent) 12%, transparent)', borderRadius: 14, padding: '14px 16px', display: 'flex', gap: 12 }}>
              <Icon name="info" size={22} stroke={2} color="var(--accent)" style={{ marginTop: 1 }} />
              <span className="t-subhead" style={{ color: 'var(--label)', textWrap: 'pretty' }}>Add your GitHub connection to start signing. These are stored securely in the iOS Keychain.</span>
            </div>
          </div>
        )}

        <SectionHeader>Appearance</SectionHeader>
        <Group>
          <Row last style={{ padding: '12px 16px' }}>
            <div style={{ flex: 1 }}>
              <Segmented value={appearance} onChange={onAppearance}
                options={[{ value: 'system', label: 'System' }, { value: 'light', label: 'Light' }, { value: 'dark', label: 'Dark' }]} />
            </div>
          </Row>
        </Group>

        <div style={{ height: 22 }} />
        <SectionHeader>GitHub Connection</SectionHeader>
        <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <Field value={gh.token} onChange={(v) => setGh({ ...gh, token: v })} placeholder="Personal access token" obscure icon="key" mono />
          <Field value={gh.owner} onChange={(v) => setGh({ ...gh, owner: v })} placeholder="Repo owner (e.g. MaliceKy)" icon="code" mono />
          <Field value={gh.repo} onChange={(v) => setGh({ ...gh, repo: v })} placeholder="Repo name (e.g. ipa-signer)" icon="folder" mono />
          <Field value={gh.branch} onChange={(v) => setGh({ ...gh, branch: v })} placeholder="Branch (default: main)" icon="code" mono />
          <Btn kind="primary" icon="shield" onClick={verify} loading={verifyState.status === 'verifying'} disabled={!canVerify}>Save &amp; verify</Btn>
          {verifyState.status === 'ok' && (
            <div className="fade-in t-subhead" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, color: 'var(--green)', fontWeight: 600, paddingTop: 2 }}>
              <Icon name="check-circle" size={18} stroke={2.4} /> Saved &amp; verified
            </div>
          )}
          {verifyState.status === 'error' && (
            <div className="fade-in t-subhead" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6, color: 'var(--red)', fontWeight: 500, paddingTop: 2, textAlign: 'center', textWrap: 'pretty' }}>
              <Icon name="exclaim-circle" size={18} stroke={2.4} /> {verifyState.message}
            </div>
          )}
        </div>
        <SectionFooter>The token signs and triggers the workflow on GitHub Actions. Stored in the Keychain — never synced.</SectionFooter>

        <div style={{ height: 22 }} />
        <SectionHeader>Installed repositories</SectionHeader>
        <Group>
          {sources.map((s, i) => (
            <Row key={s.id} last={i === sources.length - 1} leftInset={56}>
              <Icon name="folder" size={20} stroke={1.9} color={s.error ? 'var(--red)' : 'var(--label-secondary)'} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="t-body" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.name}</div>
              </div>
              <span className="t-body sec">{s.error ? <span style={{ color: 'var(--red)' }}>Failed</span> : `${s.appCount}`}</span>
            </Row>
          ))}
          <Row last onClick={onManageSources}>
            <span className="t-body" style={{ flex: 1, color: 'var(--accent)' }}>Manage Sources</span>
            <Icon name="chevron-right" size={16} stroke={2.4} color="var(--label-tertiary)" />
          </Row>
        </Group>

        {!firstRun && (
          <>
            <div style={{ height: 28 }} />
            <Group>
              <Row last onClick={onDisconnect} style={{ justifyContent: 'center' }}>
                <span className="t-body" style={{ color: 'var(--red)' }}>Disconnect GitHub</span>
              </Row>
            </Group>
          </>
        )}
      </Screen>
    </Layer>
  );
}

Object.assign(window, { AppDetailScreen, LibraryDetailScreen, FilePicker, SourcesScreen, SettingsScreen });
