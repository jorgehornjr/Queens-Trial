"""Export a neutral, unrigged Priest body while preserving the game cloth rig.

Run with Blender --background --factory-startup --python this_file.py.
The existing game model, cape cage and animations are only read.
"""
from pathlib import Path
import hashlib
import json
import zipfile
import math

import bpy
import bmesh
from mathutils import Matrix, Vector, Quaternion


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/characters/fallen_priest/fallen_priest_rig.blend"
OUT = ROOT / "art/characters/fallen_priest/mixamo"
QA = ROOT / ".godot/qa/mixamo_priest"
OUT.mkdir(parents=True, exist_ok=True)
QA.mkdir(parents=True, exist_ok=True)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


protected = [SOURCE, ROOT / "assets/models/characters/fallen_priest/fallen_priest_rig.glb",
             ROOT / "assets/models/characters/fallen_priest/cape_cage.json"]
before = {str(path.relative_to(ROOT)): sha256(path) for path in protected}
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
rig = bpy.data.objects["PriestRig"]
rig.animation_data_clear()
rig.data.pose_position = "POSE"
for obj in bpy.context.scene.objects:
    obj.animation_data_clear()
for pose in rig.pose.bones:
    pose.matrix_basis = Matrix.Identity(4)
bpy.context.view_layer.update()


# A modest A-pose separates the hands from the coat without forcing the sculpt
# into a horizontal T-pose. Keep chest ornaments and hood in their original pose.
rest_coordinates = {obj.name: [vertex.co.copy() for vertex in obj.data.vertices]
                    for obj in bpy.context.scene.objects if obj.type == "MESH"}
for side, sign in [("L", -1), ("R", 1)]:
    name = "UpperArm_" + side
    rotation = rig.data.bones[name].matrix_local.to_quaternion()
    rig.pose.bones[name].rotation_mode = "QUATERNION"
    rig.pose.bones[name].rotation_quaternion = (rotation.inverted()
        @ Quaternion((0, 1, 0), sign * math.radians(40)) @ rotation)
bpy.context.view_layer.update()
landmarks = {"chin": [0, -0.06, 1.81], "groin": [0, -0.015, 1.10]}
for side in ["L", "R"]:
    for marker, bone in [("wrist", "Hand_"), ("elbow", "Forearm_"), ("knee", "Shin_")]:
        landmarks[marker + "_" + side] = list(rig.pose.bones[bone + side].head)

# Bake the neutral pose into copied mesh data, then remove all skin and actions.
for obj in list(bpy.context.scene.objects):
    if obj.type != "MESH":
        continue
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    for modifier in list(obj.modifiers):
        if modifier.type == "ARMATURE":
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    for vertex, original in zip(obj.data.vertices, rest_coordinates[obj.name]):
        if obj.name == "BodyMesh":
            lateral = max(0.0, min(1.0, (abs(original.x) - .20) / .10))
            factor = lateral * lateral * (3 - 2 * lateral) if .80 < original.z < 1.78 else 0
        else:
            factor = 0
        vertex.co = original.lerp(vertex.co, factor)
    world = obj.matrix_world.copy()
    obj.parent = None
    obj.matrix_world = world
    obj.vertex_groups.clear()
    obj.select_set(False)
bpy.data.objects.remove(rig, do_unlink=True)

body_parts = [bpy.data.objects["BodyMesh"], bpy.data.objects["HeadMesh"]]
bpy.ops.object.select_all(action="DESELECT")
for obj in body_parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = body_parts[0]
bpy.ops.object.join()
body = bpy.context.object
body.name = "Priest_Body"
body.data.name = "Priest_Body_Neutral"
# Restore shared cut vertices so the head and torso are a single surface.
bm = bmesh.new()
bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.00001)
bm.to_mesh(body.data)
bm.free()
body.data.update()
triangles_before = sum(len(poly.vertices) - 2 for poly in body.data.polygons)
# Keep the upload light; the full-resolution game meshes remain in SOURCE.
if triangles_before > 95000:
    modifier = body.modifiers.new("Mixamo upload simplification", "DECIMATE")
    modifier.ratio = 90000 / triangles_before
    modifier.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier=modifier.name)
for polygon in body.data.polygons:
    polygon.use_smooth = True

# Mixamo's importer can reject PBR maps with a misleading skeleton error.
# Its preview needs only color; the game keeps the original full PBR materials.
preview_material = bpy.data.materials.new("Priest_Mixamo_Color")
preview_material.use_nodes = True
preview_shader = preview_material.node_tree.nodes.get("Principled BSDF")
preview_shader.inputs["Roughness"].default_value = .75
color_texture = preview_material.node_tree.nodes.new("ShaderNodeTexImage")
color_texture.image = bpy.data.images["Zyklus4_Zeile1_basecolor"]
preview_material.node_tree.links.new(color_texture.outputs["Color"], preview_shader.inputs["Base Color"])
body.data.materials.clear()
body.data.materials.append(preview_material)
for polygon in body.data.polygons:
    polygon.material_index = 0

for image in bpy.data.images:
    if image.source == "FILE":
        if not image.packed_file:
            image.pack()
        # Point embedded FBX textures to a persistent copy, never a QA folder.
        name = image.name + ".jpg"
        image.filepath_raw = str(OUT / name)
        image.file_format = "JPEG"
        image.save()

# These objects are local reassembly references, excluded from the FBX upload.
cloth = [bpy.data.objects["CapeMesh"], bpy.data.objects["TabardMesh"]]
for obj in cloth:
    obj.hide_render = True
    obj.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "priest_mixamo_prepared.blend"))
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body
fbx = OUT / "priest_body_for_mixamo.fbx"
bpy.ops.export_scene.fbx(filepath=str(fbx), use_selection=True,
    object_types={"MESH"}, bake_anim=False, add_leaf_bones=False,
    path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y",
    mesh_smooth_type="FACE", use_mesh_modifiers=True)

# OBJ explicitly carries no skeleton and avoids FBX skeleton-mapping failures.
obj_file = OUT / "priest_body_for_mixamo.obj"
for image in bpy.data.images:
    if image.source == "FILE":
        image.filepath = str(OUT / (image.name + ".jpg"))
bpy.ops.wm.obj_export(filepath=str(obj_file), export_selected_objects=True,
    forward_axis="NEGATIVE_Z", up_axis="Y", path_mode="COPY")
zip_file = OUT / "priest_body_for_mixamo.zip"
with zipfile.ZipFile(zip_file, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in [obj_file, obj_file.with_suffix(".mtl"), OUT / "Zyklus4_Zeile1_basecolor.jpg"]:
        archive.write(path, arcname=path.name)

report = {
    "source": str(SOURCE.relative_to(ROOT)),
    "upload": zip_file.name,
    "fbx_alternative": fbx.name,
    "pose": "Symmetrical A-pose, arms opened 40 degrees from default pose",
    "vertices": len(body.data.vertices),
    "triangles": sum(len(poly.vertices) - 2 for poly in body.data.polygons),
    "excluded_from_upload": [obj.name for obj in cloth],
    "embedded_textures": True,
    "preview_material": "Single opaque material, base color only; game PBR materials preserved in source",
    "armatures": 0,
    "landmarks_blender_z_up": landmarks,
    "game_source_sha256": before,
    "reassembly": "Retarget downloaded Mixamo body clips to the original PriestRig; keep CapeMesh, TabardMesh, their bones and cape_cage.json from the game source.",
}
assert before == {str(path.relative_to(ROOT)): sha256(path) for path in protected}
(OUT / "preparation_report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("MIXAMO_BODY_EXPORTED", json.dumps(report), flush=True)

# Produce an orthographic front view for checking the export before uploading.
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 16
scene.render.resolution_x = 1100
scene.render.resolution_y = 1100
scene.render.resolution_percentage = 100
scene.world.color = (0.15, 0.15, 0.15)
camera_data = bpy.data.cameras.new("QA camera")
camera = bpy.data.objects.new("QA camera", camera_data)
scene.collection.objects.link(camera)
camera.location = (0, -6, 1.10)
camera.rotation_euler = (Vector((0, 0, 1.10)) - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 2.75
scene.camera = camera
for name, location, power, size in [
    ("key", (-3, -4, 5), 650, 4),
    ("fill", (3, -2, 3), 400, 3),
    ("rim", (0, 3, 4), 550, 3),
]:
    light_data = bpy.data.lights.new(name, "AREA")
    light_data.energy = power
    light_data.shape = "DISK"
    light_data.size = size
    light = bpy.data.objects.new(name, light_data)
    scene.collection.objects.link(light)
    light.location = location
    light.rotation_euler = (Vector((0, 0, 1.1)) - light.location).to_track_quat("-Z", "Y").to_euler()
scene.render.filepath = str(QA / "priest_body_neutral_front.png")
bpy.ops.render.render(write_still=True)
