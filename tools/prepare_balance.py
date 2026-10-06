"""Articulate the supplied scales.glb, preserving its textures and geometry.

Usage: python tools/prepare_balance.py path/to/scales.glb
The original is Z-up, with disconnected base, beam, chains and pans.
Weld positions for component discovery only; retain all UV/normal seams.
"""
import collections
import json
import struct
import sys
from pathlib import Path

source = Path(sys.argv[1])
with source.open('rb') as stream:
    stream.read(12)
    size, _ = struct.unpack('<II', stream.read(8))
    gltf = json.loads(stream.read(size))
    size, _ = struct.unpack('<II', stream.read(8))
    binary = bytearray(stream.read(size))

output_dir = Path(__file__).resolve().parents[1] / 'assets/models/props/balance'
output_dir.mkdir(parents=True, exist_ok=True)
# Externalize images once: Godot otherwise extracts them while retaining a
# second full copy inside the GLB. Geometry and source texture pixels stay exact.
image_views = set()
for index, image in enumerate(gltf.get('images', [])):
    view_index = image.pop('bufferView')
    view = gltf['bufferViews'][view_index]
    start = view.get('byteOffset', 0)
    name = f'balance_{index}.png'
    (output_dir / name).write_bytes(binary[start:start + view['byteLength']])
    image['uri'] = name
    image_views.add(view_index)
geometry = bytearray()
views = []
view_remap = {}
for index, view in enumerate(gltf['bufferViews']):
    if index in image_views:
        continue
    while len(geometry) % 4:
        geometry.append(0)
    start = view.get('byteOffset', 0)
    copied = dict(view)
    copied['byteOffset'] = len(geometry)
    geometry.extend(binary[start:start + view['byteLength']])
    view_remap[index] = len(views)
    views.append(copied)
for accessor in gltf['accessors']:
    accessor['bufferView'] = view_remap[accessor['bufferView']]
gltf['bufferViews'] = views
binary = geometry


def read_accessor(index):
    accessor = gltf['accessors'][index]
    view = gltf['bufferViews'][accessor['bufferView']]
    code = {5126: 'f', 5125: 'I', 5123: 'H'}[accessor['componentType']]
    width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[accessor['type']]
    stride = view.get('byteStride', struct.calcsize(code) * width)
    start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
    return [struct.unpack_from('<' + code * width, binary, start + i * stride)
            for i in range(accessor['count'])]


def append_accessor(values, kind, component=5126):
    while len(binary) % 4:
        binary.append(0)
    start = len(binary)
    code = 'f' if component == 5126 else 'I'
    for value in values:
        binary.extend(struct.pack('<' + code * len(value), *value))
    view = len(gltf['bufferViews'])
    gltf['bufferViews'].append({'buffer': 0, 'byteOffset': start, 'byteLength': len(binary) - start})
    accessor = {'bufferView': view, 'componentType': component, 'count': len(values), 'type': kind}
    if kind == 'VEC3':
        accessor['min'] = [min(v[i] for v in values) for i in range(3)]
        accessor['max'] = [max(v[i] for v in values) for i in range(3)]
    gltf['accessors'].append(accessor)
    return len(gltf['accessors']) - 1


primitive = gltf['meshes'][0]['primitives'][0]
vertices = read_accessor(primitive['attributes']['POSITION'])
indices = [v[0] for v in read_accessor(primitive['indices'])]
parents = list(range(len(vertices)))


def root(index):
    while parents[index] != index:
        parents[index] = parents[parents[index]]
        index = parents[index]
    return index


def join(left, right):
    parents[root(left)] = root(right)


welded = {}
for index, vertex in enumerate(vertices):
    key = tuple(round(v, 3) for v in vertex)
    if key in welded:
        join(index, welded[key])
    else:
        welded[key] = index
for index in range(0, len(indices), 3):
    join(indices[index], indices[index + 1])
    join(indices[index], indices[index + 2])
components = collections.defaultdict(list)
for index, vertex in enumerate(vertices):
    components[root(index)].append(vertex)
parts = {}
for index, group in components.items():
    center_x = sum(v[0] for v in group) / len(group)
    min_x, max_x = min(v[0] for v in group), max(v[0] for v in group)
    min_height = min(v[2] for v in group)
    if min_x > 35:
        part = 'RightPan'
    elif max_x < -35:
        part = 'LeftPan'
    elif abs(center_x) > 10 and min_height > 77:
        part = 'Beam'
    else:
        part = 'Base'
    parts[index] = part

attributes = dict(primitive['attributes'])
for name in ['NORMAL', 'TANGENT']:
    if name in attributes:
        values = read_accessor(attributes[name])
        converted = [(v[0], v[2], -v[1], *v[3:]) for v in values]
        attributes[name] = append_accessor(converted, 'VEC4' if name == 'TANGENT' else 'VEC3')

gltf['nodes'] = [{'name': 'ArticulatedScales', 'children': [1, 2]}]
gltf['meshes'] = []
pivots = {'Base': (0, 0, 0), 'Beam': (0, 87, 0),
          'LeftPan': (-54.1, 79, 1.8), 'RightPan': (54.2, 79, 1.8)}
for name in pivots:
    pivot = pivots[name]
    adjusted = [(v[0] - pivot[0], v[2] - pivot[1], -v[1] - pivot[2]) for v in vertices]
    attrs = dict(attributes)
    attrs['POSITION'] = append_accessor(adjusted, 'VEC3')
    subset = [(indices[i + j],) for i in range(0, len(indices), 3)
              if parts[root(indices[i])] == name for j in range(3)]
    gltf['meshes'].append({'name': name, 'primitives': [{
        'attributes': attrs, 'indices': append_accessor(subset, 'SCALAR', 5125),
        'material': primitive.get('material', 0)}]})
    translation = list(pivot)
    if name.endswith('Pan'):
        translation = [pivot[i] - pivots['Beam'][i] for i in range(3)]
    node = {'name': name, 'mesh': len(gltf['meshes']) - 1, 'translation': translation}
    if name == 'Beam':
        node['children'] = [3, 4]
    gltf['nodes'].append(node)
gltf['scenes'] = [{'nodes': [0]}]
gltf['scene'] = 0
gltf['buffers'] = [{'byteLength': len(binary)}]
header = json.dumps(gltf, separators=(',', ':')).encode()
header += b' ' * (-len(header) % 4)
binary += b'\0' * (-len(binary) % 4)
output = output_dir / 'balance.glb'
output.write_bytes(struct.pack('<III', 0x46546C67, 2, 28 + len(header) + len(binary))
                   + struct.pack('<II', len(header), 0x4E4F534A) + header
                   + struct.pack('<II', len(binary), 0x004E4942) + binary)
print(f'Prepared {output}: {len(indices) // 3} triangles, four articulated parts.')
