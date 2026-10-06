"""Bake the user's six Mixamo clips onto the complete Priest and cloth rig.

Run in Blender --background --factory-startup. Source sculpt/skin/cape stay intact.
Mixamo's upload is an A-pose and the game sculpt has lowered arms: limbs must
follow the sampled anatomical directions, rather than copy local Euler angles.
"""
from pathlib import Path
import bpy, json, math, hashlib
from mathutils import Matrix, Vector, Quaternion

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/characters/fallen_priest'
OUT = ROOT / 'assets/models/characters/fallen_priest'
DOWNLOADS = Path.home() / 'Downloads'
CLIPS = {'Idle': 'breathing_idle', 'Walking': 'walk', 'Look Around': 'intro_arrival',
         'Standing React Death Forward': 'standing_death',
         'Left Strafe': 'left_slide', 'Right Strafe': 'right_slide'}
MAP = {'Pelvis': 'Hips', 'Spine': 'Spine1', 'Chest': 'Spine2', 'Neck': 'Neck', 'Head': 'Head'}
for side, label in [('L', 'Left'), ('R', 'Right')]:
    MAP.update({f'{target}_{side}': label+source for target, source in [
        ('Clavicle','Shoulder'), ('UpperArm','Arm'), ('Forearm','ForeArm'),
        ('Hand','Hand'), ('Thigh','UpLeg'), ('Shin','Leg'), ('Foot','Foot')]})

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

bpy.ops.wm.open_mainfile(filepath=str(ART / 'fallen_priest_rig.blend'))
rig = bpy.data.objects['PriestRig']
meshes = [o for o in rig.children if o.type == 'MESH']
for o in meshes: o.hide_viewport = True
rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}
body = [b.name for b in rig.data.bones if not b.name.startswith('Cape')]
for track in list(rig.animation_data.nla_tracks):
    if track.name in CLIPS.values(): rig.animation_data.nla_tracks.remove(track)
rig.animation_data.action = None
for action in list(bpy.data.actions):
    if action.name in CLIPS.values(): bpy.data.actions.remove(action)
report = {'source': 'Adobe Mixamo downloads supplied by user', 'fps': 30, 'clips': {},
          'cape_cage_sha256': digest(OUT / 'cape_cage.json'),
          'preserved_meshes': {o.name: len(o.data.vertices) for o in meshes}}
align = Matrix.Rotation(math.pi/2, 4, 'X')
bpy.context.scene.render.fps = 30

for source_name, clip in CLIPS.items():
    archive = ART / 'mixamo' / 'animations' / (source_name+'.fbx')
    path = DOWNLOADS / archive.name
    if not path.exists(): path = archive
    archive.parent.mkdir(parents=True, exist_ok=True)
    archive.write_bytes(path.read_bytes())
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(archive))
    imported = set(bpy.data.objects) - before
    source = next(o for o in imported if o.type == 'ARMATURE')
    action = source.animation_data.action
    start, end = (int(x) for x in action.frame_range)
    source_rest = {n: align @ source.data.bones['mixamorig:'+n].matrix_local for n in MAP.values()}
    # Keep only roll correction. Transferring A-pose swing would cross the arms.
    corrections = {}
    for target, n in MAP.items():
        sq = source_rest[n].to_quaternion()
        tq = rest[target].to_quaternion()
        swing = (sq @ Vector((0,1,0))).rotation_difference(tq @ Vector((0,1,0)))
        corrections[target] = (swing @ sq).inverted() @ tq
    scale = rest['Pelvis'].translation.z / source_rest['Hips'].translation.z
    bpy.context.scene.frame_set(start)
    first = (align @ source.pose.bones['mixamorig:Hips'].matrix).translation.copy()
    bpy.context.scene.frame_set(end)
    last = (align @ source.pose.bones['mixamorig:Hips'].matrix).translation.copy()
    drift = last - first
    loop = clip in ['breathing_idle','walk','left_slide','right_slide']
    baked = bpy.data.actions.new(clip)
    rig.animation_data.action = baked
    previous_quaternions = {}
    samples = []
    for frame in range(start, end+1):
        bpy.context.scene.frame_set(frame)
        sampled = {n: align @ source.pose.bones['mixamorig:'+n].matrix for n in MAP.values()}
        hips = sampled['Hips'].translation - source_rest['Hips'].translation
        if loop:
            progress = (frame-start)/max(1,end-start)
            hips.x -= first.x-source_rest['Hips'].translation.x + drift.x*progress
            hips.y -= first.y-source_rest['Hips'].translation.y + drift.y*progress
        desired = {}
        for name in body:
            pb = rig.pose.bones[name]
            pb.rotation_mode = 'QUATERNION'
            parent = pb.parent.name if pb.parent else None
            local_rest = rest[parent].inverted() @ rest[name] if parent else rest[name]
            parent_pose = desired[parent] if parent else Matrix.Identity(4)
            inherited = parent_pose @ local_rest
            if name == 'Pelvis':
                position = rest[name].translation + hips*scale
            else:
                position = inherited.translation
            if name in MAP:
                rotation = sampled[MAP[name]].to_quaternion() @ corrections[name]
                matrix = Matrix.Translation(position) @ rotation.to_matrix().to_4x4()
            else:
                matrix = inherited
            basis = local_rest.inverted() @ parent_pose.inverted() @ matrix
            pb.matrix_basis = basis
            # Equivalent quaternion signs must not flip between baked frames.
            q = pb.rotation_quaternion.copy()
            if name in previous_quaternions and q.dot(previous_quaternions[name]) < 0:
                q.negate()
                pb.rotation_quaternion = q
            previous_quaternions[name] = q
            desired[name] = matrix
        bpy.context.view_layer.update()
        # Preserve ground contact despite the small difference in leg lengths.
        contacts = []
        for side in ['L','R']:
            contacts.extend([desired['Foot_'+side].translation,
                             desired['Foot_'+side] @ Vector((0,rig.data.bones['Foot_'+side].length,0))])
        if clip == 'standing_death':
            contacts.extend(desired[n].translation-Vector((0,0,.045)) for n in ['Head','Chest','Hand_L','Hand_R'])
        correction = max(0.0, .012-min(p.z for p in contacts))
        if correction:
            pb = rig.pose.bones['Pelvis']
            pb.location += rest['Pelvis'].to_3x3().inverted() @ Vector((0,0,correction))
        # The front cloth inherits hips and follows the leg swing with restraint.
        thigh_pitch = sum(rig.pose.bones['Thigh_'+s].rotation_quaternion.to_euler().x for s in ['L','R'])/2
        for name, amount in [('Tabard01',.16), ('Tabard02',.24)]:
            qrest = rest[name].to_quaternion()
            rig.pose.bones[name].rotation_quaternion = qrest.inverted() @ Quaternion((1,0,0),max(-.28,min(.28,thigh_pitch*amount))) @ qrest
        output_frame = frame-start+1
        for name in body:
            pb = rig.pose.bones[name]
            pb.keyframe_insert('location',frame=output_frame,group=name)
            pb.keyframe_insert('rotation_quaternion',frame=output_frame,group=name)
        if frame in [start,(start+end)//2,end]:
            bpy.context.view_layer.update()
            samples.append({'frame': output_frame, 'bones': {n:list(rig.pose.bones[n].matrix.translation) for n in ['Pelvis','Head','Foot_L','Foot_R','Hand_L','Hand_R']}})
    baked.use_fake_user = True
    track = rig.animation_data.nla_tracks.new()
    track.name = clip
    track.strips.new(clip,1,baked)
    track.mute = True
    report['clips'][clip] = {'file': str(archive.relative_to(ROOT)), 'sha256':digest(archive),
        'duration':(end-start)/30, 'frames':end-start+1, 'loop':loop,
        'removed_root_drift':list(drift) if loop else [0,0,0], 'samples':samples}
    rig.animation_data.action = None
    for obj in imported: bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.actions.remove(action, do_unlink=True)
    print('IMPORTED_MIXAMO_CLIP',clip,end-start+1,flush=True)

for pb in rig.pose.bones: pb.matrix_basis = Matrix.Identity(4)
for obj in meshes: obj.hide_viewport=False
bpy.context.scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
for obj in meshes: obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.wm.save_as_mainfile(filepath=str(ART / 'fallen_priest_mixamo.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT / 'fallen_priest_mixamo.glb'),use_selection=True,
    export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',
    export_nla_strips=True,export_def_bones=True,export_force_sampling=True)
(ART / 'mixamo/animation_import_report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('MIXAMO_PRIEST_EXPORTED',flush=True)
