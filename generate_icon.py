import os
import subprocess
from PIL import Image, ImageDraw

def generate():
    # 1. Generate 1024x1024 AppIcon
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
    
    out_resources = "PortManager.app/Contents/Resources"
    os.makedirs(out_resources, exist_ok=True)
    out_icns = os.path.join(out_resources, "AppIcon.icns")
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", out_icns], check=True)
    import shutil
    shutil.rmtree(iconset_dir)
    print("Icon generated:", out_icns)

    # 2. Generate Dedicated Status Bar Icons (44x44 @2x and 22x22 @1x)
    stat_size = 44
    stat_img = Image.new('RGBA', (stat_size, stat_size), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(stat_img)
    
    # Outer squircle with neon cyan border
    r = 9
    sdraw.rounded_rectangle([2, 2, stat_size - 3, stat_size - 3], radius=r, fill=(20, 30, 48, 255), outline=(56, 189, 248, 240), width=2)
    
    # Inner RJ45 socket cutout
    sdraw.rounded_rectangle([8, 11, stat_size - 9, 31], radius=3, fill=(10, 16, 28, 255), outline=(96, 165, 250, 160), width=1)
    
    # Bottom key notch
    sdraw.rectangle([14, 26, stat_size - 15, 33], fill=(10, 16, 28, 255))
    
    # 6 Gold contact pins
    pins = 6
    start_x = 12
    step = 3.6
    for i in range(pins):
        px = int(start_x + i * step)
        sdraw.line([(px, 13), (px, 19)], fill=(250, 204, 21, 255), width=2)
        
    # Active indicator LEDs
    sdraw.ellipse([5, 5, 9, 9], fill=(34, 197, 94, 255))
    sdraw.ellipse([stat_size - 10, 5, stat_size - 6, 9], fill=(249, 115, 22, 255))
    
    stat_img.save(os.path.join(out_resources, "StatusIcon@2x.png"))
    stat_img_1x = stat_img.resize((22, 22), Image.Resampling.LANCZOS)
    stat_img_1x.save(os.path.join(out_resources, "StatusIcon.png"))
    
    # Also save template version
    tmpl = Image.new('RGBA', (stat_size, stat_size), (0, 0, 0, 0))
    tdraw = ImageDraw.Draw(tmpl)
    tdraw.rounded_rectangle([4, 6, stat_size - 5, stat_size - 8], radius=6, outline=(255, 255, 255, 255), width=3)
    tdraw.rectangle([14, stat_size - 10, stat_size - 15, stat_size - 5], fill=(0, 0, 0, 0))
    tdraw.line([(14, stat_size - 8), (14, stat_size - 5)], fill=(255, 255, 255, 255), width=3)
    tdraw.line([(stat_size - 15, stat_size - 8), (stat_size - 15, stat_size - 5)], fill=(255, 255, 255, 255), width=3)
    tdraw.line([(14, stat_size - 5), (stat_size - 15, stat_size - 5)], fill=(255, 255, 255, 255), width=3)
    for i in range(5):
        px = int(12 + i * 4.8)
        tdraw.line([(px, 11), (px, 20)], fill=(255, 255, 255, 255), width=2)
    tdraw.ellipse([7, 24, 11, 28], fill=(255, 255, 255, 255))
    tdraw.ellipse([stat_size - 12, 24, stat_size - 8, 28], fill=(255, 255, 255, 255))
    
    tmpl.save(os.path.join(out_resources, "StatusIconTemplate@2x.png"))
    tmpl_1x = tmpl.resize((22, 22), Image.Resampling.LANCZOS)
    tmpl_1x.save(os.path.join(out_resources, "StatusIconTemplate.png"))
    
    print("Status icons generated in:", out_resources)

if __name__ == "__main__":
    generate()
