#!/usr/bin/env python3
import sys

path = "scripts/generate_metadata_all.py"
content = open(path).read()

# 1. Fix Japanese description
content = content.replace("Bridge Trainerคือは", "Bridge Trainerは")

# 2. Fix Gujarati keywords: replace U+0A2D with U+0AAD only in the Gujarati keywords line
gu_start = content.find('"gu-IN": {')
gu_end = content.find('"kn-IN": {')
if gu_start == -1 or gu_end == -1:
    print("WARNING: gu-IN block not found")
else:
    gu_block = content[gu_start:gu_end]
    gu_block_fixed = gu_block.replace(chr(0x0a2d), chr(0x0aad))
    gu_block_fixed = gu_block_fixed.replace(
        '"keywords": "બ્રિજ,બિડિંગ,પત્તા,શીખો,ટ્યુટર,શરૂઆતી,પાઠ,ડྲિલ,ડિફેન્સ,ડિક્લેરર,અભ્યાસ,રમત,પોઇન્ટ,સ્કોર,મજા",',
        '"keywords": "બ્રિજ,બિડિંગ,પત્તા,શીખો,ટ્યુટર,શરૂઆતી,પાઠ,ડྲિલ,ડિફેન્સ,ડિક્લેરર,અભ્યાસ,રમત,પોઇન્ટ,સ્કોર,મજા,ખેલ",',
    )
    # also handle if it has already been partially updated:
    gu_block_fixed = gu_block_fixed.replace(
        '"keywords": "બ્રિજ,બિડિંગ,પત્તા,શીખો,ટ્યુટર,શરૂઆતી,પાઠ,ડྲિલ,ડિફેન્સ,ડિક્લેરર,અભ્યાસ,રમત,પોઇન્ટ,સ્કોર,મજા,ખેલ",'.replace(chr(0x0a2d), chr(0x0aad)),
        '"keywords": "બ્રિજ,બિડિંગ,પત્તા,શીખો,ટ્યુટર,શરૂઆતી,પાઠ,ડྲિલ,ડિફેન્સ,ડિક્લેરર,અભ્યાસ,રમત,પોઇન્ટ,સ્કોર,મજા,ખેલ",'.replace(chr(0x0a2d), chr(0x0aad))
    )
    content = content[:gu_start] + gu_block_fixed + content[gu_end:]

# 3. Fix Tamil keywords: replace Telugu U+0C38 U+0C3F with Tamil U+0B9A U+0BBF
ta_start = content.find('"ta-IN": {')
ta_end = content.find('"te-IN": {')
if ta_start == -1 or ta_end == -1:
    print("WARNING: ta-IN block not found")
else:
    ta_block = content[ta_start:ta_end]
    ta_block_fixed = ta_block.replace(chr(0x0c38) + chr(0x0c3f), chr(0x0b9a) + chr(0x0bbf))
    content = content[:ta_start] + ta_block_fixed + content[ta_end:]

# 4. Fix Bengali name
content = content.replace('"name": "Bridge Trainer: ब्रिज सीखुन",', '"name": "Bridge Trainer: ব্রিজ শিখুন",')

# 5. Fix Oriya keywords: replace Gujarati U+0AB0 with Oriya U+0B30
or_start = content.find('"or-IN": {')
or_end = content.find('"pa-IN": {')
if or_start == -1 or or_end == -1:
    print("WARNING: or-IN block not found")
else:
    or_block = content[or_start:or_end]
    or_block_fixed = or_block.replace(chr(0x0ab0), chr(0x0b30))
    content = content[:or_start] + or_block_fixed + content[or_end:]

open(path, "w").write(content)
print("Finished patching generate_metadata_all.py successfully!")
