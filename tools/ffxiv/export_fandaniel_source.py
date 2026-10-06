"""Re-export the editable character, omitting historical reference actions."""
from pathlib import Path
import bpy
from mathutils import Matrix
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/characters/fandaniel/fandaniel_mixamo.blend'))
rig=bpy.data.objects['FandanielRig'];rig.animation_data.action=None
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for obj in rig.children:
    if obj.type=='MESH':obj.select_set(True)
bpy.context.view_layer.objects.active=rig
for action in list(bpy.data.actions):
    if '_reference' in action.name:bpy.data.actions.remove(action,do_unlink=True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/characters/fandaniel/fandaniel_mixamo.glb'),use_selection=True,
    export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_nla_strips=True,
    export_def_bones=True,export_force_sampling=True,export_frame_range=False)
print('CLEAN_ACTIVE_CHARACTER_EXPORTED')
