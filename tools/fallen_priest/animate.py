"""Author and bake confident locomotion, a portal entrance and grounded reactions.

Uses analytic two-bone leg IK during authoring. The game receives ordinary baked
bone tracks; the accepted meshes, skin and physical cape cage stay intact.
Run Blender --background --python tools/fallen_priest/animate.py to re-export.
"""
from pathlib import Path
import math, json
import bpy
from mathutils import Vector, Quaternion, Matrix

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'art/characters/fallen_priest'
OUT = ROOT / 'assets/models/characters/fallen_priest'
FPS = 30


def smooth(a, b, t):
    f = min(1.0, max(0.0, (t-a)/(b-a)))
    return f*f*(3-2*f)


def build_actions(rig):
    rest = {b.name: b.matrix_local.copy() for b in rig.data.bones}
    body_names = [b.name for b in rig.data.bones if not b.name.startswith('Cape')]
    lengths = {b.name: b.length for b in rig.data.bones}
    for track in list(rig.animation_data.nla_tracks) if rig.animation_data else []:
        rig.animation_data.nla_tracks.remove(track)
    rig.animation_data_create()
    rig.animation_data.action = None
    for action in list(bpy.data.actions):
        if action.name in ['breathing_idle','walk','intro_arrival','intro_looking','standing_death','left_slide','right_slide','left_fall','right_fall','left_recover','right_recover']:
            bpy.data.actions.remove(action)

    def reset():
        for p in rig.pose.bones:
            p.rotation_mode = 'QUATERNION'
            p.rotation_quaternion = Quaternion()
            p.location = (0,0,0)
            p.scale = (1,1,1)

    def rotate(name, axis, angle, additive=False):
        q = rest[name].to_quaternion()
        rotation = q.inverted() @ Quaternion(axis, angle) @ q
        p = rig.pose.bones[name]
        p.rotation_quaternion = rotation @ p.rotation_quaternion if additive else rotation

    def translate(name, position):
        rig.pose.bones[name].location = rest[name].to_3x3().inverted() @ Vector(position)

    def aim(name, head, target):
        direction = Vector(target)-Vector(head)
        original = rest[name].to_3x3() @ Vector((0,1,0))
        rotation = original.rotation_difference(direction.normalized())
        rig.pose.bones[name].matrix = Matrix.Translation(head) @ rotation.to_matrix().to_4x4() @ rest[name].to_3x3().to_4x4()

    def leg(side, ankle, pole=(0,-1,0), pitch=0.0):
        thigh, shin, foot = ['Thigh_'+side,'Shin_'+side,'Foot_'+side]
        pelvis = rig.pose.bones['Pelvis'].matrix @ rest['Pelvis'].inverted()
        hip = pelvis @ rest[thigh].translation
        ankle = Vector(ankle)
        direction = ankle-hip
        distance = min(direction.length, lengths[thigh]+lengths[shin]-.001)
        distance = max(distance, abs(lengths[thigh]-lengths[shin])+.001)
        n = direction.normalized()
        along = (lengths[thigh]**2-lengths[shin]**2+distance**2)/(2*distance)
        height = math.sqrt(max(0,lengths[thigh]**2-along**2))
        bend = Vector(pole)-n*Vector(pole).dot(n)
        if bend.length < .001: bend = Vector((0,-1,0))
        knee = hip+n*along+bend.normalized()*height
        # Preserve the requested ankle even when the target is slightly beyond
        # maximum reach by moving it onto the reachable sphere, never scaling.
        ankle = hip+n*distance
        aim(thigh, hip, knee)
        bpy.context.view_layer.update()
        aim(shin, knee, ankle)
        bpy.context.view_layer.update()
        rig.pose.bones[foot].matrix = Matrix.Translation(ankle) @ Quaternion((1,0,0),pitch).to_matrix().to_4x4() @ rest[foot].to_3x3().to_4x4()

    def arm(side, wrist, pole, weight=1.0, palm_forward=True):
        upper, fore, hand = ['UpperArm_'+side,'Forearm_'+side,'Hand_'+side]
        starts = {name:(rig.pose.bones[name].rotation_quaternion.copy(),rig.pose.bones[name].location.copy()) for name in [upper,fore,hand]}
        parent_name = rig.data.bones[upper].parent.name
        motion = rig.pose.bones[parent_name].matrix @ rest[parent_name].inverted()
        shoulder = motion @ rest[upper].translation
        wrist = Vector(wrist)
        direction = wrist-shoulder
        distance = min(direction.length,lengths[upper]+lengths[fore]-.001)
        distance = max(distance,abs(lengths[upper]-lengths[fore])+.001)
        n = direction.normalized()
        along = (lengths[upper]**2-lengths[fore]**2+distance**2)/(2*distance)
        height = math.sqrt(max(0,lengths[upper]**2-along**2))
        bend = Vector(pole)-n*Vector(pole).dot(n)
        elbow = shoulder+n*along+bend.normalized()*height
        wrist = shoulder+n*distance
        aim(upper,shoulder,elbow)
        bpy.context.view_layer.update()
        aim(fore,elbow,wrist)
        bpy.context.view_layer.update()
        aim(hand,wrist,wrist+Vector((0,-.13,0) if palm_forward else (0,0,-.13)))
        for name,(rotation,location) in starts.items():
            p = rig.pose.bones[name]
            p.rotation_quaternion = rotation.slerp(p.rotation_quaternion,weight)
            p.location = location.lerp(p.location,weight)

    def gait(t, cycle, stride=.34, slow=False, strength=1.0):
        phase = t*math.tau/cycle
        translate('Pelvis',(.012*math.sin(phase),0,(-.035+.012*math.cos(phase*2))*strength))
        rotate('Pelvis',(0,0,1),.023*math.sin(phase)*strength)
        rotate('Chest',(0,0,1),-.016*math.sin(phase)*strength)
        rotate('Spine',(1,0,0),.018*strength)
        bpy.context.view_layer.update()
        for side,s in [('L',1),('R',-1)]:
            p = (t/cycle+(0 if s>0 else .5)) % 1.0
            if p < .64:
                alpha = p/.64
                y = -stride*.5+stride*alpha
                z = .13
                pitch = -.10*(1-smooth(0,.18,alpha))+.16*smooth(.80,1,alpha)
            else:
                alpha = (p-.64)/.36
                blend = smooth(0,1,alpha)
                y = stride*.5-stride*blend
                z = .13+(.058 if slow else .085)*math.sin(math.pi*alpha)
                pitch = -.09*math.sin(math.pi*alpha)
            ankle = (s*.205, y*strength, .13+(z-.13)*strength)
            leg(side, ankle, pitch=pitch*strength)
            rotate('UpperArm_'+side,(1,0,0),-.09*math.sin(phase+(0 if s>0 else math.pi))*strength)
            rotate('Forearm_'+side,(1,0,0),-.055*strength)
            rotate('Hand_'+side,(0,0,1),s*.015*strength)
        rotate('Tabard01',(1,0,0),.016*math.sin(phase-.45)*strength)
        rotate('Tabard02',(1,0,0),.025*math.sin(phase-.8)*strength)

    def brace(strength, direction, reach=1.0):
        # Anatomical left is screen-right's opposite when the model faces -Z.
        heavy = -direction
        translate('Pelvis',(direction*.055*strength,-.08*strength,-.55*strength))
        rotate('Pelvis',(0,1,0),direction*.07*strength)
        rotate('Spine',(1,0,0),.38*strength)
        rotate('Chest',(0,1,0),direction*.13*strength)
        rotate('Neck',(1,0,0),-.16*strength)
        rotate('Head',(0,0,1),direction*.055*strength)
        bpy.context.view_layer.update()
        for side,s in [('L',1),('R',-1)]:
            ankle = (s*(.205+.10*strength), (.40 if s==heavy else -.24)*strength, .13)
            leg(side, ankle, pitch=(.65 if s==heavy else 0)*strength)
            # One hand lowers toward the surface; the uphill arm counterbalances.
            rotate('UpperArm_'+side,(0,1,0),s*(.05 if s==heavy else -.24)*strength)
            rotate('UpperArm_'+side,(1,0,0),(.23 if s==heavy else -.18)*strength,True)
            rotate('Forearm_'+side,(1,0,0),(-.12 if s==heavy else -.36)*strength)
            rotate('Hand_'+side,(1,0,0),(.30 if s==heavy else -.08)*strength)
        # The uphill hand rests on the raised knee rather than hanging limp.
        if strength > .25:
            bpy.context.view_layer.update()
            side = 'L' if heavy < 0 else 'R'
            s = -heavy
            arm(side,(s*.30,-.31,.72),(s,.1,-.2),smooth(.25,.65,strength))
        rotate('Tabard01',(1,0,0),-.22*strength)
        rotate('Tabard02',(1,0,0),.30*strength)

    def pose(t, mode, d=1):
        reset()
        phase = t*math.tau/4.8
        rotate('Chest',(1,0,0),.009*math.sin(phase))
        rotate('Head',(0,0,1),.007*math.sin(phase-.5))
        if mode == 'walk': gait(t,1.1,.40)
        if mode == 'intro':
            settle = 1-smooth(10.8,12.4,t)
            gait(t+.20,3.2,.36,True,settle)
            # First deliberate step leaves the portal before the shoulders.
            if t < 2.4:
                lead = smooth(0,.9,t)
                plant = smooth(.65,1.3,t)
                leg('R',(-.205,-.33*lead,.13+.085*math.sin(math.pi*min(t/1.3,1))),pitch=-.10*(1-plant))
                leg('L',(.205,.12*lead,.13),pitch=.07*lead)
            look = .31*smooth(3.3,4.8,t)-.64*smooth(6.2,7.7,t)+.33*smooth(9.2,10.6,t)
            rotate('Head',(0,0,1),look)
            rotate('Neck',(0,0,1),look*.23)
            rotate('Chest',(0,0,1),look*.12,True)
            rotate('Head',(1,0,0),-.035)
        if mode == 'slide':
            strength = .20*smooth(0,.30,t)+.80*smooth(.32,1.25,t)
            brace(strength,d)
            # A controlled weight shift, then a sustained kneeling brace.
            rotate('Chest',(0,0,1),d*.025*math.sin(t*3.0)*smooth(0,.3,t),True)
        if mode == 'recover':
            brace(1-smooth(0,1.0,t),d)
        if mode == 'fall':
            brace(1.0,d)
            release = smooth(.04,.40,t)
            translate('Pelvis',(d*.055,-.08,-.55+.18*release))
            rotate('Spine',(1,0,0),.38-.22*release)
            heavy = -d
            for side,s in [('L',1),('R',-1)]:
                # The hand reaches back to the lost edge; legs fold with delay.
                arm_starts = {name:rig.pose.bones[name+'_'+side].rotation_quaternion.copy() for name in ['UpperArm','Forearm']}
                rotate('UpperArm_'+side,(0,1,0),(-s*.78 if s==heavy else -s*.38)*release)
                rotate('UpperArm_'+side,(1,0,0),(-.35 if s==heavy else .15)*release,True)
                rotate('Forearm_'+side,(1,0,0),(-.34 if s==heavy else -.65)*release)
                for name,start in arm_starts.items():
                    p = rig.pose.bones[name+'_'+side]
                    p.rotation_quaternion = start.slerp(p.rotation_quaternion,release)
                thigh_start = rig.pose.bones['Thigh_'+side].rotation_quaternion.copy()
                shin_start = rig.pose.bones['Shin_'+side].rotation_quaternion.copy()
                foot_start = rig.pose.bones['Foot_'+side].rotation_quaternion.copy()
                rotate('Thigh_'+side,(1,0,0),(.56 if s==heavy else .20)*smooth(.18,.70,t))
                rotate('Shin_'+side,(1,0,0),(-1.10 if s==heavy else -.65)*smooth(.20,.75,t))
                rotate('Foot_'+side,(1,0,0),-.10*release)
                limb_release = smooth(.05,.48,t)
                for bone_name, start in [('Thigh_'+side,thigh_start),('Shin_'+side,shin_start),('Foot_'+side,foot_start)]:
                    p = rig.pose.bones[bone_name]
                    p.rotation_quaternion = start.slerp(p.rotation_quaternion,limb_release)
            rotate('Neck',(1,0,0),-.16+.10*release)
            rotate('Head',(0,0,1),d*.08*release)
        if mode == 'death':
            buckle = smooth(0,.72,t)
            fold = smooth(.58,1.55,t)
            settle = smooth(1.45,2.15,t)
            translate('Pelvis',(.035*buckle,-.15*fold,-.55*buckle-.43*fold))
            rotate('Pelvis',(1,0,0),1.48*fold)
            rotate('Spine',(1,0,0),.22*buckle*(1-fold)+.04*fold)
            rotate('Chest',(1,0,0),.04*fold)
            rotate('Head',(0,0,1),-.14*fold)
            bpy.context.view_layer.update()
            for side,s in [('L',1),('R',-1)]:
                leg(side,(s*(.205+.025*buckle),.72*fold,.13),pole=(0,0,1) if fold>.4 else (0,-1,0),pitch=.28*fold)
                rotate('UpperArm_'+side,(1,0,0),(-.48 if s>0 else -.26)*fold)
                rotate('UpperArm_'+side,(0,1,0),-s*.18*fold,True)
                rotate('Forearm_'+side,(1,0,0),(-.30 if s>0 else -.55)*fold)
                rotate('Hand_'+side,(1,0,0),-.16*fold)
            if fold > .5:
                bpy.context.view_layer.update()
                for side,s in [('L',1),('R',-1)]:
                    arm(side,(s*.40,-.95,.10),(s,.2,.05),smooth(.5,.85,fold))
            # A small rebound finishes into stillness, without looping the fall.
            translate('Pelvis',(.035*buckle,-.15*fold,-.55*buckle-.43*fold+.022*math.sin((t-1.45)*math.pi/.70)*(1-settle) if t>1.45 else -.55*buckle-.43*fold))
            rotate('Tabard01',(1,0,0),-.22*fold)
            rotate('Tabard02',(1,0,0),.35*fold)

    clips = [('breathing_idle',4.8,'idle',1),('walk',1.1,'walk',1),('intro_arrival',12.4,'intro',1),('standing_death',2.6,'death',1)]
    for side,d in [('left',-1),('right',1)]:
        clips += [(side+'_slide',2.4,'slide',d),(side+'_fall',1.7,'fall',d),(side+'_recover',1.0,'recover',d)]
    meshes = [o for o in rig.children if o.type == 'MESH']
    for o in meshes: o.hide_viewport=True
    bpy.context.scene.render.fps = FPS
    diagnostics = {}
    for name,seconds,mode,direction in clips:
        action = bpy.data.actions.new(name)
        rig.animation_data.action=action
        frames=round(seconds*FPS)
        for frame in range(frames+1):
            bpy.context.scene.frame_set(frame+1)
            pose(frame/FPS,mode,direction)
            for n in body_names:
                p = rig.pose.bones[n]
                p.keyframe_insert('rotation_quaternion',frame=frame+1,group=n)
                p.keyframe_insert('location',frame=frame+1,group=n)
            if frame in [0,frames//2,frames]:
                bpy.context.view_layer.update()
                diagnostics.setdefault(name,[]).append({'frame':frame,'pelvis':list(rig.pose.bones['Pelvis'].matrix.translation),'left_ankle':list(rig.pose.bones['Foot_L'].matrix.translation),'right_ankle':list(rig.pose.bones['Foot_R'].matrix.translation)})
        action.use_fake_user=True
        track=rig.animation_data.nla_tracks.new(); track.name=name
        track.strips.new(name,1,action); track.mute=True
        print('BAKED_PRIEST_CLIP',name,frames+1,flush=True)
    rig.animation_data.action=None
    reset()
    bpy.context.scene.frame_set(1)
    for o in meshes: o.hide_viewport=False
    (ART/'animation_report.json').write_text(json.dumps(diagnostics,indent=2))
    return clips


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(ART/'fallen_priest_rig.blend'))
    rig = bpy.data.objects['PriestRig']
    clips = build_actions(rig)
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    for part in rig.children:
        if part.type=='MESH': part.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.wm.save_as_mainfile(filepath=str(ART/'fallen_priest_rig.blend'))
    bpy.ops.export_scene.gltf(filepath=str(OUT/'fallen_priest_rig.glb'),use_selection=True,export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_nla_strips=True,export_def_bones=True,export_force_sampling=True)
    report=json.loads((ART/'rig_report.json').read_text())
    report['clips']=[c[0] for c in clips]
    (ART/'rig_report.json').write_text(json.dumps(report,indent=2))
    print('PRIEST_ANIMATIONS_EXPORTED',flush=True)
