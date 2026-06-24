# Lockspire logo generator — reproduces the outlined SVG logo set.
#
# Requirements (NOT committed; fetch at generation time):
#   - Familjen Grotesk variable TTF (OFL-1.1) from Google Fonts
#   - python deps: uharfbuzz, fonttools   (pip install in a venv)
#   - optional: svgo (npx) to optimize the output
#
# Usage:
#   curl -sL -o FamiljenGrotesk.ttf \
#     "https://raw.githubusercontent.com/google/fonts/main/ofl/familjengrotesk/FamiljenGrotesk%5Bwght%5D.ttf"
#   python generate-logos.py            # writes ../logo/*.svg
#   npx svgo --multipass -f .           # optimize
#
# The wordmark/tagline are outlined to paths (font-independent). The tower mark and
# diamond tittle are hand-authored geometry. See ../notes/research.md.

import uharfbuzz as hb, os
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen

SRC="FamiljenGrotesk.ttf"; WGHT=600; TEXT="Lockspıre"; TRACK=-0.012
OUT="/Users/jon/projects/lockspire/brandbook/logo"
INK="#0b1220"; FROST="#f8fafc"

ft=TTFont(SRC); instantiateVariableFont(ft,{"wght":WGHT},inplace=True)
upem=ft["head"].unitsPerEm; gset=ft.getGlyphSet()
xH=ft["OS/2"].sxHeight; capH=ft["OS/2"].sCapHeight
blob=hb.Blob.from_file_path(SRC); face=hb.Face(blob); fnt=hb.Font(face); fnt.set_variations({"wght":WGHT})
order=ft.getGlyphOrder()

def shape(text,track):
    b=hb.Buffer(); b.add_str(text); b.guess_segment_properties(); hb.shape(fnt,b,{"kern":True,"liga":True})
    gl=[]; x=0.0; tr=track*upem; info={}
    mnx=mny=1e9; mxx=mxy=-1e9
    for gi,gp in zip(b.glyph_infos,b.glyph_positions):
        gn=order[gi.codepoint]
        sp=SVGPathPen(gset); gset[gn].draw(sp); d=sp.getCommands()
        bp=BoundsPen(gset); gset[gn].draw(bp)
        xo=x+gp.x_offset
        if d: gl.append((d,xo))
        if bp.bounds:
            a,c,e,f=bp.bounds; mnx=min(mnx,a+xo);mxx=max(mxx,e+xo);mny=min(mny,f and c);mxy=max(mxy,f)
        info[gn]=(xo,gp.x_advance)
        x+=gp.x_advance+tr
    return gl,(mnx,mny,mxx,mxy),info,x-tr

def r(v): return round(v,1)
def rs(v): return round(v,4)

gl,(mnx,mny,mxx,mxy),info,adv=shape(TEXT,TRACK)
ipos,iadv=info["dotlessi"]; stem_cx=ipos+iadv/2
dsize=upem*0.150; gap=upem*0.055
dcx=stem_cx; db=xH+gap; dt=db+dsize; dm=db+dsize/2; hf=dsize/2
mxy=max(mxy,dt); mnx=min(mnx,dcx-hf); mxx=max(mxx,dcx+hf)
W=mxx-mnx; H=mxy-mny

def diamond(color):
    if color is None:
        return f'<path d="M{r(dcx)} {r(db)} L{r(dcx+hf)} {r(dm)} L{r(dcx)} {r(dt)} L{r(dcx-hf)} {r(dm)} Z"/>'
    return (f'<path d="M{r(dcx)} {r(db)} L{r(dcx+hf)} {r(dm)} L{r(dcx)} {r(dt)} L{r(dcx-hf)} {r(dm)} Z" fill="#22d3ee"/>'
            f'<path d="M{r(dcx)} {r(db)} L{r(dcx-hf)} {r(dm)} L{r(dcx)} {r(dt)} Z" fill="#0e7490"/>')

def wm_group(letter, dx=0.0):
    # letter: hex or None(currentColor); dx extra x shift
    fill = letter if letter else "currentColor"
    g=(f'<g transform="translate({r(-mnx+dx)},{r(mxy)}) scale(1,-1)">'
       f'<g fill="{fill}">'+''.join(f'<path transform="translate({r(xo)},0)" d="{d}"/>' for d,xo in gl)+'</g>'
       + diamond(None if letter is None else "c") +'</g>')
    return g

TOWER_C='<path d="M4 82 L40 82 L36 74 L8 74 Z" fill="#0e7490"/><path d="M22 6 L30 26 L34 74 L22 74 Z" fill="#0e7490"/><path d="M22 6 L14 26 L10 74 L22 74 Z" fill="#22d3ee"/><path d="M22 10 L18 26 L19 74 L22 74 Z" fill="#67e8f9"/><path d="M22 6 L18 26 L22 26 Z" fill="#a5f3fc"/>'
TOWER_M='<g fill="currentColor"><path d="M4 82 L40 82 L36 74 L8 74 Z"/><path d="M22 6 L30 26 L34 74 L22 74 Z"/><path d="M22 6 L14 26 L10 74 L22 74 Z"/><path d="M22 10 L18 26 L19 74 L22 74 Z"/><path d="M22 6 L18 26 L22 26 Z"/></g>'

def svg(vb,inner): return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" role="img" aria-label="Lockspire">{inner}</svg>\n'
def w(name,inner,vb): open(f"{OUT}/{name}","w").write(svg(vb,inner))

VB=f"0 0 {r(W)} {r(H)}"
# wordmark: light(ink), inverse(frost), mono(currentColor)
w("lockspire-wordmark.svg", wm_group(INK), VB)
w("lockspire-wordmark-inverse.svg", wm_group(FROST), VB)
w("lockspire-wordmark-mono.svg", wm_group(None), VB)

# mark
MVB="2 4 40 80"
w("lockspire-mark.svg", TOWER_C, MVB)
w("lockspire-mark-mono.svg", TOWER_M, MVB)
w("lockspire-favicon.svg", TOWER_C, "-20 2 84 84")  # square viewBox centered on tower (cx22,cy44)

# horizontal lockup
tscale=(capH*1.20)/88.0; tw=44*tscale; baseline=mxy; ty=baseline-82*tscale
lgap=upem*0.16; wx=tw+lgap; LW=wx+W
def lock(letter, towerstr):
    return (f'<g transform="translate(0,{r(ty)}) scale({rs(tscale)})">{towerstr}</g>'+ wm_group(letter, dx=wx))
w("lockspire-horizontal.svg", lock(INK,TOWER_C), f"0 0 {r(LW)} {r(H)}")
w("lockspire-horizontal-inverse.svg", lock(FROST,TOWER_C), f"0 0 {r(LW)} {r(H)}")
w("lockspire-horizontal-mono.svg", lock(None,TOWER_M), f"0 0 {r(LW)} {r(H)}")

# tagline lockup (ink + inverse): wordmark + spaced caps below
tg,(tmnx,tmny,tmxx,tmxy),tinfo,tadv=shape("STRUCTURED TRUST FOR PHOENIX",0.16)
tagW=tmxx-tmnx
tagscale=(W*0.86)/tagW
tag_gap=upem*0.40
def tagline(letter):
    fill=letter if letter else "currentColor"
    body=wm_group(letter)
    tagx=(W-tagW*tagscale)/2
    tagy=mxy+tag_gap
    tg_inner=(f'<g transform="translate({r(tagx)},{r(tagy)}) scale({rs(tagscale)})">'
              f'<g transform="translate({r(-tmnx)},{r(tmxy)}) scale(1,-1)">'
              f'<g fill="{fill}" opacity="0.82">'+''.join(f'<path transform="translate({r(xo)},0)" d="{d}"/>' for d,xo in tg)+'</g></g></g>')
    return body+tg_inner, mxy+tag_gap+tmxy*tagscale-mny
inner,TH=tagline(INK); w("lockspire-tagline.svg", inner, f"0 0 {r(W)} {r(TH)}")
inner,TH=tagline(FROST); w("lockspire-tagline-inverse.svg", inner, f"0 0 {r(W)} {r(TH)}")

print("wordmark W x H:", r(W), r(H), "| tagline fit scale:", round(tagscale,3), "| tagW*scale:", r(tagW*tagscale), "<= W", r(W))
for f in sorted(os.listdir(OUT)):
    if f.endswith('.svg'): print(" ",f, os.path.getsize(f"{OUT}/{f}"),"B")

# adaptive variants: letters currentColor + cyan diamond + color tower (for inline/HEEx use)
w("lockspire-wordmark-adaptive.svg", wm_group(None).replace(diamond(None), diamond("c")), VB)
def lock_adaptive():
    return (f'<g transform="translate(0,{r(ty)}) scale({rs(tscale)})">{TOWER_C}</g>'
            + wm_group(None, dx=wx).replace(diamond(None), diamond("c")))
w("lockspire-horizontal-adaptive.svg", lock_adaptive(), f"0 0 {r(LW)} {r(H)}")
print("adaptive variants written")
