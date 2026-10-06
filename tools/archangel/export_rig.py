"""Re-export the packed editable rig after authoring changes in Blender."""
from pathlib import Path
import json
import bpy

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'art'/'characters'/'archangel'
ASSETS=ROOT/'assets'/'models'/'characters'/'archangel'
bpy.ops.wm.open_mainfile(filepath=str(ART/'archangel_rig.blend'))
rig=bpy.data.objects['Archangel_Rig']
parts=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent==rig]
for part in parts:
    # Godot requires unique names for scene nodes and skeleton bones.
    if not part.name.endswith('Mesh'):
        part.name+='Mesh'
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
bpy.context.view_layer.objects.active=rig
for part in parts:
    part.select_set(True)
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
report=json.loads((ART/'rig_report.json').read_text())
report['parts']={p.name:len(p.data.polygons) for p in parts}
(ART/'rig_report.json').write_text(json.dumps(report,indent=2))
print('EXPORT_COMPLETE',flush=True)
