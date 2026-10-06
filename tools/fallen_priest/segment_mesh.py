"""Separate the scanned cape by surface distance, retaining original UVs."""
from pathlib import Path
import sys
import bpy
import numpy as np
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / '.godot' / 'qa'
sys.path.insert(0, str(QA / 'blender_modules'))
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra

bpy.ops.wm.open_mainfile(filepath=str(QA / 'priest_prepared.blend'))
obj = bpy.data.objects['Priest_Working']
d = np.load(QA / 'priest_mesh.npz')
v, f = d['vertices'], d['faces']
x, y, z = v.T
edges = np.vstack([f[:, [0, 1]], f[:, [1, 2]], f[:, [2, 0]]])
g = coo_matrix((np.linalg.norm(v[edges[:, 0]]-v[edges[:, 1]], axis=1), (edges[:, 0], edges[:, 1])), shape=(len(v), len(v))).tocsr()
g = g.maximum(g.T)
cape_seed = (y > .14) & (z < 1.57) & (z > .27)
body_seed = (y < .005) | ((abs(x) > .32) & (y < .065) & (z > .80)) | (z < .18) | (z > 1.70)
dc = dijkstra(g, indices=np.flatnonzero(cape_seed), min_only=True, directed=False)
db = dijkstra(g, indices=np.flatnonzero(body_seed), min_only=True, directed=False)
cape = (dc < db) & (z < 1.64) & (y > -.035)
c = v[f].mean(1)
labels = np.full(len(f), 'Body', dtype='U24')
labels[cape[f].sum(1) >= 2] = 'Cape'
labels[(labels == 'Body') & (c[:, 2] > 1.76)] = 'Head'
labels[(labels == 'Body') & (abs(c[:, 0]) < .17) & (c[:, 1] < -.12) & (c[:, 2] < 1.13) & (c[:, 2] > .21)] = 'Tabard'
np.save(QA / 'priest_face_labels.npy', labels)
print('REGIONS', {n: int((labels == n).sum()) for n in np.unique(labels)}, flush=True)
obj.data.materials.clear()
for n, col in [('Body', (.25,.3,.38,1)), ('Cape', (.1,.8,.4,1)), ('Head', (.5,.65,.9,1)), ('Tabard', (.9,.4,.1,1))]:
    m = bpy.data.materials.new(n)
    m.diffuse_color = col
    obj.data.materials.append(m)
obj.data.polygons.foreach_set('material_index', np.array([['Body','Cape','Head','Tabard'].index(n) for n in labels], dtype=np.int32))
s = bpy.context.scene
s.render.engine = 'BLENDER_WORKBENCH'
s.display.shading.color_type = 'MATERIAL'
s.display.shading.show_cavity = True
s.world.color = (.07,.07,.07)
s.render.resolution_x = 900
s.render.resolution_y = 900
cam = bpy.data.objects.new('Camera', bpy.data.cameras.new('Camera'))
s.collection.objects.link(cam)
s.camera = cam
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 2.7
for name, pos in [('front',(0,-6,1.1)),('back',(0,6,1.1)),('side',(6,0,1.1))]:
    cam.location = pos
    cam.rotation_euler = (Vector((0,0,1.1))-cam.location).to_track_quat('-Z','Y').to_euler()
    s.render.filepath = str(QA / ('priest_regions_'+name+'.png'))
    bpy.ops.render.render(write_still=True)
