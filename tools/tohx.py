# Merges iron into single .hx file
from os.path import dirname, basename, isfile
import glob

modules = glob.glob('../Sources/**/*.hx', recursive=True)
files = []
for f in modules:
    if isfile(f):
        files.append(f)

lines = []

for file in files:
    with open(file) as f:
        lines += f.read().splitlines()

out = ''
imports = ''
for l in lines:
    if l.startswith('import iron.'):
        continue
    if l.startswith('import '):
        if l not in imports:
            imports += l + '\n'
        continue
    if l.startswith('package '):
        continue
    if l == '@:allow(iron.object.Animation)':
        l = '@:allow(Animation)'
    if l == '@:allow(iron.object.Object)':
        l = '@:allow(Object)'
    l = l.replace('iron.math.', '')
    l = l.replace('iron.data.', '')
    l = l.replace('iron.system.', '')
    l = l.replace('iron.object.', '')
    l = l.replace('iron.', '')
    out += l + '\n'

with open('Iron.hx', 'w') as f:
    f.write('package;\n' + imports + 'class Iron {}\n' + out)
