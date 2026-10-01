"""Fetch the owner's current logo and prepare transparent app assets.
No substitute/old logo is silently used if the download fails.
"""
from pathlib import Path
from urllib.request import Request, urlopen
from PIL import Image
from io import BytesIO
url='https://nounupdate.com/images/logo.webp'
with urlopen(Request(url,headers={'User-Agent':'NOUNUpdate-App-Build/1.0'}),timeout=30) as response:
    data=response.read(5_000_001)
if len(data)>5_000_000: raise RuntimeError('Logo exceeds 5 MB')
logo=Image.open(BytesIO(data)).convert('RGBA')
if min(logo.size)<32: raise RuntimeError('Logo is too small')
box=logo.getbbox()
if box is None: raise RuntimeError('Logo is empty')
logo=logo.crop(box)
folder=Path('assets/images');folder.mkdir(parents=True,exist_ok=True)
(folder/'logo.webp').write_bytes(data)
logo.save(folder/'noun_update_logo.png')
# Adaptive icons need a safe inner region so launchers do not clip the emblem.
canvas=Image.new('RGBA',(1024,1024));logo.thumbnail((600,600),Image.Resampling.LANCZOS)
canvas.alpha_composite(logo,((1024-logo.width)//2,(1024-logo.height)//2))
canvas.save(folder/'launcher_foreground.png')
print('Prepared app branding from /images/logo.webp')
