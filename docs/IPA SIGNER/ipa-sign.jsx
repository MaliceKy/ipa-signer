// ipa-sign.jsx — Sign screen + signing state machine (the centerpiece)
const { useState: useSg, useEffect: useEg, useRef: useRg, useCallback: useCg } = React;

const PHASE_META = {
  uploading: { label: 'Uploading', tone: 'blue' },
  starting:  { label: 'Starting',  tone: 'blue' },
  queued:    { label: 'Queued',    tone: 'amber' },
  signing:   { label: 'Signing',   tone: 'blue' },
  signed:    { label: 'Signed',    tone: 'green' },
  failed:    { label: 'Failed',    tone: 'red' },
};

function clockStr(base, offsetMs) {
  const d = new Date(base.getTime() + offsetMs * 6); // scale to feel like a real ~50s run
  return d.toLocaleTimeString('en-GB', { hour12: false });
}

/* Build the timeline of events for a job. Returns [{ at, fn }] */
function buildTimeline(job, ctx) {
  const { setPhase, setTarget, setSteps, addLog, setError, setRunUrl, setDone, base, gh } = ctx;
  const stepNames = window.IPA_DATA.SIGN_STEPS;
  const ev = [];
  const setStep = (i, status) => setSteps(prev => prev.map((s, k) => k === i ? { ...s, status } : s));
  const hasUpload = job.source === 'file';
  const sizeTxt = job.sizeBytes ? window.IPA_FMT.fmtSize(job.sizeBytes) : '7.7 MB';
  let t = 0;

  if (hasUpload) {
    ev.push({ at: t, fn: () => { setPhase('uploading'); setTarget(6); addLog(`Uploading ${sizeTxt}…`, 'accent'); } });
    ev.push({ at: t += 350, fn: () => { setTarget(12); addLog('Uploaded 35%'); } });
    ev.push({ at: t += 450, fn: () => { setTarget(19); addLog('Uploaded 72%'); } });
    ev.push({ at: t += 450, fn: () => { setTarget(25); addLog(`Uploaded 100% (${sizeTxt})`, 'ok'); } });
    t += 250;
  } else {
    ev.push({ at: t, fn: () => { setTarget(28); } });
  }

  const repo = `${gh.owner || 'MaliceKy'}/${gh.repo || 'ipa-signer'}`;
  const branch = gh.branch || 'main';
  ev.push({ at: t, fn: () => { setPhase('starting'); setTarget(hasUpload ? 31 : 32); addLog(`Triggered: workflow_dispatch on ${repo}@${branch}`); setRunUrl(`https://github.com/${repo}/actions/runs/8472610${Math.floor(Math.random()*90+10)}`); } });
  ev.push({ at: t += 900, fn: () => { setPhase('queued'); setTarget(39); addLog('Queued — waiting for a runner…', 'accent'); } });
  ev.push({ at: t += 1300, fn: () => { setPhase('signing'); } });

  // signing steps
  const stepPlan = [
    { pct: 47, dur: 950,  log: ['zsign built (1.8s)', 'ok'] },
    { pct: 56, dur: 1000, log: ['Certificate & provisioning profile restored', 'ok'] },
    { pct: 70, dur: 900,  log: [`Downloaded unsigned IPA (${sizeTxt})`, 'ok'] },
    { pct: 84, dur: 1300, log: ['Signed 412 files · re-embedded provisioning profile', 'ok'] },
    { pct: 92, dur: 800,  log: ['OTA manifest (plist) generated', 'ok'] },
    { pct: 99, dur: 1000, log: ['Uploaded signed.ipa + manifest to Release', 'ok'] },
  ];

  const failAt = job.outcome === 'fail' ? (job.failStep != null ? job.failStep : 3) : -1;

  for (let i = 0; i < stepNames.length; i++) {
    ev.push({ at: t, fn: () => { setStep(i, 'running'); setTarget(stepPlan[i].pct - 4); } });
    if (i === failAt) {
      ev.push({ at: t += stepPlan[i].dur, fn: () => {
        setStep(i, 'failed');
        setSteps(prev => prev.map((s, k) => k > i ? { ...s, status: 'skipped' } : s));
        const errs = [
          'zsign build failed — clang exited with code 2',
          'error: signing certificate has expired or was revoked (exit 1)',
          'error: failed to download unsigned IPA — 404 Not Found',
          'zsign: provisioning profile does not match signing certificate (exit 1)',
          'error: failed to generate OTA manifest (malformed plist)',
          'error: failed to upload release asset (HTTP 422)',
        ];
        const msg = errs[i] || 'Workflow failed (exit 1)';
        addLog('✗ ' + msg, 'error');
        setError(msg);
        setPhase('failed');
        setDone('failed');
      } });
      break;
    }
    ev.push({ at: t += stepPlan[i].dur, fn: () => { setStep(i, 'success'); setTarget(stepPlan[i].pct); if (stepPlan[i].log) addLog(stepPlan[i].log[0], stepPlan[i].log[1]); } });
    t += 120;
  }

  if (failAt < 0) {
    ev.push({ at: t += 200, fn: () => { setPhase('signed'); setTarget(100); addLog('Done — signed IPA published ✓', 'ok'); setDone('signed'); } });
  }
  return ev;
}

function SignScreen({ job, gh, onClose, onInstalled }) {
  const [phase, setPhase] = useSg(job.source === 'file' ? 'uploading' : 'starting');
  const [pct, setPct] = useSg(0);
  const [steps, setSteps] = useSg(() => window.IPA_DATA.SIGN_STEPS.map(n => ({ name: n, status: 'queued' })));
  const [lines, setLines] = useSg([]);
  const [error, setError] = useSg(null);
  const [runUrl, setRunUrl] = useSg(null);
  const [done, setDone] = useSg(null);           // 'signed' | 'failed'
  const [install, setInstall] = useSg('idle');    // idle | installing | installed

  const target = useRg(0);
  const baseTime = useRg(new Date('2026-06-06T20:14:02'));
  const timers = useRg([]);
  const raf = useRg(null);

  const addLog = useCg((text, tone) => {
    setLines(prev => [...prev, { t: clockStr(baseTime.current, performance.now() - startRef.current), text, tone }]);
  }, []);
  const startRef = useRg(performance.now());

  // run the timeline
  useEg(() => {
    const speed = (window.__signSpeed || 1);
    const ctx = {
      setPhase, setTarget: (v) => { target.current = v; }, setSteps,
      addLog, setError, setRunUrl, setDone, base: baseTime.current, gh,
    };
    const ev = buildTimeline(job, ctx);
    ev.forEach(e => { timers.current.push(setTimeout(e.fn, e.at / speed)); });
    return () => { timers.current.forEach(clearTimeout); timers.current = []; };
  }, []);

  // ease displayed percent toward target (interval, not rAF — runs even when unpainted)
  useEg(() => {
    const id = setInterval(() => {
      setPct(p => {
        const d = target.current - p;
        if (Math.abs(d) < 0.3) return target.current;
        return p + d * 0.16;
      });
    }, 28);
    return () => clearInterval(id);
  }, []);

  const meta = PHASE_META[phase];
  const failed = phase === 'failed';
  const signed = phase === 'signed';

  const etaText = (() => {
    if (failed) return 'Signing failed';
    if (signed) return install === 'installed' ? 'Installed on this device' : 'Done — ready to install';
    if (phase === 'uploading') return `Uploading ${Math.round(pct * 4)}%`;
    if (phase === 'starting') return 'Starting workflow…';
    if (phase === 'queued') return 'Queued — waiting for a runner';
    if (pct > 92) return 'Almost done…';
    const est = Math.max(2, Math.round((100 - pct) * 0.55));
    return `~${est}s remaining`;
  })();

  const barColor = failed ? 'var(--red)' : signed ? 'var(--green)' : 'var(--accent)';
  const pctColor = failed ? 'var(--red)' : signed ? 'var(--green)' : 'var(--label)';

  const copyFull = () => {
    const lines2 = [
      `IPA Signer — ${job.title}`,
      runUrl ? `Run: ${runUrl}` : '',
      '',
      ...steps.map(s => `${({ queued: '○', running: '⟳', success: '✓', skipped: '⊘', failed: '✗' })[s.status]} ${s.name}`),
      '',
      ...lines.map(l => `[${l.t}] ${l.text}`),
      error ? `\nERROR: ${error}` : '',
    ].filter(x => x !== undefined);
    navigator.clipboard && navigator.clipboard.writeText(lines2.join('\n')).catch(() => {});
    window.showToast('Log copied', { icon: 'copy' });
  };

  const doInstall = () => {
    setInstall('installing');
    setTimeout(() => {
      setInstall('installed');
      onInstalled && onInstalled(job);
      window.showToast(`${job.title} installed`, { tone: 'ok', icon: 'check-circle' });
    }, 1700);
  };

  const inProgress = !signed && !failed;

  return (
    <Layer variant="modal">
      <Screen
        title="Signing"
        large={false}
        leading={<button className="pressable" onClick={onClose} style={{ color: 'var(--accent)', fontSize: 17, padding: '6px 8px' }}>{inProgress ? 'Cancel' : 'Done'}</button>}
        trailing={<ChromeBtn icon="share" onClick={copyFull} />}
        contentPad={false} bottomInset={132}>

        {/* progress card */}
        <div className="slide-up" style={{ padding: '6px 16px 0' }}>
          <div style={{ background: 'var(--bg-elevated)', borderRadius: 16, boxShadow: '0 0 0 0.5px var(--separator)', padding: 18, position: 'relative', overflow: 'hidden' }}>
            {/* app header */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
              {job.tint ? <AppIcon name={job.title} tint={job.tint} size={44} />
                : <div style={{ width: 44, height: 44, borderRadius: 10, background: 'var(--fill)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="doc" size={22} color="var(--label-secondary)" /></div>}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="t-headline" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{job.title}</div>
                <div className="t-footnote sec" style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{job.subtitle}</div>
              </div>
              <Pill tone={meta.tone} spin={inProgress && phase !== 'queued'} dot={phase === 'queued'} icon={signed ? 'check' : failed ? 'xmark' : undefined}>{meta.label}</Pill>
            </div>

            {/* big percentage */}
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
              {failed ? (
                <div className="t-title1" style={{ color: 'var(--red)', fontWeight: 700 }}>Failed</div>
              ) : (
                <div style={{ display: 'flex', alignItems: 'baseline' }}>
                  <span className="tabular" style={{ fontSize: 52, lineHeight: '52px', fontWeight: 700, letterSpacing: -1.5, color: pctColor, fontVariantNumeric: 'tabular-nums' }}>{Math.round(pct)}</span>
                  <span className="tabular" style={{ fontSize: 26, fontWeight: 600, color: pctColor, marginLeft: 2 }}>%</span>
                </div>
              )}
              {signed && install !== 'installed' && (
                <div className="fade-in" style={{ width: 34, height: 34, borderRadius: 17, background: 'var(--green)', display: 'flex', alignItems: 'center', justifyContent: 'center', animation: 'ipa-pop .5s cubic-bezier(.2,.8,.3,1) both' }}>
                  <Icon name="check" size={22} stroke={3} color="#fff" />
                </div>
              )}
            </div>

            <Progress value={pct} color={barColor} indeterminate={failed} height={8} animate={false} />
            <div className="t-footnote tabular" style={{ marginTop: 10, color: failed ? 'var(--red)' : 'var(--label-secondary)', fontWeight: 500 }}>{etaText}</div>
          </div>
        </div>

        {/* console */}
        <div style={{ padding: '16px 16px 0' }}>
          <Console steps={steps} lines={lines} onCopy={copyFull} height={236} />
        </div>

        {/* error banner */}
        {failed && error && (
          <div className="fade-in" style={{ padding: '14px 16px 0' }}>
            <div style={{ background: 'color-mix(in srgb, var(--red) 12%, transparent)', borderRadius: 12, padding: '12px 14px', display: 'flex', gap: 10 }}>
              <Icon name="exclaim-circle" size={20} stroke={2.2} color="var(--red)" style={{ flexShrink: 0, marginTop: 1 }} />
              <span className="t-footnote" style={{ color: 'var(--red)', fontFamily: 'var(--mono)', fontSize: 12.5, lineHeight: '18px', userSelect: 'text' }}>{error}</span>
            </div>
          </div>
        )}
      </Screen>

      {/* bottom action dock */}
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 50, padding: '12px 16px 30px',
        background: 'linear-gradient(to top, var(--bg) 60%, transparent)',
      }}>
        {signed && (
          <div className="slide-up">
            <Btn kind={install === 'installed' ? 'success' : 'success'} icon={install === 'installed' ? 'check' : 'download-circle'}
              loading={install === 'installing'} onClick={install === 'idle' ? doInstall : (install === 'installed' ? onClose : undefined)}>
              {install === 'installed' ? 'Done' : 'Install on this device'}
            </Btn>
            {runUrl && install !== 'installed' && (
              <div style={{ textAlign: 'center', marginTop: 8 }}><TextBtn icon="code" onClick={() => window.showToast('Opening run on GitHub…', { icon: 'code' })}>Open run on GitHub</TextBtn></div>
            )}
          </div>
        )}
        {failed && (
          <div className="slide-up" style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <Btn kind="danger" icon="copy" onClick={() => { navigator.clipboard && navigator.clipboard.writeText(error || '').catch(()=>{}); window.showToast('Error copied', { tone: 'error', icon: 'copy' }); }}>Copy error</Btn>
            {runUrl && <div style={{ textAlign: 'center' }}><TextBtn icon="code" onClick={() => window.showToast('Opening run on GitHub…', { icon: 'code' })}>Open run on GitHub</TextBtn></div>}
          </div>
        )}
        {inProgress && runUrl && (
          <div style={{ textAlign: 'center' }}><TextBtn icon="code" onClick={() => window.showToast('Opening run on GitHub…', { icon: 'code' })}>Open run on GitHub</TextBtn></div>
        )}
      </div>
    </Layer>
  );
}

window.SignScreen = SignScreen;
