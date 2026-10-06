"""Validate the actual Blender skin, shared seams and accessory rigidity."""
from pathlib import Path
import json
import bpy
import numpy as np
from mathutils import Quaternion, Vector

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art'/'characters'/'archangel'
bpy.ops.wm.open_mainfile(filepath=str(ART/'archangel_rig.blend'))
rig=bpy.data.objects['Archangel_Rig']
parts=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==rig]
for track in rig.animation_data.nla_tracks:
    track.mute=True
rig['arm_ik']=0.0
rig['leg_ik']=0.0

def coordinates(mesh):
    result=np.empty(len(mesh.vertices)*3,dtype=np.float32)
    mesh.vertices.foreach_get('co',result)
    return result.reshape(-1,3)

original={p.name:coordinates(p.data) for p in parts}
shared={}
missing=0
maximum_influences=0
error=0
for part in parts:
    for vertex in part.data.vertices:
        influences=[g for g in vertex.groups if g.weight>0]
        maximum_influences=max(maximum_influences,len(influences))
        total=sum(g.weight for g in influences)
        missing+=int(total==0)
        error=max(error,abs(total-1))
        shared.setdefault(tuple(vertex.co),[]).append((part.name,vertex.index))
shared=[group for group in shared.values() if len(group)>1]
assert missing==0
assert maximum_influences<=4
assert error<1e-5

tests={}
depsgraph=bpy.context.evaluated_depsgraph_get()
for action_name,frame in [('rig_pose_test',61),('wing_flex_test',31),('wing_flex_test',91),('intro_presence',121)]:
    rig.animation_data.action=bpy.data.actions[action_name]
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    posed={}
    stretches={}
    for part in parts:
        evaluated=part.evaluated_get(depsgraph)
        mesh=evaluated.to_mesh()
        posed[part.name]=coordinates(mesh)
        faces=np.empty(len(mesh.polygons)*3,dtype=np.int32)
        mesh.polygons.foreach_get('vertices',faces)
        faces=faces.reshape(-1,3)
        a,b=faces[:,0],faces[:,1]
        rest=original[part.name]
        lengths=np.linalg.norm(rest[a]-rest[b],axis=1)
        now=np.linalg.norm(posed[part.name][a]-posed[part.name][b],axis=1)
        ratio=now[lengths>1e-5]/lengths[lengths>1e-5]
        stretches[part.name]={'p99_edge_ratio':float(np.quantile(ratio,.99)), 'max_edge_ratio':float(ratio.max())}
        evaluated.to_mesh_clear()
    seam_error=0
    worst=None
    for copies in shared:
        reference=posed[copies[0][0]][copies[0][1]]
        for name,index in copies[1:]:
            difference=float(np.linalg.norm(posed[name][index]-reference))
            if difference>seam_error:
                seam_error=difference
                worst=(copies[0],(name,index))
    if seam_error>=1e-5:
        print('WORST_SEAM',worst,flush=True)
        for name,index in worst:
            obj=bpy.data.objects[name]
            print('SEAM_WEIGHTS',name,index,original[name][index],[(obj.vertex_groups[g.group].name,g.weight) for g in obj.data.vertices[index].groups],flush=True)
    assert seam_error<1e-5,(action_name,seam_error)
    # Rigid armor accessories should follow their bone without stretching.
    for name in ['SwordMesh','HaloMesh']:
        assert abs(stretches[name]['p99_edge_ratio']-1)<.001,(name,stretches[name])
    tests[action_name+':'+str(frame)]={'seam_error':seam_error,'edge_stretch':stretches}

# Master controls genuinely affect the two wing roots.
rig.animation_data.action=None
for bone in rig.pose.bones:
    bone.rotation_quaternion=Quaternion()
    bone.location=Vector((0,0,0))
bpy.context.view_layer.update()
start=rig.pose.bones['WingUpper03_L'].matrix.translation.copy()
rig.pose.bones['CTRL_Wing_L'].rotation_quaternion=Quaternion((0,0,1),.2)
bpy.context.view_layer.update()
control_motion=(rig.pose.bones['WingUpper03_L'].matrix.translation-start).length
assert control_motion>.02
rig.pose.bones['CTRL_Wing_L'].rotation_quaternion=Quaternion()
rig['arm_ik']=1.0
rig['leg_ik']=1.0
rig.pose.bones['CTRL_Hand_L'].location=Vector((.025,-.045,0))
rig.pose.bones['CTRL_Foot_L'].location=Vector((.02,-.025,0))
rig.update_tag()
bpy.context.view_layer.update()
ik_errors={}
for bone,control in [('Forearm_L','CTRL_Hand_L'),('Shin_L','CTRL_Foot_L')]:
    ik_errors[bone]=(rig.pose.bones[bone].tail-rig.pose.bones[control].head).length
    assert ik_errors[bone]<.015,(bone,ik_errors[bone])
report={'unweighted_vertices':missing,'max_influences':maximum_influences,
        'max_weight_error':error,'shared_seam_vertices':len(shared),
        'wing_master_motion':control_motion,'ik_target_errors':ik_errors,'pose_checks':tests}
(ART/'validation_report.json').write_text(json.dumps(report,indent=2))
print('RIG_VALIDATION',json.dumps(report),flush=True)
