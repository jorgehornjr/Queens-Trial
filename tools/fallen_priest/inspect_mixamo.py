"""Inspect supplied Mixamo animation coordinates against the preserved game rig."""
import bpy, json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'art/characters/fallen_priest/fallen_priest_rig.blend'))
rig = bpy.data.objects['PriestRig']
def describe(r):
    return {'name': r.name, 'matrix': [list(row) for row in r.matrix_world], 'bones': [
        {'name': b.name, 'parent': b.parent.name if b.parent else None,
         'head': list(b.head_local), 'tail': list(b.tail_local), 'rotation': list(b.matrix_local.to_quaternion())}
        for b in r.data.bones if not b.name.startswith('Cape')]}
report = {'target': describe(rig), 'meshes': []}
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        report['meshes'].append({'name': obj.name, 'bounds': [list(v) for v in obj.bound_box]})
for name in ['Idle', 'Walking', 'Look Around', 'Standing React Death Forward', 'Left Strafe', 'Right Strafe']:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=str(Path.home() / 'Downloads' / (name+'.fbx')))
    added = set(bpy.data.objects) - before
    source = next(o for o in added if o.type == 'ARMATURE')
    entry = describe(source)
    action = source.animation_data.action
    entry['action'] = action.name
    entry['frames'] = list(action.frame_range)
    entry['fps'] = bpy.context.scene.render.fps
    entry['samples'] = []
    for f in [1, int(action.frame_range.y / 2), int(action.frame_range.y)]:
        bpy.context.scene.frame_set(f)
        entry['samples'].append({'frame': f, 'bones': {n: {
            'scale': list(source.pose.bones['mixamorig:'+n].scale),
            'local': list(source.pose.bones['mixamorig:'+n].location),
            'head': list(source.pose.bones['mixamorig:'+n].matrix.translation),
            'world': list(source.matrix_world @ source.pose.bones['mixamorig:'+n].matrix.translation),
            'rotation': list(source.pose.bones['mixamorig:'+n].matrix.to_quaternion())}
            for n in ['Hips', 'LeftArm', 'LeftFoot', 'Head']}})
    report[name] = entry
    for o in added: bpy.data.objects.remove(o, do_unlink=True)
out = ROOT / '.godot/qa/mixamo_inspection.json'
out.write_text(json.dumps(report, indent=2))
print('MIXAMO_INSPECTION', out)
