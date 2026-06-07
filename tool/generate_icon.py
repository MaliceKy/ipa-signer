#!/usr/bin/env python3
"""IPA Signer app icon (1024) — FLAT, Apple-style. Navy blueprint with a
prominent grid, a dashed 'app' outline, a solid install arrow, and a flat
accent checkmark badge. No glows or drop shadows. Rendered 4x, downsampled."""
import math
import os
from PIL import Image, ImageDraw

S = 1024
SS = S * 4


def sc(v):
    return v * SS / S


img = Image.new("RGB", (SS, SS), (13, 33, 58))
d = ImageDraw.Draw(img, "RGBA")

# ── flat, gentle vertical gradient ──
top, bot = (12, 31, 55), (17, 43, 76)
for y in range(SS):
    t = y / SS
    d.line([(0, y), (SS, y)], fill=tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))

# ── prominent (flat) drafting grid ──
for i in range(0, S + 1, 64):
    x = sc(i)
    major = (i % 256 == 0)
    col = (120, 188, 248, 100 if major else 52)
    w = int(sc(2.5) if major else sc(1.2))
    d.line([(x, 0), (x, SS)], fill=col, width=w)
    d.line([(0, x), (SS, x)], fill=col, width=w)

# ── corner registration marks ──
cyan = (150, 210, 255, 235)
arm, cw = sc(58), int(sc(7))
for cx, cy, dx, dy in [(sc(76), sc(76), 1, 1), (SS - sc(76), sc(76), -1, 1),
                       (sc(76), SS - sc(76), 1, -1), (SS - sc(76), SS - sc(76), -1, -1)]:
    d.line([(cx, cy), (cx + dx * arm, cy)], fill=cyan, width=cw)
    d.line([(cx, cy), (cx, cy + dy * arm)], fill=cyan, width=cw)


# ── dashed rounded-square (dashes follow the full perimeter) ──
def rounded_rect_points(x0, y0, x1, y1, r, step):
    pts = []

    def arc(cx, cy, a0, a1):
        n = max(6, int(abs(a1 - a0) / 2))
        for i in range(n + 1):
            a = math.radians(a0 + (a1 - a0) * i / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))

    x = x0 + r
    while x <= x1 - r:
        pts.append((x, y0)); x += step
    arc(x1 - r, y0 + r, -90, 0)
    y = y0 + r
    while y <= y1 - r:
        pts.append((x1, y)); y += step
    arc(x1 - r, y1 - r, 0, 90)
    x = x1 - r
    while x >= x0 + r:
        pts.append((x, y1)); x -= step
    arc(x0 + r, y1 - r, 90, 180)
    y = y1 - r
    while y >= y0 + r:
        pts.append((x0, y)); y -= step
    arc(x0 + r, y0 + r, 180, 270)
    return pts


box, br = sc(248), sc(150)
pts = rounded_rect_points(box, box, SS - box, SS - box, br, sc(2))
stroke_r, dash, gap = sc(13), sc(66), sc(48)
period = dash + gap
line_col = (175, 224, 255, 255)
s, prev = 0.0, pts[-1]
for p in pts:
    s += math.hypot(p[0] - prev[0], p[1] - prev[1]); prev = p
    if (s % period) < dash:
        d.ellipse([p[0] - stroke_r, p[1] - stroke_r, p[0] + stroke_r, p[1] + stroke_r], fill=line_col)


# ── solid install arrow, centered ──
def thick(p0, p1, col, r):
    d.line([p0, p1], fill=col, width=int(r * 2))
    for p in (p0, p1):
        d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col)


acx = SS / 2
arrow_col = (205, 235, 255, 255)
ar = sc(22)
thick((acx, sc(372)), (acx, sc(602)), arrow_col, ar)                 # shaft
thick((acx, sc(602)), (acx - sc(86), sc(602) - sc(86)), arrow_col, ar)  # head left
thick((acx, sc(602)), (acx + sc(86), sc(602) - sc(86)), arrow_col, ar)  # head right

# ── flat signed checkmark badge (accent), bottom-right ──
bcx, bcy = sc(S - 308), sc(S - 308)
R = sc(158)
d.ellipse([bcx - R, bcy - R, bcx + R, bcy + R], fill=(13, 33, 58, 255))  # flat knockout ring
d.ellipse([bcx - R + sc(10), bcy - R + sc(10), bcx + R - sc(10), bcy + R - sc(10)], fill=(10, 132, 255, 255))
cr = sc(19)
pa, pb, pc = (bcx - sc(64), bcy + sc(2)), (bcx - sc(12), bcy + sc(52)), (bcx + sc(70), bcy - sc(50))
white = (255, 255, 255, 255)
for q0, q1 in ((pa, pb), (pb, pc)):
    d.line([q0, q1], fill=white, width=int(cr * 2))
for p in (pa, pb, pc):
    d.ellipse([p[0] - cr, p[1] - cr, p[0] + cr, p[1] + cr], fill=white)

out = img.resize((S, S), Image.LANCZOS)
os.makedirs("assets/icon", exist_ok=True)
out.save("assets/icon/icon.png")
print("wrote assets/icon/icon.png")
