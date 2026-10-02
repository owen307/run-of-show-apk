#!/usr/bin/env python3
"""Materialize fonts and launcher art for a GitHub Actions checkout.

A full local tree already has these files. Actions only has the source JPEG,
split into tool/icon_parts, because the binary files cannot be committed
through the text file API. Fonts come from their public repositories.
"""

import base64
import hashlib
import io
import pathlib
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
NAVY = (4, 24, 57, 255)
SOURCE_SHA256 = "fc2babbeae9400b1719cca8e6d59b9d887e643a98d7983ab0c921127e9b23cc3"

FONTS = {
    "assets/fonts/Barlow-Regular.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/barlow/Barlow-Regular.ttf",
    "assets/fonts/Barlow-Medium.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/barlow/Barlow-Medium.ttf",
    "assets/fonts/Barlow-SemiBold.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/barlow/Barlow-SemiBold.ttf",
    "assets/fonts/Barlow-Bold.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/barlow/Barlow-Bold.ttf",
    "assets/fonts/BarlowCondensed-Medium.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/BarlowCondensed-Medium.ttf",
    "assets/fonts/BarlowCondensed-SemiBold.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/BarlowCondensed-SemiBold.ttf",
    "assets/fonts/BarlowCondensed-Bold.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/barlowcondensed/BarlowCondensed-Bold.ttf",
    "assets/fonts/JetBrainsMono-Medium.ttf": "https://raw.githubusercontent.com/JetBrains/JetBrainsMono/v2.304/fonts/ttf/JetBrainsMono-Medium.ttf",
    "assets/fonts/JetBrainsMono-Bold.ttf": "https://raw.githubusercontent.com/JetBrains/JetBrainsMono/v2.304/fonts/ttf/JetBrainsMono-Bold.ttf",
}

LEGACY = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
FOREGROUND = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}


def download(url, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"font {dest.relative_to(ROOT)}")
    urllib.request.urlretrieve(url, dest)


def load_source_jpeg():
    parts_dir = ROOT / "tool" / "icon_parts"
    plan_path = parts_dir / "PLAN.txt"
    if plan_path.is_file():
        pieces = []
        for line in plan_path.read_text(encoding="ascii").splitlines():
            if not line.strip():
                continue
            kind, rest = line.split(" ", 1)
            if kind == "fill":
                char, count = rest.split(" ", 1)
                pieces.append(char * int(count))
            elif kind == "file":
                pieces.append((parts_dir / rest).read_text(encoding="ascii"))
            else:
                raise SystemExit(f"bad icon plan line: {line}")
        encoded = "".join(pieces)
    else:
        parts = sorted(parts_dir.glob("part-*"))
        if not parts:
            return None
        encoded = "".join(path.read_text(encoding="ascii") for path in parts)
    if not encoded:
        return None
    raw = base64.b64decode(encoded, validate=True)
    digest = hashlib.sha256(raw).hexdigest()
    if digest != SOURCE_SHA256:
        raise SystemExit(f"source image sha256 {digest} does not match the locked artwork")
    return raw


def is_matte(r, g, b):
    if b > 150 and g > 140 and r < 140:
        return False
    return r >= 186 and g >= 186 and b >= 186


def knock_out(image):
    width, height = image.size
    pixels = image.load()
    seen = bytearray(width * height)
    stack = []
    for x in range(width):
        stack.append((x, 0))
        stack.append((x, height - 1))
    for y in range(height):
        stack.append((0, y))
        stack.append((width - 1, y))
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= width or y >= height:
            continue
        index = y * width + x
        if seen[index]:
            continue
        seen[index] = 1
        r, g, b, _alpha = pixels[x, y]
        if not is_matte(r, g, b):
            continue
        pixels[x, y] = (r, g, b, 0)
        stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return image


def master_from_jpeg(raw):
    from PIL import Image

    image = Image.open(io.BytesIO(raw)).convert("RGBA")
    image = image.crop((320, 52, 960, 656))
    image = knock_out(image)
    bbox = image.getbbox()
    if bbox is None:
        raise SystemExit("locked artwork has no opaque pixels")
    art = image.crop(bbox)
    side = max(art.size)
    margin = int(round(side * 0.045))
    canvas_side = side + margin * 2
    canvas = Image.new("RGBA", (canvas_side, canvas_side), (0, 0, 0, 0))
    canvas.paste(art, ((canvas_side - art.width) // 2, (canvas_side - art.height) // 2), art)
    return canvas


def fit(master, size, scale, background):
    from PIL import Image

    canvas = Image.new("RGBA", (size, size), background)
    target = max(1, int(round(size * scale)))
    glyph = master.resize((target, target), Image.Resampling.LANCZOS)
    offset = (size - target) // 2
    canvas.paste(glyph, (offset, offset), glyph)
    return canvas


def write_icons(master):
    brand = fit(master, 1024, 0.94, (0, 0, 0, 0))
    brand_path = ROOT / "assets" / "brand" / "icon.png"
    brand_path.parent.mkdir(parents=True, exist_ok=True)
    brand.save(brand_path)
    docs = fit(master, 512, 0.94, (0, 0, 0, 0))
    docs_path = ROOT / "docs" / "icon.png"
    docs_path.parent.mkdir(parents=True, exist_ok=True)
    docs.save(docs_path)
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in LEGACY.items():
        path = res / folder / "ic_launcher.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        fit(master, size, 0.94, NAVY).convert("RGB").save(path)
    for folder, size in FOREGROUND.items():
        path = res / folder / "ic_launcher_foreground.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        fit(master, size, 0.78, (0, 0, 0, 0)).save(path)
    print("icons written")


def fonts_ready():
    return all((ROOT / rel).is_file() and (ROOT / rel).stat().st_size > 1000 for rel in FONTS)


def icons_ready():
    needed = [ROOT / "assets" / "brand" / "icon.png"]
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    needed.extend(res / folder / "ic_launcher.png" for folder in LEGACY)
    needed.extend(res / folder / "ic_launcher_foreground.png" for folder in FOREGROUND)
    return all(path.is_file() and path.stat().st_size > 100 for path in needed)


def main():
    jpeg = load_source_jpeg()
    if jpeg is not None:
        write_icons(master_from_jpeg(jpeg))
    elif not icons_ready():
        raise SystemExit("launcher art is missing and tool/icon_parts was not checked out")
    else:
        print("icons already in the tree")

    if not fonts_ready():
        for rel, url in FONTS.items():
            download(url, ROOT / rel)
    else:
        print("fonts already in the tree")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(error, file=sys.stderr)
        raise
