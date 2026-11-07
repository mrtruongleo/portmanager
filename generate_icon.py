import os
import subprocess
from PIL import Image, ImageDraw

def generate():
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    corner_radius = 220
    rect = [40, 40, size - 40, size - 40]
    
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(rect, radius=corner_radius, fill=255)
    
    grad = Image.new('RGBA', (size, size))
    gdraw = ImageDraw.Draw(grad)
    for y in range(size):
        t = y / size
        r = int(15 + 15 * t)
        g = int(20 + 80 * t)
        b = int(45 + 160 * t)
        gdraw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    img.paste(grad, (0, 0), mask)
    
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle(rect, radius=corner_radius, outline=(255, 255, 255, 60), width=6)
    
    center_x, center_y = size // 2, size // 2 - 20
    
    shield_box = [center_x - 220, center_y - 140, center_x + 220, center_y + 160]
    draw.rounded_rectangle(shield_box, radius=40, fill=(30, 41, 59, 255), outline=(96, 165, 250, 200), width=10)
    
    inner_box = [center_x - 170, center_y - 90, center_x + 170, center_y + 110]
    draw.rounded_rectangle(inner_box, radius=20, fill=(15, 23, 42, 255), outline=(56, 189, 248, 180), width=6)
    
    pin_y_start = center_y - 80
    pin_y_end = center_y - 20
    spacing = 38
    start_x = center_x - int(3.5 * spacing)
    for i in range(8):
        px = start_x + i * spacing
        draw.rounded_rectangle([px - 6, pin_y_start, px + 6, pin_y_end], radius=3, fill=(250, 204, 21, 255))
    
    draw.ellipse([center_x - 140, center_y + 50, center_x - 100, center_y + 90], fill=(34, 197, 94, 255), outline=(255, 255, 255, 120), width=3)
    draw.ellipse([center_x + 100, center_y + 50, center_x + 140, center_y + 90], fill=(239, 68, 68, 255), outline=(255, 255, 255, 120), width=3)
    
    draw.rounded_rectangle([center_x - 140, center_y + 240, center_x + 140, center_y + 310], radius=35, fill=(59, 130, 246, 230))
    
    iconset_dir = "AppIcon.iconset"
    os.makedirs(iconset_dir, exist_ok=True)
    sizes = [16, 32, 64, 128, 256, 512]
    for s in sizes:
        r1 = img.resize((s, s), Image.Resampling.LANCZOS)
        r1.save(f"{iconset_dir}/icon_{s}x{s}.png")
        r2 = img.resize((s * 2, s * 2), Image.Resampling.LANCZOS)
        r2.save(f"{iconset_dir}/icon_{s}x{s}@2x.png")
    
    out_icns = "PortManager.app/Contents/Resources/AppIcon.icns"
    os.makedirs(os.path.dirname(out_icns), exist_ok=True)
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", out_icns], check=True)
    import shutil
    shutil.rmtree(iconset_dir)
    print("Icon generated:", out_icns)

if __name__ == "__main__":
    generate()

