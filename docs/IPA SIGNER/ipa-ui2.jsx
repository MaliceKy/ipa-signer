// ipa-ui2.jsx — console, toast, chrome buttons, sheet (exported to window)
const { useState: useState2, useRef: useRef2, useEffect: useEffect2 } = React;

/* ─────────────────────────────────────────────────────────────
   Chrome buttons (top bar) — plain accent icon / text, and back
   ───────────────────────────────────────────────────────────── */
function ChromeBtn({ icon, label, onClick, color = 'var(--accent)', badge }) {
  return (
    <button className="pressable" onClick={onClick} style={{
      display: 'inline-flex', alignItems: 'center', gap: 4, color,
      padding: '6px 8px', fontSize: 17, letterSpacing: -0.4, position: 'relative',
    }}>
      {icon && <Icon name={icon} size={23} stroke={2} />}
      {label && <span style={{ fontWeight: icon ? 400 : 400 }}>{label}</span>}
      {badge != null && (
        <span style={{
          position: 'absolute', top: 0, right: 2, minWidth: 16, height: 16, padding: '0 4px',
          borderRadius: 8, background: 'var(--red)', color: '#fff', fontSize: 10, fontWeight: 700,
          display: 'flex', alignItems: 'center', justifyContent: 'center', boxSizing: 'border-box',
        }}>{badge}</span>
      )}
    </button>
  );
}
function BackBtn({ onClick, label = 'Back' }) {
  return (
    <button className="pressable" onClick={onClick} style={{
      display: 'inline-flex', alignItems: 'center', gap: 1, color: 'var(--accent)',
      padding: '6px 6px 6px 2px', fontSize: 17, letterSpacing: -0.4,
    }}>
      <Icon name="chevron-left" size={24} stroke={2.4} />
      <span>{label}</span>
    </button>
  );
}

/* ─────────────────────────────────────────────────────────────
   Console — monospace scrolling log w/ per-line status icons
   steps: [{ name, status: queued|running|success|skipped|failed }]
   lines: [{ t, text, tone }]
   ───────────────────────────────────────────────────────────── */
function StepGlyph({ status }) {
  if (status === 'running') return <Spinner size={15} width={2.6} color="var(--accent)" />;
  if (status === 'success') return <Icon name="check-circle" size={15} stroke={2.4} color="var(--green)" />;
  if (status === 'failed') return <Icon name="x-circle" size={15} stroke={2.4} color="var(--red)" />;
  if (status === 'skipped') return <Icon name="step-skipped" size={15} stroke={2.2} color="var(--label-tertiary)" />;
  return <Icon name="step-queued" size={15} stroke={2.2} color="var(--label-tertiary)" />;
}

function Console({ steps = [], lines = [], onCopy, height = 248 }) {
  const ref = useRef2(null);
  const stick = useRef2(true);
  useEffect2(() => {
    const el = ref.current; if (!el) return;
    if (stick.current) el.scrollTop = el.scrollHeight;
  }, [steps, lines]);
  const onScroll = () => {
    const el = ref.current; if (!el) return;
    stick.current = el.scrollHeight - el.scrollTop - el.clientHeight < 24;
  };
  const toneColor = (tone) => tone === 'error' ? 'var(--red)' : tone === 'ok' ? 'var(--green)'
    : tone === 'accent' ? 'var(--accent)' : 'var(--label-secondary)';

  return (
    <div style={{ background: 'var(--bg-elevated)', borderRadius: 14, boxShadow: '0 0 0 0.5px var(--separator)', overflow: 'hidden' }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '10px 14px', borderBottom: '0.5px solid var(--separator)',
      }}>
        <span className="t-footnote" style={{ fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.4, color: 'var(--label-secondary)' }}>Console</span>
        <button className="pressable" onClick={onCopy} style={{ display: 'inline-flex', alignItems: 'center', gap: 5, color: 'var(--accent)', fontSize: 13, fontWeight: 500 }}>
          <Icon name="copy" size={15} stroke={2} /> Copy
        </button>
      </div>
      <div ref={ref} onScroll={onScroll} style={{
        height, overflowY: 'auto', padding: '10px 14px',
        fontFamily: 'var(--mono)', fontSize: 12.5, lineHeight: '20px',
        userSelect: 'text', WebkitUserSelect: 'text',
      }}>
        {steps.map((s, i) => (
          <div key={'s' + i} style={{
            display: 'flex', alignItems: 'center', gap: 9, padding: '3px 0',
            opacity: s.status === 'queued' ? 0.55 : 1, transition: 'opacity .3s',
          }}>
            <span style={{ width: 16, display: 'flex', justifyContent: 'center', flexShrink: 0 }}><StepGlyph status={s.status} /></span>
            <span style={{
              color: s.status === 'failed' ? 'var(--red)' : 'var(--label)',
              fontWeight: s.status === 'running' ? 600 : 400,
              fontFamily: 'var(--font)', fontSize: 14, letterSpacing: -0.2,
            }}>{s.name}</span>
          </div>
        ))}
        {(steps.length > 0 && lines.length > 0) && (
          <div style={{ height: 1, background: 'var(--separator)', margin: '8px 0' }} />
        )}
        {lines.map((l, i) => (
          <div key={'l' + i} className="fade-in" style={{ display: 'flex', gap: 8, color: toneColor(l.tone) }}>
            <span style={{ color: 'var(--label-tertiary)', flexShrink: 0 }}>{l.t}</span>
            <span style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>{l.text}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Toast — imperative: window.showToast(msg, { tone, icon })
   ───────────────────────────────────────────────────────────── */
function ToastHost() {
  const [items, setItems] = useState2([]);
  useEffect2(() => {
    const handler = (e) => {
      const id = Math.random().toString(36).slice(2);
      const item = { id, ...e.detail };
      setItems(list => [...list, item]);
      setTimeout(() => setItems(list => list.filter(x => x.id !== id)), e.detail.duration || 2200);
    };
    window.addEventListener('ipa-toast', handler);
    return () => window.removeEventListener('ipa-toast', handler);
  }, []);
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 96, zIndex: 200,
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, pointerEvents: 'none',
    }}>
      {items.map(it => {
        const c = it.tone === 'error' ? 'var(--red)' : it.tone === 'ok' ? 'var(--green)' : 'var(--label)';
        return (
          <div key={it.id} style={{
            animation: 'ipa-toast-in .3s cubic-bezier(.2,.8,.3,1) both',
            display: 'flex', alignItems: 'center', gap: 8, maxWidth: 320,
            padding: '11px 16px', borderRadius: 22,
            background: 'var(--bg-elevated)', boxShadow: 'var(--shadow-pop), 0 0 0 0.5px var(--separator)',
          }}>
            {it.icon && <Icon name={it.icon} size={18} stroke={2.2} color={c} />}
            <span className="t-subhead" style={{ fontWeight: 500, color: 'var(--label)' }}>{it.msg}</span>
          </div>
        );
      })}
    </div>
  );
}
window.showToast = (msg, opts = {}) => window.dispatchEvent(new CustomEvent('ipa-toast', { detail: { msg, ...opts } }));

/* ─────────────────────────────────────────────────────────────
   Sheet / pushed-screen container with slide animation
   variant: push (from right) | modal (from bottom)
   ───────────────────────────────────────────────────────────── */
function Layer({ children, variant = 'push' }) {
  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 40, overflow: 'hidden' }}>
      {/* opaque backdrop so the previous screen never peeks during the slide */}
      <div style={{ position: 'absolute', inset: 0, background: 'var(--bg)' }} />
      <div className="ipa-layer" style={{
        position: 'absolute', inset: 0, background: 'var(--bg)', overflow: 'hidden',
        animation: `${variant === 'modal' ? 'ipa-modal-in' : 'ipa-push-in'} .34s cubic-bezier(.2,.8,.3,1) both`,
      }}>{children}</div>
    </div>
  );
}

Object.assign(window, { ChromeBtn, BackBtn, Console, ToastHost, Layer });
