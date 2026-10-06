"""Build an editable FK/IK rig and a skinned glTF from the prepared source.

Run with Blender --background --python tools/archangel/build_rig.py.
Weights on shared cut vertices are identical, so splitting meshes does not
introduce animation cracks. Original UVs and 4K images remain untouched.
"""
from pathlib import Path
import sys
import math
import json
import bpy
import bmesh
import numpy as np
from mathutils import Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT/'.godot'/'qa'
ART = ROOT/'art'/'characters'/'archangel'
ASSETS = ROOT/'assets'/'models'/'characters'/'archangel'
ART.mkdir(parents=True,exist_ok=True)
ASSETS.mkdir(parents=True,exist_ok=True)
(ART/'.gdignore').write_text('')
sys.path.insert(0,str(QA/'blender_modules'))
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra
from scipy.spatial import cKDTree

bpy.ops.wm.open_mainfile(filepath=str(QA/'archangel_prepared.blend'))
source = bpy.data.objects['Archangel_Working']
mesh = source.data
data = np.load(QA/'archangel_mesh.npz')
coords,faces = data['vertices'],data['faces']
labels = np.load(QA/'archangel_face_labels.npy')
definitions = {}

def bone(name,head,tail,parent=None,deform=True):
    definitions[name]={'head':head,'tail':tail,'parent':parent,'deform':deform}

bone('Root',(0,.15,.03),(0,.15,.25))
bone('Pelvis',(-.025,.16,1.10),(-.025,.15,1.25),'Root')
bone('Spine',(-.025,.15,1.25),(-.035,.15,1.40),'Pelvis')
bone('Chest',(-.035,.15,1.40),(-.045,.15,1.63),'Spine')
bone('UpperChest',(-.045,.15,1.63),(-.05,.15,1.75),'Chest')
bone('Neck',(-.05,.15,1.75),(-.055,.15,1.84),'UpperChest')
bone('Head',(-.055,.15,1.84),(-.07,.15,2.01),'Neck')
for side,s,shoulder,elbow,wrist,hand,hip,knee,ankle,toe in [
    ('R',-1,(-.32,.10,1.57),(-.425,.075,1.32),(-.535,.04,1.08),(-.55,.04,.97),(-.16,.10,1.10),(-.245,.11,.62),(-.305,.15,.14),(-.29,-.015,.05)),
    ('L',1,(.285,.29,1.57),(.38,.28,1.32),(.46,.27,1.10),(.48,.25,.97),(.15,.23,1.10),(.23,.28,.62),(.24,.34,.14),(.30,.17,.05))]:
    bone('Clavicle_'+side,(-.045,.15,1.67),shoulder,'UpperChest')
    bone('UpperArm_'+side,shoulder,elbow,'Clavicle_'+side)
    bone('Forearm_'+side,elbow,wrist,'UpperArm_'+side)
    bone('Hand_'+side,wrist,hand,'Forearm_'+side)
    bone('Thigh_'+side,hip,knee,'Pelvis')
    bone('Shin_'+side,knee,ankle,'Thigh_'+side)
    bone('Foot_'+side,ankle,toe,'Shin_'+side)
    bone('Toe_'+side,toe,(toe[0],toe[1]-.075,toe[2]),'Foot_'+side)
    # Finger chains remain available for close-up gestures; the sword grip
    # starts neutral, and no digit is forced into a Mixamo rest pose.
    palm = np.array(hand)
    for digit in range(5):
        offset = (digit-2)*.022
        start = palm+np.array([offset,.002,.008 if digit==0 else -.01])
        direction = np.array([(-.015 if digit==0 else .005)*s,-.008,-.030])
        previous = 'Hand_'+side
        for joint in range(3):
            name = f'Finger{digit+1}_{joint+1}_{side}'
            a,b = start+direction*joint,start+direction*(joint+1)
            bone(name,tuple(a),tuple(b),previous)
            previous=name
    # Authoring controls, excluded from skin export.
    bone('CTRL_Hand_'+side,wrist,hand,'Root',False)
    bone('CTRL_ElbowPole_'+side,(elbow[0],elbow[1]-.65,elbow[2]),(elbow[0],elbow[1]-.65,elbow[2]+.12),'Root',False)
    bone('CTRL_Foot_'+side,ankle,toe,'Root',False)
    bone('CTRL_KneePole_'+side,(knee[0],knee[1]-.70,knee[2]),(knee[0],knee[1]-.70,knee[2]+.12),'Root',False)

    root=(s*.24,.36,1.53)
    hinge=(s*.48,.43,1.89)
    elbow_w=(s*.80,.30,2.02)
    tip=(s*1.29,.07,2.11)
    bone('WingRoot_'+side,root,hinge,'Chest')
    bone('WingUpper02_'+side,hinge,elbow_w,'WingRoot_'+side)
    bone('WingUpper03_'+side,elbow_w,tip,'WingUpper02_'+side)
    bone('WingMid01_'+side,(s*.43,.42,1.72),(s*.73,.43,1.63),'WingRoot_'+side)
    bone('WingMid02_'+side,(s*.73,.43,1.63),(s*1.18,.32,1.58),'WingMid01_'+side)
    bone('WingLower01_'+side,(s*.34,.42,1.52),(s*.64,.46,1.33),'WingRoot_'+side)
    bone('WingLower02_'+side,(s*.64,.46,1.33),(s*1.04,.40,1.07),'WingLower01_'+side)
    for n,head,tail,parent in [
        (1,(s*.76,.35,1.96),(s*1.22,.15,1.97),'WingUpper02_'+side),
        (2,(s*.64,.43,1.73),(s*1.13,.34,1.76),'WingMid01_'+side),
        (3,(s*.58,.45,1.52),(s*.97,.39,1.42),'WingLower01_'+side),
        (4,(s*.55,.45,1.42),(s*.83,.45,1.16),'WingLower01_'+side)]:
        bone(f'FeatherFan{n}_{side}',head,tail,parent)
    bone('CTRL_Wing_'+side,root,hinge,'Chest',False)

bone('Sword',(-.55,.04,1.0),(.54,-.66,.10),'Hand_R')
bone('Halo',(-.05,.15,2.06),(-.05,.15,2.16),'Head')
for label,y in [('Front',-.025),('Back',.28)]:
    bone('Cloth'+label+'01',(0,y,1.12),(0,y,.91),'Pelvis')
    bone('Cloth'+label+'02',(0,y,.91),(0,y,.67),'Cloth'+label+'01')

arm_data = bpy.data.armatures.new('Archangel_Skeleton')
rig = bpy.data.objects.new('Archangel_Rig',arm_data)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
source.select_set(False)
bpy.ops.object.mode_set(mode='EDIT')
for name,definition in definitions.items():
    edit=arm_data.edit_bones.new(name)
    edit.head=definition['head']
    edit.tail=definition['tail']
    edit.use_deform=definition['deform']
    if definition['parent']:
        edit.parent=arm_data.edit_bones[definition['parent']]
    edit.align_roll(Vector((0,-1,0)))
bpy.ops.object.mode_set(mode='OBJECT')
arm_data.display_type='OCTAHEDRAL'
rig.show_in_front=True
for name in ['Body','Hands','Wings','Accessories','Controls']:
    arm_data.collections.new(name)
for name in definitions:
    group = 'Controls' if name.startswith('CTRL_') else 'Wings' if name.startswith(('Wing','Feather')) else 'Hands' if name.startswith('Finger') else 'Accessories' if name.startswith(('Cloth','Sword','Halo')) else 'Body'
    arm_data.collections[group].assign(arm_data.bones[name])
    arm_data.bones[name].color.palette = {'Body':'THEME04','Hands':'THEME03','Wings':'THEME02','Accessories':'THEME05','Controls':'THEME01'}[group]
rig['description']='FK body, two 11-bone wing fans, optional limb IK; neutral source pose.'
widgets=bpy.data.collections.new('Rig Widgets')
bpy.context.scene.collection.children.link(widgets)
widgets.hide_render=True
for side in ['L','R']:
    constraint=rig.pose.bones['WingRoot_'+side].constraints.new('COPY_ROTATION')
    constraint.name='Wing master '+side
    constraint.target=rig
    constraint.subtarget='CTRL_Wing_'+side
    constraint.target_space='LOCAL'
    constraint.owner_space='LOCAL'
    constraint.mix_mode='AFTER'
for kind,size in [('Hand',.12),('Foot',.16),('Wing',.28),('ElbowPole',.07),('KneePole',.07)]:
    widget_mesh=bpy.data.meshes.new('WGT_'+kind)
    points=[(math.cos(i*math.pi/12)*size,0,math.sin(i*math.pi/12)*size) for i in range(24)]
    widget_mesh.from_pydata(points,[(i,(i+1)%24) for i in range(24)],[])
    widget=bpy.data.objects.new('WGT_'+kind,widget_mesh)
    widgets.objects.link(widget)
    widget.hide_render=True
    widget.hide_set(True)
    for side in ['L','R']:
        pose=rig.pose.bones['CTRL_'+kind+'_'+side]
        pose.custom_shape=widget
        pose.use_custom_shape_bone_size=False
for kind in ['arm_ik','leg_ik']:
    rig[kind]=0.0
    rig.id_properties_ui(kind).update(min=0.0,max=1.0,description='0: FK / 1: IK controls')
for side in ['L','R']:
    for kind,bname,target,pole,chain in [('arm','Forearm_', 'CTRL_Hand_', 'CTRL_ElbowPole_',2),('leg','Shin_','CTRL_Foot_','CTRL_KneePole_',2)]:
        constraint=rig.pose.bones[bname+side].constraints.new('IK')
        constraint.name='IK '+kind+' '+side
        constraint.target=rig
        constraint.subtarget=target+side
        constraint.pole_target=rig
        constraint.pole_subtarget=pole+side
        constraint.chain_count=chain
        constraint.use_tail=True
        constraint.influence=0
        driver=constraint.driver_add('influence').driver
        var=driver.variables.new()
        var.name='mix'
        var.targets[0].id=rig
        var.targets[0].data_path='["'+kind+'_ik"]'
        driver.expression='mix'

# Bind surface geodesics: a forearm and a wing can overlap on screen but their
# weights travel along different mesh branches. Smooth the resulting fields.
names=[n for n,d in definitions.items() if d['deform']]
name_index={name:i for i,name in enumerate(names)}
weights=np.zeros((len(coords),len(names)),dtype=np.float32)
edges=np.vstack([faces[:,[0,1]],faces[:,[1,2]],faces[:,[2,0]]])
lengths=np.linalg.norm(coords[edges[:,0]]-coords[edges[:,1]],axis=1)
graph=coo_matrix((lengths,(edges[:,0],edges[:,1])),shape=(len(coords),len(coords))).tocsr()
graph=graph.maximum(graph.T)
vertex_regions={}
for label in np.unique(labels):
    mask=np.zeros(len(coords),dtype=bool)
    mask[np.unique(faces[labels==label])]=True
    vertex_regions[label]=mask
special=np.zeros(len(coords),dtype=bool)
for label in ['Wing_L','Wing_R','Sword','Halo']:
    special |= vertex_regions.get(label,False)
body_ids=np.flatnonzero(~special)
body_points=coords[body_ids]
tree=cKDTree(body_points)
body_names=[n for n in names if not n.startswith(('Wing','Feather','Cloth','Sword','Halo','Finger')) and n!='Root']

def segment_distance(points,name):
    a=np.array(definitions[name]['head']);b=np.array(definitions[name]['tail'])
    vector=b-a
    t=np.clip(((points-a)@vector)/(vector@vector),0,1)
    return np.linalg.norm(points-(a+t[:,None]*vector),axis=1)

fields=[]
for name in body_names:
    a=np.array(definitions[name]['head']);b=np.array(definitions[name]['tail'])
    query=np.array([a+(b-a)*t for t in [.15,.4,.65,.85]])
    _,near=tree.query(query,k=12)
    seeds=body_ids[np.unique(near)]
    geodesic=dijkstra(graph,directed=False,indices=seeds,min_only=True)
    euclidean=segment_distance(coords,name)
    distance=.68*geodesic+.32*euclidean
    distance=np.where(np.isfinite(distance),distance,euclidean)
    if name.endswith('_L'):
        distance[coords[:,0]<-.09]+=2
    if name.endswith('_R'):
        distance[coords[:,0]>.06]+=2
    fields.append(distance)
fields=np.stack(fields,axis=1)
body_weight=np.exp(-np.square(fields/.15))+.000000001
body_weight/=body_weight.sum(1,keepdims=True)
for i,name in enumerate(body_names):
    weights[:,name_index[name]]=body_weight[:,i]
print('BODY_WEIGHT_FIELDS',len(body_names),flush=True)

for side in ['L','R']:
    mask=vertex_regions['Wing_'+side]
    wnames=[name for name in names if name.endswith('_'+side) and name.startswith(('Wing','Feather'))]
    distances=np.stack([segment_distance(coords[mask],name) for name in wnames],axis=1)
    values=1.0/np.power(distances+.055,4)
    values/=values.sum(1,keepdims=True)
    # Attachment under the armor: gradual rotation rather than a rigid hinge.
    strength=np.clip((np.abs(coords[mask,0])-.27)/.23,0,1)
    strength=strength*strength*(3-2*strength)
    weights[mask]=0
    weights[mask,name_index['Chest']]=1-strength
    for column,name in enumerate(wnames):
        weights[mask,name_index[name]]=values[:,column]*strength
for label,name in [('Sword','Sword'),('Halo','Halo')]:
    mask=vertex_regions[label]
    weights[mask]=0
    weights[mask,name_index[name]]=1
for label in ['Front','Back']:
    mask=vertex_regions.get('Tabard_'+label)
    if mask is None:
        continue
    z=coords[mask,2]
    a=np.clip((1.12-z)/.16,0,1)
    b=np.clip((.93-z)/.22,0,1)
    weights[mask]=0
    weights[mask,name_index['Pelvis']]=1-a
    weights[mask,name_index['Cloth'+label+'01']]=a*(1-b)
    weights[mask,name_index['Cloth'+label+'02']]=a*b
# Free hand fingertips: restrict digit influences to the hand itself.
for side in ['L','R']:
    if side=='L':
        mask=(coords[:,0]>.36)&(coords[:,0]<.56)&(coords[:,2]<1.00)&(coords[:,2]>.85)&(~special)
    else:
        mask=(coords[:,0]<-.43)&(coords[:,0]>-.62)&(coords[:,2]<1.04)&(coords[:,2]>.91)&(~special)
    fnames=[n for n in names if n.startswith('Finger') and n.endswith('_'+side)]
    distances=np.stack([segment_distance(coords[mask],name) for name in fnames],axis=1)
    values=np.exp(-np.square(distances/.035))
    values/=np.maximum(values.sum(1,keepdims=True),1e-8)
    strength=np.clip((1.02-coords[mask,2])/.08,0,.85)
    weights[mask]*=(1-strength[:,None])
    for column,name in enumerate(fnames):
        weights[mask,name_index[name]]+=values[:,column]*strength

adj=graph.copy()
adj.data[:]=1
row_sums=np.asarray(adj.sum(1)).ravel()
adj.data*=np.repeat(1/np.maximum(row_sums,1),np.diff(adj.indptr))
rigid=vertex_regions['Sword']|vertex_regions['Halo']
for _ in range(10):
    smoothed=adj@weights
    weights[~rigid]=weights[~rigid]*.65+smoothed[~rigid]*.35
# The source also has a few coincident vertices in disconnected tiny triangles.
# Keep their skin identical instead of exposing submillimeter cracks in poses.
_,inverse,counts=np.unique(coords,axis=0,return_inverse=True,return_counts=True)
for duplicate in np.flatnonzero(counts>1):
    ids=np.flatnonzero(inverse==duplicate)
    weights[ids]=weights[ids].mean(axis=0)
# Four influences match Godot's default GPU skinning and keep sum exactly one.
top=np.argpartition(weights,-4,axis=1)[:,-4:]
reduced=np.zeros_like(weights)
np.put_along_axis(reduced,top,np.take_along_axis(weights,top,axis=1),axis=1)
weights=reduced/np.maximum(reduced.sum(1,keepdims=True),1e-12)
assert np.max(np.abs(weights.sum(1)-1))<1e-5
assert np.all(np.isfinite(weights))
for column,name in enumerate(names):
    group=source.vertex_groups.new(name=name)
    ids=np.flatnonzero(weights[:,column]>1e-6)
    # Quantization batches identical assignments without changing normalization.
    for index in ids:
        group.add([int(index)],float(weights[index,column]),'REPLACE')
modifier=source.modifiers.new('Archangel Skin','ARMATURE')
modifier.object=rig
modifier.use_deform_preserve_volume=False  # Match Godot's linear skinning.
source.parent=rig

parts=[]
base_material=mesh.materials[0]
for label in sorted(np.unique(labels)):
    part=source.copy()
    part.data=mesh.copy()
    part.name=label+'Mesh'
    bpy.context.scene.collection.objects.link(part)
    bm=bmesh.new()
    bm.from_mesh(part.data)
    bm.faces.ensure_lookup_table()
    remove=[face for i,face in enumerate(bm.faces) if labels[i]!=label]
    bmesh.ops.delete(bm,geom=remove,context='FACES')
    loose=[v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm,geom=loose,context='VERTS')
    bm.to_mesh(part.data)
    bm.free()
    part.data.materials.clear()
    mat=base_material.copy()
    mat.name='Archangel_'+label
    part.data.materials.append(mat)
    parts.append(part)
bpy.data.objects.remove(source,do_unlink=True)

def rotate(name,axis,angle):
    pose=rig.pose.bones[name]
    pose.rotation_mode='QUATERNION'
    basis=arm_data.bones[name].matrix_local.to_quaternion()
    pose.rotation_quaternion=basis.inverted()@Quaternion(axis,angle)@basis

def reset_pose():
    for pose in rig.pose.bones:
        pose.rotation_mode='QUATERNION'
        pose.rotation_quaternion=Quaternion()
        pose.location=Vector((0,0,0))
        pose.scale=Vector((1,1,1))

def animate(name,seconds,mode):
    rig.animation_data_create()
    action=bpy.data.actions.new(name)
    rig.animation_data.action=action
    for frame in range(1,int(seconds*30)+2):
        t=(frame-1)/30
        phase=2*math.pi*t/seconds
        reset_pose()
        rotate('Chest',(1,0,0),.009*math.sin(phase))
        rotate('Head',(0,0,1),.012*math.sin(phase-.5))
        for side,s in [('L',1),('R',-1)]:
            amount=.055*math.sin(phase)
            if mode=='intro':
                amount+=.18*math.sin(math.pi*min(t/seconds,1))**2
            elif mode=='flex':
                amount=.32*math.sin(phase)
            rotate('WingRoot_'+side,(0,0,1),s*amount)
            rotate('WingUpper02_'+side,(0,1,0),s*.035*math.sin(phase-.4))
            rotate('WingUpper03_'+side,(0,0,1),s*.045*math.sin(phase-.8))
            rotate('WingMid01_'+side,(1,0,0),.035*math.sin(phase-.5))
            rotate('WingMid02_'+side,(0,1,0),s*.03*math.sin(phase-.9))
            rotate('WingLower01_'+side,(1,0,0),.04*math.sin(phase-.8))
            rotate('WingLower02_'+side,(0,0,1),s*.035*math.sin(phase-1.1))
            for n in range(1,5):
                rotate(f'FeatherFan{n}_{side}',(1,0,0),(.02+n*.007)*math.sin(phase-.35*n))
        rotate('ClothFront01',(1,0,0),.017*math.sin(phase-.8))
        rotate('ClothBack01',(1,0,0),.024*math.sin(phase-.6))
        rotate('ClothBack02',(1,0,0),.028*math.sin(phase-1.0))
        if mode=='intro':
            rotate('Head',(0,0,1),.10*math.sin(phase))
        if mode=='pose':
            swell=math.sin(math.pi*t/seconds)**2
            rotate('UpperArm_R',(0,1,0),-.22*swell)
            rotate('Forearm_R',(1,0,0),-.32*swell)
            rotate('UpperArm_L',(0,1,0),.23*swell)
            rotate('Forearm_L',(1,0,0),-.45*swell)
            rotate('Thigh_L',(1,0,0),-.15*swell)
            rotate('Shin_L',(1,0,0),.32*swell)
            rotate('Head',(0,0,1),.20*swell)
        for pose in rig.pose.bones:
            if pose.bone.use_deform:
                pose.keyframe_insert('rotation_quaternion',frame=frame,group=pose.name)
    track=rig.animation_data.nla_tracks.new()
    track.name=name
    track.strips.new(name,1,action)
    track.mute=True
    return action

actions={}
for name,seconds,mode in [('breathing_idle',4,'idle'),('intro_presence',8,'intro'),('wing_flex_test',4,'flex'),('rig_pose_test',4,'pose')]:
    actions[name]=animate(name,seconds,mode)
rig.animation_data.action=None
reset_pose()
scene=bpy.context.scene
scene.render.fps=30
scene.frame_start=1
scene.frame_end=241
scene.frame_set(1)
for image in bpy.data.images:
    if image.source=='FILE' and image.has_data:
        image.pack()
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active=rig
for part in parts:
    part.select_set(True)
# Persist packed, editable source before export or diagnostic rendering.
bpy.ops.wm.save_as_mainfile(filepath=str(ART/'archangel_rig.blend'))
for track in rig.animation_data.nla_tracks:
    track.mute=False
rig.animation_data.action=None
bpy.ops.export_scene.gltf(filepath=str(ASSETS/'archangel_rig.glb'),export_format='GLB',
    use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',
    export_force_sampling=True,export_def_bones=True,export_skins=True,
    export_all_influences=False,export_materials='EXPORT',export_image_format='AUTO',
    export_texcoords=True,export_normals=True,export_tangents=True,
    export_cameras=False,export_lights=False,export_optimize_animation_size=True)
for track in rig.animation_data.nla_tracks:
    track.mute=True

report={'vertices_source':981894,'triangles_source':1963878,
        'vertices_working':int(len(coords)),'triangles_working':int(len(faces)),
        'deform_bones':len(names),'control_bones':len(definitions)-len(names),
        'max_influences':4,'max_weight_error':float(np.max(np.abs(weights.sum(1)-1))),
        'parts':{p.name:len(p.data.polygons) for p in parts},'actions':list(actions)}
(ART/'rig_report.json').write_text(json.dumps(report,indent=2))
print('RIG_REPORT',json.dumps(report),flush=True)

if '--skip-render' in sys.argv:
    print('RIG_COMPLETE',flush=True)
    raise SystemExit(0)

# Render actual skinned test poses, not an unbound bone overlay.
scene.render.engine='CYCLES'
scene.cycles.samples=20
scene.render.resolution_x=1400
scene.render.resolution_y=1100
scene.render.resolution_percentage=100
scene.world.color=(.12,.12,.12)
for name,location,power,size in [('Key',(-3,-4,5),650,4),('Fill',(3,-2,3),300,3),('Rim',(0,4,4),750,3)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=power;light.size=size
    node=bpy.data.objects.new(name,light);scene.collection.objects.link(node)
    node.location=location
    node.rotation_euler=(Vector((0,0,1.2))-node.location).to_track_quat('-Z','Y').to_euler()
cam_data=bpy.data.cameras.new('Rig Preview');cam_data.type='ORTHO';cam_data.ortho_scale=3.5
cam=bpy.data.objects.new('Rig Preview',cam_data);scene.collection.objects.link(cam);scene.camera=cam
for name,action,frame,location in [('rest',None,1,(0,-6,1.15)),
    ('body_pose',actions['rig_pose_test'],61,(0,-6,1.15)),
    ('wings_forward',actions['wing_flex_test'],31,(0,-6,1.15)),
    ('wings_back',actions['wing_flex_test'],91,(0,6,1.15))]:
    rig.animation_data.action=action
    reset_pose();scene.frame_set(frame)
    cam.location=location;cam.rotation_euler=(Vector((0,.1,1.15))-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(QA/('archangel_rig_'+name+'.png'))
    bpy.ops.render.render(write_still=True)
print('RIG_COMPLETE',flush=True)
