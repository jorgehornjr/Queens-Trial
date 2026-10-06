"""Editable character rig plus a physical cape cage; no Adobe dependency."""
from pathlib import Path
import sys, math, json
import bpy, bmesh
import numpy as np
from mathutils import Vector, Quaternion
ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / '.godot' / 'qa'
ART = ROOT / 'art/characters/fallen_priest'
OUT = ROOT / 'assets/models/characters/fallen_priest'
for p in [ART, OUT]: p.mkdir(parents=True, exist_ok=True)
(ART / '.gdignore').write_text('')
sys.path.insert(0, str(QA / 'blender_modules'))
from scipy.spatial import cKDTree
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra
bpy.ops.wm.open_mainfile(filepath=str(QA / 'priest_prepared.blend'))
source = bpy.data.objects['Priest_Working']
mesh = source.data
data = np.load(QA / 'priest_mesh.npz')
v, f = data['vertices'], data['faces']
labels = np.load(QA / 'priest_face_labels.npy')
defs = {}
def bone(n, a, b, parent=None): defs[n] = (np.array(a), np.array(b), parent)
bone('Root', (0,0,.02), (0,0,.2))
bone('Pelvis', (0,-.015,1.13), (0,-.015,1.28), 'Root')
bone('Spine', (0,-.015,1.28), (0,-.015,1.46), 'Pelvis')
bone('Chest', (0,-.015,1.46), (0,-.015,1.68), 'Spine')
bone('Neck', (0,-.015,1.68), (0,-.035,1.81), 'Chest')
bone('Head', (0,-.035,1.81), (0,-.065,2.10), 'Neck')
for side,s in [('L',1),('R',-1)]:
    bone('Clavicle_'+side,(0,0,1.63),(s*.26,0,1.62),'Chest')
    bone('UpperArm_'+side,(s*.26,0,1.62),(s*.32,-.015,1.31),'Clavicle_'+side)
    bone('Forearm_'+side,(s*.32,-.015,1.31),(s*.355,-.045,1.05),'UpperArm_'+side)
    bone('Hand_'+side,(s*.355,-.045,1.05),(s*.36,-.05,.92),'Forearm_'+side)
    bone('Thigh_'+side,(s*.14,-.015,1.13),(s*.17,-.025,.64),'Pelvis')
    bone('Shin_'+side,(s*.17,-.025,.64),(s*.205,0,.13),'Thigh_'+side)
    bone('Foot_'+side,(s*.205,0,.13),(s*.22,-.18,.045),'Shin_'+side)
bone('Tabard01',(0,-.18,1.13),(0,-.19,.75),'Pelvis')
bone('Tabard02',(0,-.19,.75),(0,-.20,.24),'Tabard01')

# Sample the actual rear surface, so each cage row follows the silhouette.
cape_ids = np.unique(f[labels == 'Cape'])
cv = v[cape_ids]
cols, rows = 9, 13
nodes = []
for row in range(rows):
    z = 1.62 - row / (rows-1) * 1.37
    near = cv[abs(cv[:,2]-z)<.085]
    if not len(near): near = cv
    lo, hi = np.quantile(near[:,0], [.01,.99])
    for col in range(cols):
        x = lo + (hi-lo) * col/(cols-1)
        dist = ((cv[:,0]-x)/.045)**2 + ((cv[:,2]-z)/.06)**2
        sample = cv[np.argsort(dist)[:12]]
        y = float(np.median(sample[:,1]))
        point = [float(x), y, float(z)]
        nodes.append(point)
        bone(f'Cape_{row:02}_{col:02}', point, (x,y,z-.06), 'Chest')
ad = bpy.data.armatures.new('PriestSkeleton')
rig = bpy.data.objects.new('PriestRig', ad)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
source.select_set(False)
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for n,(a,b,parent) in defs.items():
    eb = ad.edit_bones.new(n)
    eb.head, eb.tail = a, b
    if parent: eb.parent = ad.edit_bones[parent]
    eb.align_roll(Vector((0,-1,0)))
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front = True
for group in ['Body','Cape','Tabard']: ad.collections.new(group)
for n in defs: ad.collections['Cape' if n.startswith('Cape') else 'Tabard' if n.startswith('Tabard') else 'Body'].assign(ad.bones[n])

names = list(defs)
ni = {n:i for i,n in enumerate(names)}
w = np.zeros((len(v),len(names)),dtype=np.float32)
body_names = [n for n in names if not n.startswith(('Cape','Tabard')) and n != 'Root']
edges = np.vstack([f[:,[0,1]], f[:,[1,2]], f[:,[2,0]]])
g = coo_matrix((np.linalg.norm(v[edges[:,0]]-v[edges[:,1]],axis=1),(edges[:,0],edges[:,1])),shape=(len(v),len(v))).tocsr()
g = g.maximum(g.T)
body_ids = np.unique(f[labels != 'Cape'])
tree = cKDTree(v[body_ids])
fields = []
for n in body_names:
    a,b,_ = defs[n]
    vec = b-a
    t = np.clip((v-a)@vec/(vec@vec),0,1)
    eu = np.linalg.norm(v-(a+t[:,None]*vec),axis=1)
    _, close = tree.query([a+(b-a)*t for t in [.15,.4,.65,.85]], k=8)
    ge = dijkstra(g,indices=body_ids[np.unique(close)],min_only=True,directed=False)
    dist = np.where(np.isfinite(ge), .65*ge+.35*eu, eu)
    if n.endswith('_L'): dist[v[:,0]<-.04] += 2
    if n.endswith('_R'): dist[v[:,0]>.04] += 2
    fields.append(dist)
vals = np.exp(-(np.stack(fields,axis=1)/.12)**2) + 1e-12
vals /= vals.sum(1,keepdims=True)
for i,n in enumerate(body_names): w[:,ni[n]] = vals[:,i]
tab = np.unique(f[labels == 'Tabard'])
a = np.clip((1.13-v[tab,2])/.16,0,1)
b = np.clip((.84-v[tab,2])/.25,0,1)
w[tab] = 0
w[tab,ni['Pelvis']] = 1-a
w[tab,ni['Tabard01']] = a*(1-b)
w[tab,ni['Tabard02']] = a*b

cape_points = np.array(nodes).reshape(rows,cols,3)
for index in cape_ids:
    x,y,z = v[index]
    if z > 1.43:
        w[index] = 0
        w[index,ni['Chest']] = 1
        continue
    rf = np.clip((1.62-z)/1.37*(rows-1),0,rows-1-1e-6)
    r = int(rf); rt = rf-r
    lo = (1-rt)*cape_points[r,0,0]+rt*cape_points[r+1,0,0]
    hi = (1-rt)*cape_points[r,-1,0]+rt*cape_points[r+1,-1,0]
    cf = np.clip((x-lo)/max(hi-lo,.01)*(cols-1),0,cols-1-1e-6)
    c = int(cf); ct = cf-c
    w[index] = 0
    for rr,cc,amount in [(r,c,(1-rt)*(1-ct)),(r,c+1,(1-rt)*ct),(r+1,c,rt*(1-ct)),(r+1,c+1,rt*ct)]:
        w[index,ni[f'Cape_{rr:02}_{cc:02}']] = amount
# The separation seam is under the shoulder mantle; both adjacent vertices
# use the same weights, including all duplicate coordinates.
_, inv, counts = np.unique(v,axis=0,return_inverse=True,return_counts=True)
for duplicate in np.flatnonzero(counts>1):
    ids = np.flatnonzero(inv==duplicate)
    w[ids] = w[ids].mean(0)
top = np.argpartition(w,-4,axis=1)[:,-4:]
reduced = np.zeros_like(w)
np.put_along_axis(reduced,top,np.take_along_axis(w,top,axis=1),axis=1)
w = reduced/reduced.sum(1,keepdims=True)
assert np.isfinite(w).all() and np.max(abs(w.sum(1)-1)) < 1e-5
for col,n in enumerate(names):
    vg = source.vertex_groups.new(name=n)
    for index in np.flatnonzero(w[:,col]>1e-7): vg.add([int(index)],float(w[index,col]),'REPLACE')
mod = source.modifiers.new('CharacterSkin','ARMATURE')
mod.object = rig
source.parent = rig
base = mesh.materials[0]
normal_attribute = mesh.attributes.new('rig_rest_normal','FLOAT_VECTOR','POINT')
normal_attribute.data.foreach_set('vector',np.array([vert.normal[:] for vert in mesh.vertices],dtype=np.float32).ravel())
parts = []
for label in np.unique(labels):
    part = source.copy(); part.data = mesh.copy(); part.name = str(label)+'Mesh'
    bpy.context.scene.collection.objects.link(part)
    bm = bmesh.new(); bm.from_mesh(part.data); bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[face for i,face in enumerate(bm.faces) if labels[i]!=label],context='FACES')
    bmesh.ops.delete(bm,geom=[vert for vert in bm.verts if not vert.link_faces],context='VERTS')
    bm.to_mesh(part.data); bm.free()
    normals = np.empty(len(part.data.vertices)*3,dtype=np.float32)
    part.data.attributes['rig_rest_normal'].data.foreach_get('vector',normals)
    part.data.normals_split_custom_set_from_vertices(normals.reshape(-1,3).tolist())
    part.data.materials.clear(); material = base.copy(); material.name = 'Priest_'+str(label)
    material.use_backface_culling = False
    part.data.materials.append(material); parts.append(part)
bpy.data.objects.remove(source,do_unlink=True)

sys.path.insert(0, str(Path(__file__).parent))
from animate import build_actions
clips = build_actions(rig)
for image in bpy.data.images:
    if image.source=='FILE': image.pack()
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
for part in parts: part.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(ART/'fallen_priest_rig.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'fallen_priest_rig.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_nla_strips=True,export_def_bones=True,export_force_sampling=True)
# glTF rotates Blender Z-up into Godot Y-up.
config = {'columns':cols,'rows':rows,'points':[[x,z,-y] for x,y,z in nodes],'bones':[f'Cape_{r:02}_{c:02}' for r in range(rows) for c in range(cols)]}
(OUT/'cape_cage.json').write_text(json.dumps(config,indent=2))
report={'vertices':len(v),'triangles':len(f),'bones':len(defs),'parts':{str(n):int((labels==n).sum()) for n in np.unique(labels)},'clips':[c[0] for c in clips],'cape_particles':len(nodes),'max_weight_error':float(abs(w.sum(1)-1).max()),'max_influences':int((w>1e-7).sum(1).max())}
(ART/'rig_report.json').write_text(json.dumps(report,indent=2))
print('PRIEST_RIG_EXPORTED',report,flush=True)
