"""Inspect exported FFXIV walking poses in Blender before choosing the intro."""
from pathlib import Path
import bpy,json,math
from mathutils import Matrix
ROOT=Path(__file__).resolve().parents[2]
QA=ROOT/'.godot/qa/ffxiv/native_walk'
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/characters/fandaniel/fandaniel_mixamo.blend'))
rig=bpy.data.objects['FandanielRig']
result={'target':{'matrix':[list(row) for row in rig.matrix_world],'bones':{b.name:{'head':list(b.head_local),'rotation':list(b.matrix_local.to_quaternion())} for b in rig.data.bones}}}
for file in QA.glob('*.fbx'):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(file));added=set(bpy.data.objects)-before
    source=next(o for o in added if o.type=='ARMATURE')
    a=source.animation_data.action;first,last=a.frame_range
    sample={'name':source.name,'objects':[(o.name,o.type) for o in added],'matrix':[list(row) for row in source.matrix_world],'frames':[first,last],'fps':bpy.context.scene.render.fps,
        'rest':{b.name:{'head':list(b.head_local),'rotation':list(b.matrix_local.to_quaternion())} for b in source.data.bones},'poses':[]}
    for f in [first,(first+last)/2,last]:
        bpy.context.scene.frame_set(int(f),subframe=f-int(f))
        sample['poses'].append({'frame':f,'bones':{n:{'matrix':[list(row) for row in source.pose.bones[n].matrix],
           'world':list(source.matrix_world @ source.pose.bones[n].matrix.translation)} for n in ['n_root','n_hara','j_ude_a_l','j_ude_b_l','j_te_l','j_asi_a_l','j_asi_d_l'] if n in source.pose.bones}})
    result[file.name]=sample
    for o in added:bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.actions.remove(a,do_unlink=True)
(QA/'inspection.json').write_text(json.dumps(result,indent=2))
print('NATIVE_WALK_INSPECTION_SAVED')
