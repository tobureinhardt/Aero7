#!/usr/bin/env python3
# Aero7: builds the LoadingSpinner assets from a vector definition (single source of truth).
#   assets/spinner/spinner.svg        animated SVG (SMIL, 18 discrete steps, 0.9s/rev like spinner.gif)
#   assets/spinner/spinner.gif        animated GIF preview (transparent)
#   assets/spinner/spinnersheet.png   6x3 sprite sheet, 18 frames of 160x160 (960x480) used by the Lua component
# Then re-embeds the sheet into src/components/LoadingSpinner.lua and dist/Win7UI.lua (pass --no-patch to skip).
# Roblox ImageLabels cannot display .svg or .gif, so the PNG sheet is the in-game format; svg/gif are for preview/web.
# Requires: pip install playwright pillow && playwright install chromium
import asyncio, base64, io, math, os, re, sys
from playwright.async_api import async_playwright
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "spinner")
FRAMES, COLS, ROWS = 18, 6, 3
STEP = 360 / FRAMES          # 20 deg per frame, clockwise (measured from the original spinner.png)
HEAD0 = 158                  # comet head angle in frame 1 (deg, 0 = east, clockwise), measured from the original sheet
PX = 160                     # px per frame; 6*160=960 stays under Roblox's 1024px texture limit
DUR = 0.9                    # seconds per revolution (18 frames x 0.05s)

R_OUT, R_IN, R_MID = 39.4, 23.2, 31.3


def arc(r, deg_len):
    """Arc ending at angle 0 (east), starting deg_len degrees counter-clockwise behind it."""
    a = math.radians(-deg_len)
    x0, y0 = 40 + r * math.cos(a), 40 + r * math.sin(a)
    return f"M{x0:.3f} {y0:.3f}A{r} {r} 0 {1 if deg_len > 180 else 0} 1 {40 + r:.3f} 40"


def lerp(c1, c2, t):
    return tuple(round(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def comet_layers():
    tail, mid, head = (0x45, 0xB4, 0xB3), (0x64, 0xFF, 0xEF), (0xE8, 0xFF, 0xFF)
    n, out = 36, []
    for k in range(n):                       # longest/dimmest first -> shortest/brightest last
        t = k / (n - 1)
        length = 8 + 105 * (1 - t) ** 1.4   # dense near the head so the tail fades smoothly
        col = lerp(tail, mid, t * 2) if t < 0.5 else lerp(mid, head, (t - 0.5) * 2)
        out.append(f'<path d="{arc(R_MID, length)}" stroke="#%02x%02x%02x" stroke-opacity="0.085"/>' % col)
    for ln, op in ((30, 0.3), (18, 0.3), (9, 0.3)):   # hot white-cyan core at the head
        out.append(f'<path d="{arc(R_MID, ln)}" stroke="#f4ffff" stroke-opacity="{op}"/>')
    return "\n".join(out)


def ring_path(ro, ri):
    return (f"M{40 - ro} 40a{ro} {ro} 0 1 0 {2 * ro} 0a{ro} {ro} 0 1 0 {-2 * ro} 0Z"
            f"M{40 - ri} 40a{ri} {ri} 0 1 0 {2 * ri} 0a{ri} {ri} 0 1 0 {-2 * ri} 0Z")


def svg(rotation, animated=False, size=80):
    if animated:
        vals = ";".join(f"{HEAD0 + i * STEP:g} 40 40" for i in range(FRAMES))
        keys = ";".join(f"{i / FRAMES:.6f}" for i in range(FRAMES))
        rot = (f'<g><animateTransform attributeName="transform" type="rotate" values="{vals}" '
               f'keyTimes="{keys}" dur="{DUR}s" calcMode="discrete" repeatCount="indefinite"/>')
    else:
        rot = f'<g transform="rotate({rotation:g} 40 40)">'
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 80 80" fill="none">
<defs>
<linearGradient id="body" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="80">
<stop offset="0" stop-color="#dbe8ee"/><stop offset="0.11" stop-color="#c5d4da"/><stop offset="0.23" stop-color="#97bed1"/>
<stop offset="0.38" stop-color="#8fb7cc"/><stop offset="0.46" stop-color="#6b9fa8"/><stop offset="0.5" stop-color="#1f6469"/>
<stop offset="0.56" stop-color="#2a7a7e"/><stop offset="0.7" stop-color="#4fb8b0"/><stop offset="0.78" stop-color="#6dcbc4"/>
<stop offset="0.9" stop-color="#86ded7"/><stop offset="1" stop-color="#5fe3d3"/>
</linearGradient>
<linearGradient id="rimOut" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="80">
<stop offset="0" stop-color="#295377"/><stop offset="0.48" stop-color="#3e9197"/><stop offset="0.52" stop-color="#276b70"/><stop offset="1" stop-color="#00c97c"/>
</linearGradient>
<linearGradient id="rimIn" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="80">
<stop offset="0.28" stop-color="#59909d"/><stop offset="0.5" stop-color="#276b70"/><stop offset="0.72" stop-color="#1ac2b4"/>
</linearGradient>
<clipPath id="ring"><path clip-rule="evenodd" d="{ring_path(R_OUT - 0.6, R_IN + 0.6)}"/></clipPath>
<filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="1.8"/></filter>
</defs>
<path fill-rule="evenodd" fill="url(#body)" d="{ring_path(R_OUT, R_IN)}"/>
<g clip-path="url(#ring)"><g filter="url(#soft)">
{rot}
<g stroke-width="13" stroke-linecap="butt">
{comet_layers()}
</g></g></g></g>
<circle cx="40" cy="40" r="{R_OUT - 0.5 - 0.5:.2f}" stroke="url(#rimOut)" stroke-width="1"/>
<circle cx="40" cy="40" r="{R_IN + 0.5 + 0.5:.2f}" stroke="url(#rimIn)" stroke-width="1"/>
<circle cx="40" cy="40" r="{R_OUT - 1.4:.2f}" stroke="#fff" stroke-opacity="0.22" stroke-width="0.8"/>
</svg>'''


async def render(page, svg_text, px):
    await page.set_viewport_size({"width": px, "height": px})
    await page.set_content(f"<html><body style='margin:0;background:transparent'>{svg_text}</body></html>")
    png = await page.screenshot(omit_background=True, clip={"x": 0, "y": 0, "width": px, "height": px})
    return Image.open(io.BytesIO(png)).convert("RGBA")


def chunk_b64(png_bytes, width=120):
    b = base64.b64encode(png_bytes).decode()
    return "\\\n\t".join(b[i:i + width] for i in range(0, len(b), width))


def patch_sources(png_bytes):
    b64 = base64.b64encode(png_bytes).decode()
    # --- src (double-quoted, backslash-newline chunks)
    p = os.path.join(ROOT, "src", "components", "LoadingSpinner.lua")
    s = open(p, encoding="utf-8").read()
    s, n1 = re.subn(r'(local SPINNER_7CSS_SHEET_B64 = ")(.*?)("\n)', lambda m: m.group(1) + chunk_b64(png_bytes) + m.group(3), s, count=1, flags=re.S)
    s, n2 = re.subn(r"local FRAME_SIZE = \d+", f"local FRAME_SIZE = {PX}", s, count=1)
    s, n3 = re.subn(r"-- \d+x\d+px sprite sheet \(.*?\)\n",
                    f"-- {COLS * PX}x{ROWS * PX}px sprite sheet ({FRAMES} frames x {PX}x{PX}px in {COLS}x{ROWS} grid, rendered from vector by tools/build_spinner_sheet.py)\n", s, count=1)
    s, n4 = re.subn(r"Win7UI/spinner_\w+\.png", "Win7UI/spinner_aero7_v2.png", s, count=1)
    assert (n1, n2, n3, n4) == (1, 1, 1, 1), (n1, n2, n3, n4)
    open(p, "w", encoding="utf-8").write(s)
    # --- dist (single-quoted, single line)
    p = os.path.join(ROOT, "dist", "Win7UI.lua")
    if os.path.isfile(p):
        d = open(p, encoding="utf-8").read()
        d, m1 = re.subn(r"(local SPINNER_7CSS_SHEET_B64 = ')(.*?)('\n)", lambda m: m.group(1) + b64 + m.group(3), d, count=1, flags=re.S)
        d, m2 = re.subn(r"local FRAME_SIZE = \d+", f"local FRAME_SIZE = {PX}", d, count=1)
        d, m3 = re.subn(r"Win7UI/spinner_\w+\.png", "Win7UI/spinner_aero7_v2.png", d, count=1)
        assert (m1, m2, m3) == (1, 1, 1), (m1, m2, m3)
        open(p, "w", encoding="utf-8").write(d)


async def main():
    os.makedirs(OUT, exist_ok=True)
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page()
        frames = [await render(pg, svg(HEAD0 + i * STEP, size=PX), PX) for i in range(FRAMES)]
        # verify the animated SVG shows the same pixels as the sheet frames
        anim = svg(0, animated=True, size=PX)
        await pg.set_viewport_size({"width": PX, "height": PX})
        await pg.set_content(f"<html><body style='margin:0;background:transparent'>{anim}</body></html>")
        for i in (0, 5, 11, 17):
            await pg.evaluate(f"document.querySelector('svg').pauseAnimations();document.querySelector('svg').setCurrentTime({(i + 0.5) * DUR / FRAMES})")
            shot = Image.open(io.BytesIO(await pg.screenshot(omit_background=True, clip={"x": 0, "y": 0, "width": PX, "height": PX}))).convert("RGBA")
            diff = max(max(abs(a - b) for a, b in zip(x, y)) for x, y in zip(shot.get_flattened_data() if hasattr(shot,'get_flattened_data') else shot.getdata(), frames[i].get_flattened_data() if hasattr(frames[i],'get_flattened_data') else frames[i].getdata()))
            print(f"animated svg vs sheet frame {i + 1}: max channel diff = {diff}")
            assert diff == 0, "animated SVG does not match sheet"
        await b.close()
    sheet = Image.new("RGBA", (COLS * PX, ROWS * PX), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, ((i % COLS) * PX, (i // COLS) * PX))
    sheet_path = os.path.join(OUT, "spinnersheet.png")
    sheet.save(sheet_path, optimize=True)
    open(os.path.join(OUT, "spinner.svg"), "w", encoding="utf-8").write(svg(0, animated=True, size=80))
    gif = []
    for f in frames:
        pal = f.convert("RGB").quantize(colors=255, method=Image.Quantize.MEDIANCUT)
        mask = f.getchannel("A").point(lambda a: 255 if a < 128 else 0)
        pal.paste(255, mask)
        gif.append(pal)
    gif[0].save(os.path.join(OUT, "spinner.gif"), save_all=True, append_images=gif[1:], duration=int(DUR / FRAMES * 1000), loop=0, transparency=255, disposal=2)
    print("sheet", sheet.size, os.path.getsize(sheet_path), "bytes")
    if "--no-patch" not in sys.argv:
        patch_sources(open(sheet_path, "rb").read())
        print("patched src/components/LoadingSpinner.lua and dist/Win7UI.lua")


asyncio.run(main())
