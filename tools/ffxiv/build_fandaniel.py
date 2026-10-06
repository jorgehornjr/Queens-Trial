"""Build the supplied hooded Fandaniel with original geometry, UVs and weights.

Run Blender --background --factory-startup --python this_file.py. Six recent
Mixamo FBX files provide animation only; the original FFXIV skin is retained.
"""
from pathlib import Path
import bpy,json,math,hashlib,shutil
from mathutils import Matrix,Quaternion,Vector

ROOT=Path(__file__).resolve().parents[2]
QA=ROOT/'.godot/qa/ffxiv'
ART=ROOT/'art/characters/fandaniel'
OUT=ROOT/'assets/models/characters/fandaniel'
ART.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
source=QA/'fandaniel_export/model.json'
if not source.exists():source=ART/'source/model.json'
data=json.loads(source.read_text())
(ART/'source').mkdir(exist_ok=True)
shutil.copyfile(source,ART/'source/model.json') if source!=ART/'source/model.json' else None
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
arm=bpy.data.armatures.new('FandanielOriginalSkeleton')
rig=bpy.data.objects.new('FandanielRig',arm);bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
align=Matrix.Rotation(math.pi/2,4,'X')
bone_axes=Matrix.Rotation(-math.pi/2,4,'Z')
original={}
for i,b in enumerate(data['skeleton']):
    rotation=b['rotation'];local=Matrix.Translation(Vector(b['translation'])) @ Quaternion((rotation[3],*rotation[:3])).to_matrix().to_4x4()
    parent=data['skeleton'][b['parent']]['name'] if b['parent']>=0 else None
    native=original[parent] @ local if parent else local
    original[b['name']]=native
    bone=arm.edit_bones.new(b['name'])
    bone.head=align @ native.translation
    bone.tail=bone.head + (align @ native).to_3x3() @ Vector((.08,0,0))
    bone.matrix=align @ native @ bone_axes
    if parent:bone.parent=arm.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
meshes=[]
for index,raw in enumerate(data['meshes']):
    suffix=raw['material'].split('_')[-1].split('.')[0]
    mesh=bpy.data.meshes.new('FandanielOriginal_'+suffix)
    points=[align @ Vector(v['position'][:3]) for v in raw['vertices']]
    faces=[raw['indices'][i:i+3] for i in range(0,len(raw['indices']),3)]
    mesh.from_pydata(points,[],faces);mesh.update()
    obj=bpy.data.objects.new('Fandaniel_'+suffix,mesh);bpy.context.collection.objects.link(obj)
    obj.parent=rig
    uv=mesh.uv_layers.new(name='UVMap')
    for loop in mesh.loops:
        v=raw['vertices'][loop.vertex_index]
        uv.data[loop.index].uv=(v['uv'][0],1-v['uv'][1])
    for polygon in mesh.polygons:polygon.use_smooth=True
    mesh.normals_split_custom_set_from_vertices([align.to_3x3() @ Vector(v['normal']) for v in raw['vertices']])
    colors=mesh.color_attributes.new(name='FFXIVColor',type='FLOAT_COLOR',domain='POINT')
    for i,v in enumerate(raw['vertices']):
        colors.data[i].color=(1,1,1,v.get('color',[1,1,1,1])[3])
        for name,weight in zip(v['joints'],v['weights']):
            if weight>0:
                group=obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
                group.add([i],weight,'REPLACE')
    skin=obj.modifiers.new('OriginalFFXIVSkin','ARMATURE');skin.object=rig
    material=bpy.data.materials.new('Fandaniel_'+suffix);material.use_nodes=True
    material.use_backface_culling=False;material.surface_render_method='DITHERED'
    shader=material.node_tree.nodes.get('Principled BSDF')
    nodes=material.node_tree.nodes;links=material.node_tree.links
    for kind in ['basecolor','normal','roughness','emission']:
        image=bpy.data.images.load(str(OUT/f'fandaniel_{suffix}_{kind}.png'),check_existing=True)
        image.pack()
        if kind in ['normal','roughness']:image.colorspace_settings.name='Non-Color'
        tex=nodes.new('ShaderNodeTexImage');tex.image=image
        if kind=='basecolor':
            links.new(tex.outputs['Color'],shader.inputs['Base Color'])
            links.new(tex.outputs['Alpha'],shader.inputs['Alpha'])
        elif kind=='normal':
            normal=nodes.new('ShaderNodeNormalMap');links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],shader.inputs['Normal'])
        elif kind=='roughness':links.new(tex.outputs['Color'],shader.inputs['Roughness'])
        else:links.new(tex.outputs['Color'],shader.inputs['Emission Color']);shader.inputs['Emission Strength'].default_value=1.0
    mesh.materials.append(material);meshes.append(obj)

rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
CLIPS={'Idle':'breathing_idle','Walking':'walk','Look Around':'intro_arrival',
       'Standing React Death Forward':'standing_death','Left Strafe':'left_slide','Right Strafe':'right_slide'}
MAP={'n_hara':'Hips','j_sebo_a':'Spine','j_sebo_b':'Spine1','j_sebo_c':'Spine2','j_kubi':'Neck','j_kao':'Head'}
for side,label in [('l','Left'),('r','Right')]:
    MAP.update({f'{target}_{side}':label+src for target,src in [
        ('j_sako','Shoulder'),('j_ude_a','Arm'),('j_ude_b','ForeArm'),('j_te','Hand'),
        ('j_asi_a','UpLeg'),('j_asi_b','Leg'),('j_asi_c','Leg'),('j_asi_d','Foot')]})
report={'model':'Hooded Fandaniel','mod_author':'Dekken','original_skeleton_bones':len(rest),
        'original_meshes':[{k:len(m[k]) for k in ['vertices','indices']} for m in data['meshes']],
        'clips':{},'bone_rest':{n:[list(row) for row in m] for n,m in rest.items()}}
rig.animation_data_create()
for obj in meshes:obj.hide_viewport=True
for download,clip in CLIPS.items():
    archive=ART/'animations'/(download+'(1).fbx');archive.parent.mkdir(exist_ok=True)
    fbx=Path.home()/'Downloads'/archive.name
    if not fbx.exists():fbx=archive
    if fbx!=archive:shutil.copyfile(fbx,archive)
    before=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(archive));imported=set(bpy.data.objects)-before
    src=next(o for o in imported if o.type=='ARMATURE')
    action=src.animation_data.action;start,end=[int(v) for v in action.frame_range]
    source_rest={n:align @ src.data.bones['mixamorig:'+n].matrix_local for n in MAP.values()}
    corrections={}
    anatomical=set(n for n in MAP if any(s in n for s in ['j_ude','j_te','j_asi','j_sako']))
    for target,n in MAP.items():
        sq=source_rest[n].to_quaternion();tq=rest[target].to_quaternion()
        if target in anatomical:
            swing=(sq @ Vector((0,1,0))).rotation_difference(tq @ Vector((0,1,0)))
            corrections[target]=(swing @ sq).inverted() @ tq
        else:corrections[target]=sq.inverted() @ tq
    ratio=rest['n_hara'].translation.z/source_rest['Hips'].translation.z
    bpy.context.scene.frame_set(start);first=(align @ src.pose.bones['mixamorig:Hips'].matrix).translation.copy()
    bpy.context.scene.frame_set(end);last=(align @ src.pose.bones['mixamorig:Hips'].matrix).translation.copy()
    drift=last-first;loop=clip in ['walk','breathing_idle','left_slide','right_slide']
    baked=bpy.data.actions.new(clip);rig.animation_data.action=baked
    last_q={};samples=[]
    for frame in range(start,end+1):
        bpy.context.scene.frame_set(frame)
        sampled={n:align @ src.pose.bones['mixamorig:'+n].matrix for n in MAP.values()}
        hips=sampled['Hips'].translation-source_rest['Hips'].translation
        if loop:
            progress=(frame-start)/max(1,end-start)
            hips.x-=first.x-source_rest['Hips'].translation.x+drift.x*progress
            hips.y-=first.y-source_rest['Hips'].translation.y+drift.y*progress
        desired={}
        for pb in rig.pose.bones:
            name=pb.name;parent=pb.parent.name if pb.parent else None
            parent_pose=desired[parent] if parent else Matrix.Identity(4)
            local_rest=rest[parent].inverted() @ rest[name] if parent else rest[name]
            inherited=parent_pose @ local_rest
            position=rest[name].translation+hips*ratio if name=='n_hara' else inherited.translation
            if name in MAP:
                q=sampled[MAP[name]].to_quaternion() @ corrections[name]
                matrix=Matrix.Translation(position) @ q.to_matrix().to_4x4()
            else:matrix=inherited
            pb.rotation_mode='QUATERNION';pb.matrix_basis=local_rest.inverted() @ parent_pose.inverted() @ matrix
            q=pb.rotation_quaternion.copy()
            if name in last_q and q.dot(last_q[name])<0:q.negate();pb.rotation_quaternion=q
            last_q[name]=q;desired[name]=matrix
        # The original skirt chains have no Mixamo counterpart. Follow the
        # native leg swing mildly, so the robe's hem accompanies the stride.
        for side in ['l','r']:
            thigh=rig.pose.bones['j_asi_a_'+side].rotation_quaternion.to_euler().x
            for region,amount in [('f',.26),('b',.15),('s',.20)]:
                name='j_sk_'+region+'_a_'+side
                q=rest[name].to_quaternion()
                rig.pose.bones[name].rotation_quaternion=q.inverted() @ Quaternion((1,0,0),max(-.24,min(.24,thigh*amount))) @ q
        bpy.context.view_layer.update()
        if clip=='standing_death':
            settle=max(0.0,min(1.0,((frame-start)/(end-start)-.35)/.4))
            for side in ['l','r']:
                ankle=rig.pose.bones['j_asi_d_'+side].matrix.translation.copy()
                for region in ['f','b','s']:
                    name='j_sk_'+region+'_a_'+side
                    pb=rig.pose.bones[name]
                    head=pb.matrix.translation.copy()
                    # FF XIV settles these chains through cloth physics. Bake a
                    # leg-directed rest for the corpse instead of leaving the
                    # robe pointing upwards after the hips rotate forward.
                    direction=ankle-head
                    if direction.length>.01:
                        base=rest[name].to_quaternion()
                        aim=(base @ Vector((0,1,0))).rotation_difference(direction.normalized()) @ base
                        q=pb.matrix.to_quaternion().slerp(aim,settle)
                        pb.matrix=Matrix.Translation(head) @ q.to_matrix().to_4x4()
                        bpy.context.view_layer.update()
        contact=[rig.pose.bones['j_asi_d_'+s].matrix.translation.z-.055 for s in ['l','r']]
        if clip=='standing_death':contact.extend(rig.pose.bones[n].matrix.translation.z-.045 for n in ['j_kao','j_sebo_c','j_te_l','j_te_r'])
        correction=max(0.0,.008-min(contact))
        rig.pose.bones['n_hara'].location+=rest['n_hara'].to_3x3().inverted() @ Vector((0,0,correction))
        for pb in rig.pose.bones:
            pb.keyframe_insert('location',frame=frame-start,group=pb.name)
            pb.keyframe_insert('rotation_quaternion',frame=frame-start,group=pb.name)
        if frame in [start,(start+end)//2,end]:
            bpy.context.view_layer.update();samples.append({n:list(rig.pose.bones[n].matrix.translation) for n in ['n_hara','j_kao','j_asi_d_l','j_asi_d_r']})
    baked.use_fake_user=True
    track=rig.animation_data.nla_tracks.new();track.name=clip;track.strips.new(clip,0,baked);track.mute=True
    report['clips'][clip]={'download':archive.name,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'frames':end-start+1,'duration':(end-start)/30,'samples':samples}
    rig.animation_data.action=None
    for obj in imported:bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.actions.remove(action,do_unlink=True)
    print('FANDANIEL_MIXAMO_CLIP',clip,end-start+1,flush=True)

import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from import_native_walks import bake_native_walks
references=bake_native_walks(rig,report)
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
for obj in meshes:obj.hide_viewport=False
bpy.context.scene.render.fps=30;bpy.context.scene.frame_set(0)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for obj in meshes:obj.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(ART/'fandaniel_mixamo.blend'))
# Keep superseded arrivals in Blender, outside the game's active clips.
for action in list(bpy.data.actions):
    if '_reference' in action.name:bpy.data.actions.remove(action,do_unlink=True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'fandaniel_mixamo.glb'),use_selection=True,
    export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',
    export_nla_strips=True,export_def_bones=True,export_force_sampling=True,
    export_frame_range=False)
(ART/'rig_report.json').write_text(json.dumps(report,indent=2))
print('FANDANIEL_EXPORTED',flush=True)
