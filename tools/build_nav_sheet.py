#!/usr/bin/env python3
# Aero7: builds assets/nav/navsheet.png (Back/Forward orb states + glass frame, 4x) from assets/nav/back-forward-orbs.svg.
# Requires: pip install playwright pillow && playwright install chromium
# After changing the sheet, re-embed it: base64 of navsheet.png -> SHEET_B64 chunks in src/core/NavSprites.lua, then run tools/build.py.
import re, asyncio, io
from playwright.async_api import async_playwright
from PIL import Image

import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = open(os.path.join(ROOT, "assets", "nav", "back-forward-orbs.svg"), encoding="utf-8").read()

# --- 1. remove the duplicated 2nd back-orb layer (paint8..11 / filter2) so edges aren't double-drawn
dup_start = SRC.index('<ellipse cx="12.5" cy="13" rx="12.5" ry="13" fill="url(#paint8_radial_60_471)"/>')
dup_end = SRC.index('<defs>')
clean = SRC[:dup_start] + SRC[dup_end:]
assert 'paint8_radial' in clean  # gradient defs remain (harmless, unused)

def wrap_body(svg):
    # forward orb: from its first ellipse (paint0) up to its arrow group (filter0)
    a = svg.index('<ellipse cx="42.5" cy="13" rx="12.5" ry="13" fill="url(#paint0_radial_60_471)"/>')
    b = svg.index('<g filter="url(#filter0_d_60_471)">')
    svg = svg[:a] + '<g class="bodyf">' + svg[a:b] + '</g>' + svg[b:]
    # back orb: from its first ellipse (paint4) up to its arrow group (filter1)
    a = svg.index('<ellipse cx="12.5" cy="13" rx="12.5" ry="13" fill="url(#paint4_radial_60_471)"/>')
    b = svg.index('<g filter="url(#filter1_d_60_471)">')
    return svg[:a] + '<g class="bodyf">' + svg[a:b] + '</g>' + svg[b:]

clean = wrap_body(clean)

def with_viewbox(svg, vb, w, h):
    svg = re.sub(r'<svg width="55" height="26" viewBox="0 0 55 26"', f'<svg width="{w}" height="{h}" viewBox="{vb}"', svg, count=1)
    return svg

BACK = with_viewbox(clean, "0 0 25 26", 25, 26)      # back orb occupies x 0..25
FWD  = with_viewbox(clean, "30 0 25 26", 25, 26)     # forward orb occupies x 30..55

def disabled_svg(direction):
    arrow = ("M19 13.1029H8.5M12.2751 8L7 13.1029L12.0533 18" if direction == "L"
             else "M6 13.1029H16.5M12.7249 8L18 13.1029L12.9467 18")
    # Silver-blue translucent glass (sampled from the real Win7 disabled orb): readable body, dark rim, light arrow
    return f'''<svg width="25" height="26" viewBox="0 0 25 26" fill="none" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="dbody" x1="12.5" y1="0" x2="12.5" y2="26" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#D3DDEA" stop-opacity="0.40"/><stop offset="0.5" stop-color="#A9BFD3" stop-opacity="0.30"/><stop offset="1" stop-color="#86A0BB" stop-opacity="0.34"/>
</linearGradient>
<linearGradient id="drim" x1="12.5" y1="0" x2="12.5" y2="26" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#586A82" stop-opacity="0.75"/><stop offset="0.55" stop-color="#4A5C74" stop-opacity="0.78"/><stop offset="1" stop-color="#5E7088" stop-opacity="0.75"/>
</linearGradient>
<linearGradient id="dgloss" x1="12.5" y1="1" x2="12.5" y2="13" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#FFFFFF" stop-opacity="0.50"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0.06"/>
</linearGradient>
<filter id="dsh" x="3" y="4" width="20" height="18" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
<feGaussianBlur stdDeviation="0.9"/>
</filter>
</defs>
<ellipse cx="12.5" cy="13" rx="12.5" ry="13" fill="url(#dbody)"/>
<path d="M1.6 12.7C5 13.5 2.7 11.5 12.5 11.5C22.3 11.5 20 13.5 23.4 12.7C23.4 6.5 18.6 1.6 12.5 1.6C6.4 1.6 1.6 6.5 1.6 12.7Z" fill="url(#dgloss)"/>
<path d="{arrow}" stroke="#4F6379" stroke-opacity="0.40" stroke-width="3.5" stroke-linecap="round" filter="url(#dsh)"/>
<path d="{arrow}" stroke="#E6EEF6" stroke-opacity="0.80" stroke-width="3.2" stroke-linecap="round"/>
</svg>'''

FRAME = '''<svg width="61" height="30" viewBox="0 0 61 30" fill="none" xmlns="http://www.w3.org/2000/svg">
<defs>
<linearGradient id="fbody" x1="30.5" y1="0" x2="30.5" y2="30" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#FFFFFF" stop-opacity="0.16"/>
<stop offset="0.55" stop-color="#EAF2FB" stop-opacity="0.07"/>
<stop offset="1" stop-color="#FFFFFF" stop-opacity="0.14"/>
</linearGradient>
<linearGradient id="fedge" x1="30.5" y1="0" x2="30.5" y2="30" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#0A2548" stop-opacity="0.62"/>
<stop offset="0.5" stop-color="#1B3F6E" stop-opacity="0.45"/>
<stop offset="1" stop-color="#FFFFFF" stop-opacity="0.85"/>
</linearGradient>
<clipPath id="fclip"><path id="shape" d="M15.5 0.5C21 0.5 25 3.4 30.5 3.4C36 3.4 40 0.5 45.5 0.5C53.5 0.5 60.5 6.5 60.5 15C60.5 23.5 53.5 29.5 45.5 29.5C40 29.5 36 26.6 30.5 26.6C25 26.6 21 29.5 15.5 29.5C7.5 29.5 0.5 23.5 0.5 15C0.5 6.5 7.5 0.5 15.5 0.5Z"/></clipPath>
<filter id="finner" x="-5" y="-5" width="71" height="40" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
<feGaussianBlur stdDeviation="1.3"/>
</filter>
</defs>
<use href="#shape" fill="url(#fbody)"/>
<g clip-path="url(#fclip)">
<use href="#shape" fill="none" stroke="#0B2A52" stroke-opacity="0.55" stroke-width="3.2" filter="url(#finner)" transform="translate(0 1.1)"/>
</g>
<use href="#shape" stroke="url(#fedge)" stroke-width="1"/>
<path d="M16 2C21 2 25 4.8 30.5 4.8C36 4.8 40 2 45 2" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="0.8" stroke-linecap="round"/>
</svg>'''

SCALE = 4
CW, CH = 25*SCALE, 26*SCALE      # 100 x 104
FW, FH = 61*SCALE, 30*SCALE      # 244 x 120
FILTERS = {
    "default": "none",
    "hover":   "brightness(1.16) saturate(1.28)",
    "pressed": "brightness(0.70) saturate(0.92) contrast(1.12)",
}

async def render(page, svg, w, h, css_filter="none"):
    html = f"<html><body style='margin:0;background:transparent'><style>.bodyf{{filter:{css_filter}}}</style><div style='width:{w*SCALE}px;height:{h*SCALE}px'>{svg.replace('width=\"%d\"'%w,'width=\"%d\"'%(w*SCALE)).replace('height=\"%d\"'%h,'height=\"%d\"'%(h*SCALE),1)}</div></body></html>"
    await page.set_viewport_size({"width": w*SCALE, "height": h*SCALE})
    await page.set_content(html)
    png = await page.screenshot(omit_background=True, clip={"x":0,"y":0,"width":w*SCALE,"height":h*SCALE})
    return Image.open(io.BytesIO(png)).convert("RGBA")

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch()
        pg = await b.new_page()
        sheet = Image.new("RGBA", (4*CW, 2*CH + FH), (0,0,0,0))
        cells = {}
        for row, (name, svg_def, dis_dir) in enumerate([("back", BACK, "L"), ("forward", FWD, "R")]):
            for col, st in enumerate(["default", "hover", "pressed", "disabled"]):
                if st == "disabled":
                    im = await render(pg, disabled_svg(dis_dir), 25, 26)
                else:
                    im = await render(pg, svg_def, 25, 26, FILTERS[st])
                sheet.alpha_composite(im, (col*CW, row*CH))
                cells[(name, st)] = (col*CW, row*CH, CW, CH)
        fr = await render(pg, FRAME, 61, 30)
        sheet.alpha_composite(fr, (0, 2*CH))
        await b.close()
    sheet.save(os.path.join(ROOT, "assets", "nav", "navsheet.png"), optimize=True)
    print("sheet", sheet.size)
asyncio.run(main())
