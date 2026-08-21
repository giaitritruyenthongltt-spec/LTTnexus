"""Generate the full LTT Nexus icon set from brand/ltt-logo.png into the fork.
Transparent where supported (Windows .ico, Android legacy+adaptive, macOS .icns);
flattened onto white for iOS (Apple requires opaque icons)."""
from PIL import Image
import os

SRC = r"D:\LTTnexus\brand\ltt-logo.png"
ROOT = r"D:\LTTnexus\flutter"
src = Image.open(SRC).convert("RGBA")
print("source:", src.size, src.mode)

def rz(size):
    return src.resize((size, size), Image.LANCZOS)

done = []

# ---- Windows .ico (multi-size) ----
ico = os.path.join(ROOT, "windows", "runner", "resources", "app_icon.ico")
rz(256).save(ico, format="ICO", sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])
done.append("windows app_icon.ico")

# ---- Android legacy launcher + round (transparent corners OK) ----
DENS = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for d, sz in DENS.items():
    base = os.path.join(ROOT, "android", "app", "src", "main", "res", f"mipmap-{d}")
    if not os.path.isdir(base):
        continue
    img = rz(sz)
    img.save(os.path.join(base, "ic_launcher.png"))
    img.save(os.path.join(base, "ic_launcher_round.png"))
done.append(f"android legacy+round x{len(DENS)}")

# ---- Android adaptive foreground: logo ~72% centered on transparent canvas ----
FG = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
for d, canvas in FG.items():
    base = os.path.join(ROOT, "android", "app", "src", "main", "res", f"mipmap-{d}")
    if not os.path.isdir(base):
        continue
    layer = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    ls = int(canvas * 0.72)
    lg = src.resize((ls, ls), Image.LANCZOS)
    off = (canvas - ls) // 2
    layer.paste(lg, (off, off), lg)
    layer.save(os.path.join(base, "ic_launcher_foreground.png"))
done.append(f"android adaptive foreground x{len(FG)}")

# ---- iOS (opaque, flatten onto white) ----
IOS = {
    "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40, "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29, "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80, "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120, "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76, "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167, "Icon-App-1024x1024@1x.png": 1024,
}
ios_dir = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
n = 0
for fn, sz in IOS.items():
    bg = Image.new("RGBA", (sz, sz), (255, 255, 255, 255))
    lg = src.resize((sz, sz), Image.LANCZOS)
    bg.paste(lg, (0, 0), lg)
    bg.convert("RGB").save(os.path.join(ios_dir, fn))
    n += 1
done.append(f"ios appiconset x{n}")

# ---- macOS .icns (transparent) ----
icns = os.path.join(ROOT, "macos", "Runner", "AppIcon.icns")
try:
    rz(1024).save(icns, format="ICNS")
    done.append("macos AppIcon.icns")
except Exception as e:
    done.append(f"macos icns SKIPPED ({type(e).__name__}: {e})")

# ---- flutter in-app asset ----
rz(512).save(os.path.join(ROOT, "assets", "icon.png"))
done.append("flutter/assets/icon.png")

print("GENERATED:")
for x in done:
    print("  -", x)
