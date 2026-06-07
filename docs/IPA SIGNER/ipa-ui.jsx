// ipa-ui.jsx — shared iOS UI components for IPA Signer (exported to window)
const { useState, useRef, useEffect, useCallback } = React;

/* ─────────────────────────────────────────────────────────────
   AppIcon — tinted squircle placeholder with monogram
   ───────────────────────────────────────────────────────────── */
function AppIcon({ name = '?', tint = '#8E8E93', size = 56, radius }) {
  const ratio = window.__iconRatio || 0.225;
  const r = radius != null ? radius : Math.round(size * ratio);
  const letters = name.replace(/[^A-Za-z0-9]/g, '').slice(0, 2).toUpperCase() || '?';
  return (
    <div style={{
      width: size, height: size, borderRadius: r, flexShrink: 0,
      background: `linear-gradient(160deg, ${tint}, color-mix(in srgb, ${tint} 72%, #000))`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: 'inset 0 0 0 0.5px rgba(255,255,255,0.18), inset 0 1px 1px rgba(255,255,255,0.25)',
      position: 'relative', overflow: 'hidden',
    }}>
      <span style={{
        color: '#fff', fontWeight: 600, fontSize: size * 0.4,
        letterSpacing: -0.5, textShadow: '0 1px 1px rgba(0,0,0,0.18)',
      }}>{letters}</span>
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Spinner — circular indeterminate
   ───────────────────────────────────────────────────────────── */
function Spinner({ size = 20, width = 2.5, color = 'currentColor', track = 'transparent' }) {
  return (
    <svg className="spin" width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
      <circle cx="12" cy="12" r="9" fill="none" stroke={track} strokeWidth={width} />
      <circle cx="12" cy="12" r="9" fill="none" stroke={color} strokeWidth={width}
              strokeLinecap="round" strokeDasharray="44" strokeDashoffset="32" />
    </svg>
  );
}

/* ─────────────────────────────────────────────────────────────
   Btn — full-width pill button (primary / success / danger / neutral)
   ───────────────────────────────────────────────────────────── */
function Btn({ children, onClick, kind = 'primary', loading = false, disabled = false,
               icon, full = true, size = 'lg', style = {} }) {
  const bgMap = {
    primary: 'var(--accent)', success: 'var(--green)', danger: 'var(--red)',
    neutral: 'var(--fill)', amber: 'var(--amber)',
  };
  const isTinted = kind !== 'neutral';
  const h = size === 'lg' ? 50 : size === 'md' ? 44 : 36;
  const fs = size === 'lg' ? 17 : size === 'sm' ? 15 : 17;
  const off = disabled || loading;
  return (
    <button className="pressable" onClick={off ? undefined : onClick} disabled={off}
      style={{
        width: full ? '100%' : 'auto', height: h, borderRadius: h / 2,
        background: bgMap[kind], color: isTinted ? '#fff' : 'var(--accent)',
        fontWeight: 600, fontSize: fs, letterSpacing: -0.4,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        padding: '0 22px', opacity: off ? 0.5 : 1, cursor: off ? 'default' : 'pointer',
        ...style,
      }}>
      {loading ? <Spinner size={20} color={isTinted ? '#fff' : 'var(--accent)'} />
        : (<>{icon && <Icon name={icon} size={19} stroke={2} />}{children}</>)}
    </button>
  );
}

/* tertiary text button with optional leading icon */
function TextBtn({ children, onClick, icon, color = 'var(--accent)', size = 15, weight = 500, style = {} }) {
  return (
    <button className="pressable" onClick={onClick} style={{
      display: 'inline-flex', alignItems: 'center', gap: 5, color,
      fontSize: size, fontWeight: weight, letterSpacing: -0.2, padding: '6px 2px', ...style,
    }}>
      {icon && <Icon name={icon} size={size + 2} stroke={2} />}
      {children}
    </button>
  );
}

/* ─────────────────────────────────────────────────────────────
   SearchBar
   ───────────────────────────────────────────────────────────── */
function SearchBar({ value, onChange, placeholder = 'Search', onFocus, onBlur }) {
  const [focus, setFocus] = useState(false);
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <div style={{
        flex: 1, height: 36, borderRadius: 10, background: 'var(--fill)',
        display: 'flex', alignItems: 'center', gap: 6, padding: '0 8px',
        transition: 'background .15s',
      }}>
        <Icon name="search" size={17} stroke={2.2} color="var(--label-secondary)" />
        <input value={value} placeholder={placeholder}
          onChange={(e) => onChange(e.target.value)}
          onFocus={() => { setFocus(true); onFocus && onFocus(); }}
          onBlur={() => { setFocus(false); onBlur && onBlur(); }}
          style={{ flex: 1, fontSize: 17, letterSpacing: -0.4, minWidth: 0 }} />
        {value && (
          <button className="pressable" onClick={() => onChange('')}
            style={{ display: 'flex', color: 'var(--label-tertiary)' }}>
            <Icon name="x-circle" size={18} stroke={0} color="var(--label-tertiary)" />
          </button>
        )}
      </div>
      {focus && (
        <button className="pressable" onMouseDown={(e) => e.preventDefault()}
          onClick={() => onChange('')}
          style={{ color: 'var(--accent)', fontSize: 17, letterSpacing: -0.4 }}>Cancel</button>
      )}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Field — text input, optional obscured w/ reveal, leading icon
   ───────────────────────────────────────────────────────────── */
function Field({ value, onChange, placeholder, obscure = false, icon, mono = false,
                 autoCapitalize = 'off', onEnter, style = {} }) {
  const [reveal, setReveal] = useState(false);
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 9, height: 44,
      background: 'var(--bg-elevated)', borderRadius: 10, padding: '0 14px',
      boxShadow: 'inset 0 0 0 0.5px var(--separator-strong)', ...style,
    }}>
      {icon && <Icon name={icon} size={18} color="var(--label-secondary)" />}
      <input
        value={value}
        placeholder={placeholder}
        type={obscure && !reveal ? 'password' : 'text'}
        autoCapitalize={autoCapitalize} autoCorrect="off" spellCheck={false}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={(e) => { if (e.key === 'Enter' && onEnter) onEnter(); }}
        style={{ flex: 1, fontSize: 17, letterSpacing: -0.3, minWidth: 0,
                 fontFamily: mono ? 'var(--mono)' : 'inherit' }} />
      {obscure && value && (
        <button className="pressable" onClick={() => setReveal(r => !r)}
          style={{ color: 'var(--label-secondary)', fontSize: 13, fontWeight: 500 }}>
          {reveal ? 'Hide' : 'Show'}
        </button>
      )}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Segmented control
   ───────────────────────────────────────────────────────────── */
function Segmented({ options, value, onChange }) {
  const idx = options.findIndex(o => (o.value ?? o) === value);
  return (
    <div style={{
      position: 'relative', display: 'flex', height: 32, padding: 2,
      background: 'var(--fill)', borderRadius: 9,
    }}>
      <div style={{
        position: 'absolute', top: 2, bottom: 2, left: 2,
        width: `calc((100% - 4px) / ${options.length})`,
        transform: `translateX(${idx * 100}%)`,
        background: 'var(--bg-elevated)', borderRadius: 7,
        boxShadow: '0 1px 3px rgba(0,0,0,0.12), 0 0 0 0.5px rgba(0,0,0,0.04)',
        transition: 'transform .26s cubic-bezier(.3,.8,.3,1)',
      }} />
      {options.map((o, i) => {
        const val = o.value ?? o, label = o.label ?? o;
        const active = val === value;
        return (
          <button key={val} onClick={() => onChange(val)} style={{
            flex: 1, position: 'relative', zIndex: 1, fontSize: 13, fontWeight: active ? 600 : 500,
            color: 'var(--label)', letterSpacing: -0.1, transition: 'font-weight .2s',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5,
          }}>
            {o.icon && <Icon name={o.icon} size={15} stroke={2} />}
            {label}
          </button>
        );
      })}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Progress bar — determinate / indeterminate / colored
   ───────────────────────────────────────────────────────────── */
function Progress({ value = 0, color = 'var(--accent)', indeterminate = false, height = 8, animate = true }) {
  return (
    <div style={{
      position: 'relative', height, borderRadius: height / 2,
      background: 'var(--fill-strong)', overflow: 'hidden',
    }}>
      {indeterminate ? (
        <div style={{
          position: 'absolute', top: 0, bottom: 0, width: '40%', borderRadius: height / 2,
          background: color, animation: 'ipa-indeterminate 1.1s ease-in-out infinite',
        }} />
      ) : (
        <div style={{
          height: '100%', width: `${Math.max(0, Math.min(100, value))}%`,
          borderRadius: height / 2, background: color,
          transition: animate ? 'width .5s cubic-bezier(.3,.8,.3,1)' : 'none',
        }} />
      )}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Pill — status / phase chip
   ───────────────────────────────────────────────────────────── */
function Pill({ children, tone = 'neutral', icon, dot = false, spin = false }) {
  const toneMap = {
    blue: 'var(--accent)', green: 'var(--green)', red: 'var(--red)',
    amber: 'var(--amber)', neutral: 'var(--label-secondary)',
  };
  const c = toneMap[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      height: 26, padding: '0 10px', borderRadius: 13,
      background: `color-mix(in srgb, ${c} 14%, transparent)`,
      color: c, fontSize: 13, fontWeight: 600, letterSpacing: -0.1,
    }}>
      {spin && <Spinner size={13} width={2.4} color={c} />}
      {dot && !spin && <span style={{ width: 7, height: 7, borderRadius: 4, background: c }} />}
      {icon && !spin && <Icon name={icon} size={14} stroke={2.4} />}
      {children}
    </span>
  );
}

/* ─────────────────────────────────────────────────────────────
   Grouped list (inset card) + rows + headers
   ───────────────────────────────────────────────────────────── */
function Group({ children, style = {}, inset = true }) {
  return (
    <div style={{
      background: 'var(--bg-elevated)', borderRadius: 12,
      margin: inset ? '0 16px' : 0, overflow: 'hidden',
      boxShadow: '0 0 0 0.5px var(--separator)', ...style,
    }}>{children}</div>
  );
}
function Row({ children, onClick, last = false, leftInset = 16, style = {}, align = 'center' }) {
  return (
    <div className={onClick ? 'row-press' : ''} onClick={onClick} style={{
      position: 'relative', display: 'flex', alignItems: align, gap: 12,
      padding: '11px 16px', minHeight: 44, cursor: onClick ? 'pointer' : 'default', ...style,
    }}>
      {children}
      {!last && <div style={{ position: 'absolute', left: leftInset, right: 0, bottom: 0, height: 0.5, background: 'var(--separator)' }} />}
    </div>
  );
}
function SectionHeader({ children, style = {} }) {
  return (
    <div className="t-footnote" style={{
      textTransform: 'uppercase', color: 'var(--label-secondary)',
      padding: '0 16px 6px', margin: '0 16px', letterSpacing: 0.4, ...style,
    }}>{children}</div>
  );
}
function SectionFooter({ children }) {
  return (
    <div className="t-footnote" style={{ color: 'var(--label-secondary)', padding: '7px 16px 0', margin: '0 16px', letterSpacing: -0.08 }}>
      {children}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   EmptyState
   ───────────────────────────────────────────────────────────── */
function EmptyState({ icon, title, message, action }) {
  return (
    <div className="fade-in" style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center',
      padding: '64px 40px', gap: 6,
    }}>
      {icon && (
        <div style={{
          width: 66, height: 66, borderRadius: 18, marginBottom: 8,
          background: 'var(--fill)', display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name={icon} size={32} stroke={1.7} color="var(--label-tertiary)" />
        </div>
      )}
      <div className="t-title3" style={{ color: 'var(--label)' }}>{title}</div>
      <div className="t-subhead" style={{ color: 'var(--label-secondary)', maxWidth: 260, textWrap: 'pretty' }}>{message}</div>
      {action && <div style={{ marginTop: 14 }}>{action}</div>}
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   Screen — top chrome (collapsing large title) + scroll + pull-to-refresh
   ───────────────────────────────────────────────────────────── */
const STATUS_INSET = 59;
const COMPACT_BAR = 44;

function Screen({ title, large = true, leading, trailing, search, children,
                  onRefresh, refreshing = false, bottomInset = 0, contentPad = true }) {
  const scrollRef = useRef(null);
  const [scrolled, setScrolled] = useState(false);
  const [showCompact, setShowCompact] = useState(!large);
  const [pull, setPull] = useState(0);
  const drag = useRef({ active: false, startY: 0, can: false });

  const onScroll = () => {
    const st = scrollRef.current ? scrollRef.current.scrollTop : 0;
    setScrolled(st > 1);
    if (large) setShowCompact(st > 34);
  };

  // pointer-based pull to refresh
  const onDown = (e) => {
    if (!onRefresh) return;
    const st = scrollRef.current ? scrollRef.current.scrollTop : 0;
    drag.current = { active: true, startY: e.clientY, can: st <= 0 };
  };
  const onMove = (e) => {
    if (!drag.current.active || !drag.current.can || refreshing) return;
    const dy = e.clientY - drag.current.startY;
    if (dy > 0) { setPull(Math.min(90, dy * 0.5)); }
  };
  const onUp = () => {
    if (!drag.current.active) return;
    drag.current.active = false;
    if (pull > 56 && onRefresh && !refreshing) onRefresh();
    setPull(0);
  };

  const ptrSpin = refreshing || pull > 56;
  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', background: 'var(--bg)' }}>
      {/* top chrome */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, zIndex: 10,
        height: STATUS_INSET + COMPACT_BAR, pointerEvents: 'none',
      }}>
        <div style={{
          position: 'absolute', inset: 0,
          background: scrolled ? 'var(--chrome)' : 'transparent',
          backdropFilter: scrolled ? 'saturate(180%) blur(20px)' : 'none',
          WebkitBackdropFilter: scrolled ? 'saturate(180%) blur(20px)' : 'none',
          transition: 'background .25s',
        }} />
        {scrolled && <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, height: 0.5, background: 'var(--chrome-border)' }} />}
        <div style={{
          position: 'absolute', top: STATUS_INSET, left: 0, right: 0, height: COMPACT_BAR,
          display: 'flex', alignItems: 'center', padding: '0 8px', pointerEvents: 'auto',
        }}>
          <div style={{ flex: 1, display: 'flex', justifyContent: 'flex-start' }}>{leading}</div>
          <div className="t-headline" style={{
            position: 'absolute', left: 0, right: 0, textAlign: 'center', pointerEvents: 'none',
            color: 'var(--label)', opacity: showCompact ? 1 : 0, transform: showCompact ? 'none' : 'translateY(3px)',
            transition: 'opacity .2s, transform .2s', padding: '0 80px',
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{title}</div>
          <div style={{ flex: 1, display: 'flex', justifyContent: 'flex-end', gap: 2 }}>{trailing}</div>
        </div>
      </div>

      {/* scroll area */}
      <div ref={scrollRef} onScroll={onScroll}
        onPointerDown={onDown} onPointerMove={onMove} onPointerUp={onUp} onPointerCancel={onUp}
        style={{
          position: 'absolute', inset: 0, overflowY: 'auto', overflowX: 'hidden',
          paddingTop: STATUS_INSET + COMPACT_BAR, WebkitOverflowScrolling: 'touch',
        }}>
        {/* pull-to-refresh indicator */}
        {onRefresh && (
          <div style={{
            height: pull, marginTop: refreshing ? 8 : 0, display: 'flex', alignItems: 'flex-end',
            justifyContent: 'center', overflow: 'hidden', transition: drag.current.active ? 'none' : 'height .25s, margin .25s',
          }}>
            <div style={{ paddingBottom: 8, opacity: ptrSpin ? 1 : pull / 56 }}>
              {ptrSpin ? <Spinner size={22} color="var(--label-tertiary)" />
                : <Icon name="refresh" size={22} color="var(--label-tertiary)" style={{ transform: `rotate(${pull * 3}deg)` }} />}
            </div>
          </div>
        )}
        {refreshing && pull === 0 && (
          <div style={{ display: 'flex', justifyContent: 'center', padding: '4px 0 8px' }}>
            <Spinner size={22} color="var(--label-tertiary)" />
          </div>
        )}

        {large && (
          <div style={{ padding: '4px 16px 2px' }}>
            <h1 className="t-large" style={{ margin: 0, color: 'var(--label)' }}>{title}</h1>
          </div>
        )}
        {search && <div style={{ padding: '6px 16px 4px' }}>{search}</div>}
        <div style={{ paddingTop: contentPad ? 10 : 0, paddingBottom: bottomInset + 24 }}>
          {children}
        </div>
      </div>
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────
   TabBar — bottom, translucent, N tabs
   ───────────────────────────────────────────────────────────── */
function TabBar({ tabs, active, onChange }) {
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 30,
      paddingBottom: 26, paddingTop: 8,
      background: 'var(--chrome)', backdropFilter: 'saturate(180%) blur(20px)',
      WebkitBackdropFilter: 'saturate(180%) blur(20px)',
      borderTop: '0.5px solid var(--chrome-border)',
      display: 'flex', justifyContent: 'space-around',
    }}>
      {tabs.map(t => {
        const on = t.id === active;
        return (
          <button key={t.id} onClick={() => onChange(t.id)} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            color: on ? 'var(--accent)' : 'var(--label-tertiary)', flex: 1, paddingTop: 2,
            transition: 'color .15s',
          }}>
            <Icon name={on ? t.icon + '-fill' : t.icon} size={26} stroke={1.9} />
            <span style={{ fontSize: 10, fontWeight: on ? 600 : 500, letterSpacing: 0.1 }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

Object.assign(window, {
  AppIcon, Spinner, Btn, TextBtn, SearchBar, Field, Segmented, Progress, Pill,
  Group, Row, SectionHeader, SectionFooter, EmptyState, Screen, TabBar,
  STATUS_INSET, COMPACT_BAR,
});
