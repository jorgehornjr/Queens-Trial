"""Blender background: inspect and prepare an untouched-texture working mesh."""
from pathlib import Path
import bpy
import json
import numpy as np
import zipfile
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / '.godot' / 'qa'
SOURCE = QA / 'priest_source'
if not list(SOURCE.glob('*.fbx')):
    archive = Path.home()/'Downloads'/'corrupted-fallen-priest-dark-fantasy'/'source'/'Zyklus4_Zeile1.zip'
    SOURCE.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(archive) as package:
        for entry in package.infolist():
            if not (SOURCE/entry.filename).resolve().is_relative_to(SOURCE.resolve()):
                raise ValueError('Unsafe source archive path')
        package.extractall(SOURCE)
FBX = next(SOURCE.glob('*.fbx'))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.fbx(filepath=str(FBX), use_image_search=True)
obj = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
coords = np.empty(len(obj.data.vertices)*3, dtype=np.float32)
obj.data.vertices.foreach_get('co', coords)
coords = coords.reshape(-1,3)
print('IMPORTED_BOUNDS', coords.min(0), coords.max(0), flush=True)
obj.scale *= 2.2 / (coords[:,2].max()-coords[:,2].min())
obj.location.z = -coords[:,2].min() * obj.scale.z
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
obj.name = 'Priest_Working'
modifier = obj.modifiers.new('Game mesh simplification', 'DECIMATE')
modifier.ratio = 0.08
modifier.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=modifier.name)
for poly in obj.data.polygons:
    poly.use_smooth = True

material = bpy.data.materials.new('Priest_Surface')
material.use_nodes = True
nodes = material.node_tree.nodes
links = material.node_tree.links
shader = nodes.get('Principled BSDF')
for name, socket in [('basecolor','Base Color'), ('roughness','Roughness'), ('metallic','Metallic')]:
    image = bpy.data.images.load(str(next(SOURCE.rglob('*_'+name+'.JPEG'))), check_existing=True)
    if name != 'basecolor':
        image.colorspace_settings.name = 'Non-Color'
    tex = nodes.new('ShaderNodeTexImage')
    tex.image = image
    links.new(tex.outputs['Color'], shader.inputs[socket])
normal = nodes.new('ShaderNodeTexImage')
normal.image = bpy.data.images.load(str(next(SOURCE.rglob('*_normal.JPEG'))), check_existing=True)
normal.image.colorspace_settings.name = 'Non-Color'
normal_map = nodes.new('ShaderNodeNormalMap')
links.new(normal.outputs['Color'], normal_map.inputs['Color'])
links.new(normal_map.outputs['Normal'], shader.inputs['Normal'])
obj.data.materials.clear()
obj.data.materials.append(material)
coords = np.empty(len(obj.data.vertices)*3, dtype=np.float32)
obj.data.vertices.foreach_get('co', coords)
coords = coords.reshape(-1,3)
triangles = np.empty(len(obj.data.polygons)*3, dtype=np.int32)
obj.data.polygons.foreach_get('vertices',triangles)
triangles = triangles.reshape(-1,3)
np.savez_compressed(QA/'priest_mesh.npz', vertices=coords, faces=triangles)
print('PREPARED', len(obj.data.vertices), len(obj.data.polygons), coords.min(0), coords.max(0),flush=True)
bpy.ops.wm.save_as_mainfile(filepath=str(QA/'priest_prepared.blend'))

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.render.resolution_x = 1100
scene.render.resolution_y = 1100
scene.render.resolution_percentage = 100
scene.world.color = (0.18,0.18,0.18)
for name, location, power, size in [('Key',(-3,-4,5),550,4),('Fill',(3,-2,3),350,3),('Rim',(0,4,4),750,3)]:
    light = bpy.data.lights.new(name,'AREA')
    light.energy = power
    light.shape = 'DISK'
    light.size = size
    node = bpy.data.objects.new(name,light)
    scene.collection.objects.link(node)
    node.location = location
    node.rotation_euler = (Vector((0,0,1.2))-node.location).to_track_quat('-Z','Y').to_euler()
camera_data = bpy.data.cameras.new('Inspection Camera')
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 3.0
camera = bpy.data.objects.new('Inspection Camera',camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
for name,location in [('front',(0,-6,1.1)),('back',(0,6,1.1)),('side',(6,0,1.1)),('top',(0,0,7))]:
    camera.location = location
    camera.rotation_euler = (Vector((0,0,1.1))-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath = str(QA/('priest_inspect_'+name+'.png'))
    bpy.ops.render.render(write_still=True)
print('DONE_SOURCE',flush=True)
