"""Author a restrained arrival on the preserved FFXIV skeleton and idle pose.

Only small global chest/neck/head adjustments; original limbs and foot contact
come from Idle, and continuous breathing remains throughout the camera shot.
"""
from pathlib import Path
import bpy,math,json
from mathutils import Matrix,Quaternion,Vector

ROOT=Path(__file__).resolve().parents[2]
FPS=30
DURATION=14.7

def smooth(a,b,t):
    x=max(0.0,min(1.0,(t-a)/(b-a)))
    return x*x*x*(x*(x*6-15)+10)

def bake_confident_arrival(rig,report):
    idle=bpy.data.actions['breathing_idle']
    reference=bpy.data.actions.get('intro_arrival')
    if reference:
        reference.name='mixamo_look_around_reference'
        reference.use_fake_user=True
    for track in list(rig.animation_data.nla_tracks):
        if track.name=='intro_arrival':rig.animation_data.nla_tracks.remove(track)
    old_report=report['clips'].get('intro_arrival')
    if old_report:report.setdefault('reference_clips',{})['mixamo_look_around']=old_report
    frames=round(DURATION*FPS)
    idle_start,idle_end=idle.frame_range
    # Sample first, so no newly inserted keys can contaminate the source idle.
    rig.animation_data.action=idle
    bases=[]
    for frame in range(frames+1):
        source=float(idle_start)+(frame % max(1,int(idle_end-idle_start)))
        bpy.context.scene.frame_set(int(source),subframe=source-int(source))
        bases.append({p.name:p.matrix_basis.copy() for p in rig.pose.bones})
    action=bpy.data.actions.new('intro_arrival')
    rig.animation_data.action=action
    rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
    diagnostics=[]
    for frame in range(frames+1):
        t=frame/FPS
        bpy.context.scene.frame_set(frame)
        for p in rig.pose.bones:p.matrix_basis=bases[frame][p.name]
        presence=smooth(.15,1.65,t)*(1-smooth(11.0,DURATION,t))
        deliberate=-math.radians(7.0)*smooth(2.1,4.4,t)*(1-smooth(6.7,9.0,t))
        breath=math.sin(t*math.tau/4.5)
        # He calmly raises his gaze, acknowledges the challenge and settles.
        # No scanning from side to side, gestures or exaggerated chest thrust.
        changes={
            'j_sebo_b':Quaternion((1,0,0),-.007*presence+.003*breath),
            'j_sebo_c':Quaternion((1,0,0),-.009*presence+.004*breath),
            'j_kubi':Quaternion((0,0,1),deliberate*.35) @ Quaternion((1,0,0),-.012*presence),
            'j_kao':Quaternion((0,0,1),deliberate*.65) @ Quaternion((1,0,0),-.018*presence)}
        for name,rotation in changes.items():
            p=rig.pose.bones[name]
            q=rest[name].to_quaternion()
            p.rotation_quaternion=q.inverted() @ rotation @ q @ p.rotation_quaternion
        for p in rig.pose.bones:
            p.rotation_mode='QUATERNION'
            p.keyframe_insert('location',frame=frame,group=p.name)
            p.keyframe_insert('rotation_quaternion',frame=frame,group=p.name)
        if frame in [0,45,132,270,frames]:
            bpy.context.view_layer.update()
            diagnostics.append({'time':t,'head':list(rig.pose.bones['j_kao'].matrix.translation),
                'left_foot':list(rig.pose.bones['j_asi_d_l'].matrix.translation),
                'right_foot':list(rig.pose.bones['j_asi_d_r'].matrix.translation)})
    action.use_fake_user=True
    track=rig.animation_data.nla_tracks.new();track.name='intro_arrival'
    track.strips.new('intro_arrival',0,action);track.mute=True
    rig.animation_data.action=None
    report['clips']['intro_arrival']={'origin':'Original restrained Queen\'s Trial arrival',
        'authoring':'tools/ffxiv/author_confident_arrival.py','duration':DURATION,
        'frames':frames+1,'continuous_idle_base':True,'samples':diagnostics}
    print('AUTHORED_CONFIDENT_ARRIVAL',DURATION,flush=True)
    return reference

if __name__=='__main__':
    art=ROOT/'art/characters/fandaniel'
    bpy.ops.wm.open_mainfile(filepath=str(art/'fandaniel_mixamo.blend'))
    report=json.loads((art/'rig_report.json').read_text())
    bake_confident_arrival(bpy.data.objects['FandanielRig'],report)
