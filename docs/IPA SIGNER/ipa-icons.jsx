// ipa-icons.jsx — SF-Symbols-style stroke icons. Exported to window as <Icon name=.. size=.. />
(function () {
  const S = (paths, { fill = false, vb = 24 } = {}) => ({ paths, fill, vb });

  // stroke icons use currentColor stroke; fill icons use currentColor fill
  const ICONS = {
    // ── tab bar ──
    catalog: S(['M4 5h6v6H4zM14 5h6v6h-6zM4 15h6v6H4zM14 15h6v6h-6z']),
    'catalog-fill': S(['M4 5h6v6H4zM14 5h6v6h-6zM4 15h6v6H4zM14 15h6v6h-6z'], { fill: true }),
    upload: S(['M12 16V4M12 4l-4 4M12 4l4 4', 'M4 14v4a2 2 0 002 2h12a2 2 0 002-2v-4']),
    'upload-fill': S(['M5 12h4v5h6v-5h4l-7-8z', 'M4 19h16'], { fill: true }),
    library: S(['M4 8h16M6 8v11a1 1 0 001 1h10a1 1 0 001-1V8M9 4h6l1 4H8z']),
    'library-fill': S(['M4 7.5h16l-1.2 12a1.2 1.2 0 01-1.2 1.1H6.4a1.2 1.2 0 01-1.2-1.1zM9 4h6l1.4 3.5H7.6z'], { fill: true }),

    // ── chrome ──
    search: S(['M11 11m-7 0a7 7 0 1014 0a7 7 0 10-14 0', 'M20 20l-4-4']),
    folder: S(['M3 7a2 2 0 012-2h4l2 2h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z']),
    gear: S(['M12 9a3 3 0 100 6 3 3 0 000-6z', 'M19.4 13a1.6 1.6 0 00.3 1.7l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.6 1.6 0 00-2.7 1.1V20a2 2 0 11-4 0v-.1A1.6 1.6 0 007 18.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1A1.6 1.6 0 004 13H3.9a2 2 0 110-4H4a1.6 1.6 0 001.4-2.7l-.1-.1a2 2 0 112.8-2.8l.1.1A1.6 1.6 0 0011 4V3.9a2 2 0 114 0V4a1.6 1.6 0 002.7 1.1l.1-.1a2 2 0 112.8 2.8l-.1.1A1.6 1.6 0 0020 11h.1a2 2 0 110 4H20a1.6 1.6 0 00-1.4 1z']),
    'chevron-left': S(['M15 4l-8 8 8 8']),
    'chevron-right': S(['M9 4l8 8-8 8']),
    'chevron-down': S(['M5 9l7 7 7-7']),
    trash: S(['M4 7h16M9 7V5a1 1 0 011-1h4a1 1 0 011 1v2M6 7l1 13a1 1 0 001 1h8a1 1 0 001-1l1-13']),
    doc: S(['M7 3h7l5 5v13a1 1 0 01-1 1H7a1 1 0 01-1-1V4a1 1 0 011-1z', 'M14 3v5h5']),
    link: S(['M9 14a4 4 0 005.7.3l3-3A4 4 0 1012 6l-1 1', 'M15 10a4 4 0 00-5.7-.3l-3 3A4 4 0 1012 18l1-1']),
    xmark: S(['M6 6l12 12M18 6L6 18']),
    'x-circle': S(['M12 12m-9 0a9 9 0 1018 0a9 9 0 10-18 0', 'M9 9l6 6M15 9l-6 6']),
    check: S(['M5 13l4 4L19 7']),
    'check-circle': S(['M12 12m-9 0a9 9 0 1018 0a9 9 0 10-18 0', 'M8 12.5l2.5 2.5L16 9.5']),
    'exclaim-circle': S(['M12 12m-9 0a9 9 0 1018 0a9 9 0 10-18 0', 'M12 7.5v5.5', 'M12 16.2v.1']),
    share: S(['M12 15V4M12 4l-4 4M12 4l4 4', 'M5 13v5a2 2 0 002 2h10a2 2 0 002-2v-5']),
    copy: S(['M9 9h9a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1v-9a1 1 0 011-1z', 'M5 15H4a1 1 0 01-1-1V4a1 1 0 011-1h10a1 1 0 011 1v1']),
    plus: S(['M12 5v14M5 12h14']),
    refresh: S(['M20 11a8 8 0 10-2.3 6.6M20 20v-5h-5']),
    code: S(['M9 8l-5 4 5 4M15 8l5 4-5 4']),
    key: S(['M14.5 9.5m-4 0a4 4 0 108 0a4 4 0 10-8 0', 'M11.5 12.5L4 20v0M7 17l2 2M9 15l2 2']),
    clock: S(['M12 12m-9 0a9 9 0 1018 0a9 9 0 10-18 0', 'M12 7v5l3.5 2']),
    'download-circle': S(['M12 12m-9 0a9 9 0 1018 0a9 9 0 10-18 0', 'M12 7v8M12 15l-3.2-3.2M12 15l3.2-3.2']),
    bolt: S(['M13 3L5 13h6l-1 8 8-10h-6z']),
    info: S(['M12 12m-9 0a9 9 0 1018 0a9 9 0 10-18 0', 'M12 11v5', 'M12 8v.1']),
    shield: S(['M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z']),
    moon: S(['M20 13.5A8 8 0 0110.5 4 7 7 0 1020 13.5z']),
    iphone: S(['M8 3h8a2 2 0 012 2v14a2 2 0 01-2 2H8a2 2 0 01-2-2V5a2 2 0 012-2z', 'M10 5h4']),

    // ── console step states ──
    'step-queued': S(['M12 12m-7 0a7 7 0 1014 0a7 7 0 10-14 0']),
    'step-skipped': S(['M12 12m-7 0a7 7 0 1014 0a7 7 0 10-14 0', 'M7 17L17 7']),
    dot: S(['M12 12m-4 0a4 4 0 108 0a4 4 0 10-8 0'], { fill: true }),
  };

  function Icon({ name, size = 22, stroke = 1.8, color, style = {}, className = '' }) {
    const def = ICONS[name];
    if (!def) return null;
    const common = {
      width: size, height: size, viewBox: `0 0 ${def.vb} ${def.vb}`,
      style: { display: 'block', color: color || 'currentColor', flexShrink: 0, ...style },
      className,
    };
    if (def.fill) {
      return (
        <svg {...common}>
          {def.paths.map((d, i) => <path key={i} d={d} fill="currentColor" />)}
        </svg>
      );
    }
    return (
      <svg {...common} fill="none">
        {def.paths.map((d, i) => (
          <path key={i} d={d} stroke="currentColor" strokeWidth={stroke}
                strokeLinecap="round" strokeLinejoin="round" />
        ))}
      </svg>
    );
  }

  window.Icon = Icon;
  window.ICON_NAMES = Object.keys(ICONS);
})();
