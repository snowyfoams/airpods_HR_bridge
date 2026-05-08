#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset" / "Icon-1024.png"
SIZE = 1024


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def radial_background() -> Image.Image:
    center = (SIZE * 0.52, SIZE * 0.40)
    inner = (19, 27, 40)
    outer = (4, 7, 13)
    accent = (13, 86, 110)
    image = Image.new("RGB", (SIZE, SIZE))
    pixels = image.load()

    max_distance = math.hypot(SIZE, SIZE)
    for y in range(SIZE):
        for x in range(SIZE):
            dx = x - center[0]
            dy = y - center[1]
            t = min(1.0, math.hypot(dx, dy) / (max_distance * 0.62))
            base = tuple(lerp(inner[i], outer[i], t) for i in range(3))

            sweep = max(0.0, 1.0 - abs((x + y * 0.62) - SIZE * 0.92) / (SIZE * 0.72))
            sweep *= 0.34
            pixels[x, y] = tuple(lerp(base[i], accent[i], sweep) for i in range(3))

    return image


def heart_points(center: tuple[float, float], scale: float) -> list[tuple[int, int]]:
    points: list[tuple[int, int]] = []
    for index in range(720):
        t = 2 * math.pi * index / 720
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        points.append((round(center[0] + x * scale), round(center[1] + y * scale)))
    return points


def draw_heart(base: Image.Image) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.polygon(heart_points((SIZE * 0.50, SIZE * 0.54), SIZE * 0.0255), fill=(0, 0, 0, 190))
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    base.alpha_composite(shadow)

    heart = Image.new("RGBA", base.size, (0, 0, 0, 0))
    heart_draw = ImageDraw.Draw(heart)
    heart_draw.polygon(heart_points((SIZE * 0.50, SIZE * 0.50), SIZE * 0.0255), fill=(255, 63, 84, 255))

    highlight = Image.new("RGBA", base.size, (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.polygon(heart_points((SIZE * 0.48, SIZE * 0.47), SIZE * 0.019), fill=(255, 119, 139, 110))
    highlight = highlight.filter(ImageFilter.GaussianBlur(22))
    heart.alpha_composite(highlight)

    base.alpha_composite(heart)


def draw_bridge_marks(base: Image.Image) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    blue = (66, 190, 255, 255)
    cyan = (117, 236, 255, 230)
    white = (235, 250, 255, 245)

    # Bluetooth-inspired bridge glyph inside the heart.
    cx = SIZE * 0.50
    top = SIZE * 0.330
    bottom = SIZE * 0.668
    mid = SIZE * 0.500
    left = SIZE * 0.405
    right = SIZE * 0.600
    width = 42

    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    for line in [
        ((cx, top), (cx, bottom)),
        ((cx, top), (right, mid)),
        ((right, mid), (cx, bottom)),
        ((cx, mid), (left, SIZE * 0.405)),
        ((left, SIZE * 0.405), (cx, top)),
        ((cx, mid), (left, SIZE * 0.595)),
        ((left, SIZE * 0.595), (cx, bottom)),
    ]:
        glow_draw.line(line, fill=(53, 198, 255, 170), width=width + 34, joint="curve")
    glow = glow.filter(ImageFilter.GaussianBlur(16))
    layer.alpha_composite(glow)

    for line in [
        ((cx, top), (cx, bottom)),
        ((cx, top), (right, mid)),
        ((right, mid), (cx, bottom)),
        ((cx, mid), (left, SIZE * 0.405)),
        ((left, SIZE * 0.405), (cx, top)),
        ((cx, mid), (left, SIZE * 0.595)),
        ((left, SIZE * 0.595), (cx, bottom)),
    ]:
        draw.line(line, fill=blue, width=width, joint="curve")

    # Wireless bridge arcs around the heart.
    for inset, alpha, stroke in [(210, 140, 24), (152, 96, 20)]:
        box = (inset, inset + 22, SIZE - inset, SIZE - inset + 22)
        draw.arc(box, start=206, end=334, fill=(93, 217, 255, alpha), width=stroke)

    draw.ellipse((SIZE * 0.205, SIZE * 0.475, SIZE * 0.270, SIZE * 0.540), fill=cyan)
    draw.ellipse((SIZE * 0.730, SIZE * 0.475, SIZE * 0.795, SIZE * 0.540), fill=cyan)
    draw.ellipse((SIZE * 0.466, SIZE * 0.466, SIZE * 0.534, SIZE * 0.534), fill=white)

    base.alpha_composite(layer)


def main() -> None:
    icon = radial_background().convert("RGBA")
    draw_heart(icon)
    draw_bridge_marks(icon)

    # A subtle inner vignette keeps the icon readable under iOS masking.
    vignette = Image.new("RGBA", icon.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(vignette)
    draw.rounded_rectangle((22, 22, SIZE - 22, SIZE - 22), radius=206, outline=(255, 255, 255, 20), width=6)
    icon.alpha_composite(vignette)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    icon.convert("RGB").save(OUTPUT, "PNG", optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
