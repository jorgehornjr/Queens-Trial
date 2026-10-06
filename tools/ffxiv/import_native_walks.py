"""Apply sampled original FFXIV walks to the same FFXIV skeleton, without Mixamo.

Both skeletons have the same bind hierarchy; skin-motion deltas compensate only
the FBX/Blender bone-axis conventions. Geometry and original weights stay intact.
"""
from pathlib import Path
import bpy,json,math,shutil,hashlib
from mathutils import Matrix,Vector

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art/characters/fandaniel'
OUT=ROOT/'assets/models/characters/fandaniel'
QA=ROOT/'.godot/qa/ffxiv/native_walk'

def bake_native_walks(rig,report):
    archive=ART/'native_animations';archive.mkdir(parents=True,exist_ok=True)
    metadata=QA/'extraction_report.json'
    if not metadata.exists():metadata=archive/'extraction_report.json'
    extraction=json.loads(metadata.read_text())
    (archive/'extraction_report.json').write_text(json.dumps(extraction,indent=2))
    references=[]
    for clip in ['intro_arrival','ffxiv_cinematic_walk']:
        action=bpy.data.actions.get(clip)
        if action:
            action.name='previous_'+clip+'_reference';action.use_fake_user=True;references.append(action)
            if clip in report['clips']:report.setdefault('reference_clips',{})[clip]=report['clips'].pop(clip)
        for track in list(rig.animation_data.nla_tracks):
            if track.name==clip:rig.animation_data.nla_tracks.remove(track)
    rig.animation_data.action=None
    rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
    for file,clip,key in [('cbfm_walk_loop.fbx','ffxiv_cinematic_walk','event_walk_loop'),
                          ('cbfm_swalk_loop.fbx','intro_arrival','event_swalk_loop')]:
        input_path=QA/file
        if not input_path.exists():input_path=archive/file
        if input_path!=archive/file:shutil.copyfile(input_path,archive/file)
        before=set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=str(archive/file))
        added=set(bpy.data.objects)-before
        source=next(o for o in added if o.type=='ARMATURE')
        action=source.animation_data.action
        first,last=[int(x) for x in action.frame_range]
        source_rest_transform=source.matrix_world.copy()
        source_rest={b.name:source_rest_transform @ b.matrix_local for b in source.data.bones}
        sampled=[];contacts=[]
        for frame in range(first,last+1):
            bpy.context.scene.frame_set(frame)
            pose={name:(source.matrix_world @ source.pose.bones[name].matrix) @ source_rest[name].inverted() @ target
                  for name,target in rest.items() if name in source_rest}
            pose['n_root']=source.matrix_world @ source_rest_transform.inverted() @ rest['n_root']
            sampled.append(pose)
            contacts.append({side:list(pose['j_asi_d_'+side].translation) for side in ['l','r']})
        # Estimate the authored gait's forward speed from grounded foot phases.
        estimates=[]
        for side in ['l','r']:
            floor=min(f[side][2] for f in contacts)
            for a,b in zip(contacts,contacts[1:]):
                if max(a[side][2],b[side][2]) < floor+.012:
                    velocity=(b[side][1]-a[side][1])*30
                    if .05<velocity<2.5:estimates.append(velocity)
        estimates.sort()
        speed=estimates[len(estimates)//2] if estimates else .40
        baked=bpy.data.actions.new(clip);rig.animation_data.action=baked
        prior={};diagnostics=[]
        for frame,pose in enumerate(sampled):
            bpy.context.scene.frame_set(frame)
            for pb in rig.pose.bones:
                name=pb.name;parent=pb.parent.name if pb.parent else None
                parent_pose=pose[parent] if parent else Matrix.Identity(4)
                local_rest=rest[parent].inverted() @ rest[name] if parent else rest[name]
                pb.rotation_mode='QUATERNION'
                pb.matrix_basis=local_rest.inverted() @ parent_pose.inverted() @ pose[name]
                q=pb.rotation_quaternion.copy()
                if name in prior and q.dot(prior[name])<0:q.negate();pb.rotation_quaternion=q
                prior[name]=q
                pb.keyframe_insert('location',frame=frame,group=name)
                pb.keyframe_insert('rotation_quaternion',frame=frame,group=name)
                pb.keyframe_insert('scale',frame=frame,group=name)
            if frame in [0,len(sampled)//4,len(sampled)//2,len(sampled)-1]:
                diagnostics.append({'frame':frame,'left_hand':list(pose['j_te_l'].translation),
                    'right_hand':list(pose['j_te_r'].translation),'left_foot':list(pose['j_asi_d_l'].translation)})
        baked.use_fake_user=True
        track=rig.animation_data.nla_tracks.new();track.name=clip
        track.strips.new(clip,0,baked);track.mute=True
        report['clips'][clip]={'origin':'Original FFXIV cinematic slow walk' if clip=='intro_arrival' else 'Original FFXIV cinematic walk',
            'game_path':extraction[key]['game_path'],'motion_name':file.removesuffix('.fbx'),
            'pap_sha256':extraction[key]['sha256'],'duration':(last-first)/30,'frames':last-first+1,
            'native_bone_mapping':True,'loop':True,'forward_speed_native':speed,'samples':diagnostics}
        rig.animation_data.action=None
        for o in added:bpy.data.objects.remove(o,do_unlink=True)
        bpy.data.actions.remove(action,do_unlink=True)
        print('BAKED_NATIVE_FFXIV_WALK',clip,last-first+1,'speed',speed,flush=True)
    report['design']='Original burgundy restored'
    return references

def export_current():
    bpy.ops.wm.open_mainfile(filepath=str(ART/'fandaniel_mixamo.blend'))
    rig=bpy.data.objects['FandanielRig']
    report=json.loads((ART/'rig_report.json').read_text())
    # Replace embedded black images with the restored original color files.
    for suffix in ['d','e']:
        name=f'fandaniel_{suffix}_basecolor.png'
        for image in list(bpy.data.images):
            if image.name.startswith(name):
                replacement=bpy.data.images.load(str(OUT/name),check_existing=False)
                replacement.pack();image.user_remap(replacement)
                bpy.data.images.remove(image)
                replacement.name=name
    refs=bake_native_walks(rig,report)
    for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
    bpy.context.scene.frame_set(0)
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    for o in rig.children:
        if o.type=='MESH':o.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.wm.save_as_mainfile(filepath=str(ART/'fandaniel_mixamo.blend'))
    for ref in list(bpy.data.actions):
        if '_reference' in ref.name:bpy.data.actions.remove(ref,do_unlink=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT/'fandaniel_mixamo.glb'),use_selection=True,
        export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',
        export_nla_strips=True,export_def_bones=True,export_force_sampling=True,export_frame_range=False)
    (ART/'rig_report.json').write_text(json.dumps(report,indent=2))
    print('NATIVE_FFXIV_WALKS_EXPORTED',flush=True)

if __name__=='__main__':export_current()
