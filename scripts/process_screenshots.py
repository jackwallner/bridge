#!/usr/bin/env python3
import os
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "fastlane" / "screenshots" / "en-US"

# Ensure output directory is clean
if OUT_DIR.exists():
    for f in OUT_DIR.glob("*.png"):
        f.unlink()
else:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

# List of input paths (in numerical order)
INPUTS = [
    "/Users/jackwallner/Downloads/ChatGPT Image Jul 14, 2026, 10_40_54 PM (1).png",
    "/Users/jackwallner/Downloads/ChatGPT Image Jul 14, 2026, 10_40_56 PM (2).png",
    "/Users/jackwallner/Downloads/ChatGPT Image Jul 14, 2026, 10_41_00 PM (3).png",
    "/Users/jackwallner/Downloads/ChatGPT Image Jul 14, 2026, 10_41_03 PM (4).png",
]

TARGET_SIZE = (1320, 2868)

for i, src_str in enumerate(INPUTS, 1):
    src = Path(src_str)
    if not src.exists():
        print(f"Error: {src} not found!")
        continue
    
    img = Image.open(src)
    # Upscale to target 6.9" / 6.7" size (1320x2868) using high-quality LANCZOS interpolation
    resized = img.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
    
    out_name = f"0{i}_screenshot.png"
    dest = OUT_DIR / out_name
    resized.save(dest, "PNG")
    print(f"Resized and saved {src.name} -> {dest.name}")

print("All screenshots processed successfully!")
