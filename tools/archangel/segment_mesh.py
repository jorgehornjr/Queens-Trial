"""Blender preview of semantic face regions, without altering source geometry."""
from pathlib import Path
import sys
import bpy
import numpy as np
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[2]
QA = ROOT/'.godot'/'qa'
sys.path.insert(0,str(QA/'blender_modules'))
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components, dijkstra

def region_labels(obj):
    coords = np.empty(len(obj.data.vertices)*3,dtype=np.float32)
    obj.data.vertices.foreach_get('co',coords)
    coords = coords.reshape(-1,3)
    faces = np.empty(len(obj.data.polygons)*3,dtype=np.int32)
    obj.data.polygons.foreach_get('vertices',faces)
    faces = faces.reshape(-1,3)
    edges = np.vstack([faces[:,[0,1]],faces[:,[1,2]],faces[:,[2,0]]])
    lengths = np.linalg.norm(coords[edges[:,0]]-coords[edges[:,1]],axis=1)
    graph = coo_matrix((lengths,(edges[:,0],edges[:,1])),shape=(len(coords),len(coords))).tocsr()
    graph = graph.maximum(graph.T)
    _,components = connected_components(graph,directed=False)
    ids,counts = np.unique(components,return_counts=True)
    for cid in ids[np.argsort(counts)[-8:]]:
        points = coords[components==cid]
        print('COMPONENT',cid,len(points),points.min(0),points.max(0),flush=True)
    centroids = coords[faces].mean(1)
    x,y,z = centroids.T
    labels = np.full(len(faces),'Body',dtype=object)
    # Surface geodesics separate branches joined in the source without capturing
    # an arm simply because it lies near a feather in Euclidean space.
    vx,vy,vz = coords.T
    body_seeds = ((np.abs(vx)<0.21)&(vz<1.82))|((np.abs(vx)<0.26)&(vz>1.82)&(vz<2.02))
    body_seeds |= (np.abs(vx)<0.43)&(vz<0.76)&(vy>-.28)
    body_seeds |= (np.abs(vx)>.34)&(np.abs(vx)<.66)&(vz>1.01)&(vz<1.57)&(vy<.22)
    wing_seeds = (np.abs(vx)>.70)&(vz>1.04)
    wing_seeds |= (np.abs(vx)>.28)&(vy>.40)&(vz>1.35)
    sword_seeds = (vz<.80)&(vy<-.30)
    sword_seeds |= ((vx+.77)/.10)**2+((vy-.16)/.075)**2+((vz-1.075)/.075)**2<1
    body_seeds &= ~sword_seeds
    wing_seeds &= ~(body_seeds|sword_seeds)
    dist_body = dijkstra(graph,directed=False,indices=np.flatnonzero(body_seeds),min_only=True)
    dist_wing = dijkstra(graph,directed=False,indices=np.flatnonzero(wing_seeds),min_only=True)
    dist_sword = dijkstra(graph,directed=False,indices=np.flatnonzero(sword_seeds),min_only=True)
    vertex_wing = (dist_wing < dist_body)&(vz>1.02)&(np.abs(vx)>.21)
    vertex_sword = (dist_sword < dist_body)&(dist_sword < dist_wing)
    wing = vertex_wing[faces].sum(1)>=2
    labels[wing&(x<0)]='Wing_R'
    labels[wing&(x>=0)]='Wing_L'
    # The halo is the only sizeable disconnected component above the helmet.
    halo_ids = [cid for cid in ids if np.all(coords[components==cid,2]>2.00)]
    halo = np.isin(components[faces[:,0]],halo_ids)
    labels[halo]='Halo'
    # Sword lies in front of the legs and torso, along a diagonal from the grip.
    sword = vertex_sword[faces].sum(1)>=2
    blade_x = -.53 + 1.15*(1.0-z)
    blade_y = .03 - .76*(1.0-z)
    sword |= (z<.93)&(y<-.10)&(np.abs(x-blade_x)<.23)&(np.abs(y-blade_y)<.135)
    sword |= (x<-.27)&(x>-.65)&(z>.77)&(z<1.01)&(y<.005)
    sword |= (x<-.40)&(z>.72)&(z<.90)&(y<.13)
    sword |= ((x+.77)/.10)**2+((y-.16)/.075)**2+((z-1.075)/.075)**2<1
    # Retain fingers as part of the hand rather than the hilt.
    sword &= ~((x>-.62)&(x<-.45)&(z>.95)&(z<1.10)&(y>-.025))
    labels[sword&(z<1.32)]='Sword'
    # Separate head and hanging fabric panels from the armor.
    labels[(labels=='Body')&(z>1.78)]='Head'
    skirt = (z>0.66)&(z<1.12)&(np.abs(x)<0.115)
    labels[(labels=='Body')&skirt&(y<.005)]='Tabard_Front'
    labels[(labels=='Body')&skirt&(y>.24)]='Tabard_Back'
    return coords,faces,labels

def preview_regions(obj, labels):
    colors = {'Body':(.22,.27,.35,1),'Head':(.5,.65,.85,1),
              'Wing_L':(.95,.2,.2,1),'Wing_R':(.15,.45,1,1),'Halo':(1,.7,.1,1),
              'Sword':(.65,.15,.9,1),'Tabard_Front':(.05,.7,.35,1),'Tabard_Back':(.1,.9,.7,1)}
    obj.data.materials.clear()
    for name,color in colors.items():
        material = bpy.data.materials.new(name)
        material.diffuse_color = color
        obj.data.materials.append(material)
    indices = {name:i for i,name in enumerate(colors)}
    obj.data.polygons.foreach_set('material_index',np.array([indices[label] for label in labels],dtype=np.int32))
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_WORKBENCH'
    scene.display.shading.light = 'STUDIO'
    scene.display.shading.color_type = 'MATERIAL'
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.display.shading.background_type = 'WORLD'
    scene.world.color = (.05,.05,.05)
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 1200
    scene.render.resolution_percentage = 100
    camera_data = bpy.data.cameras.new('Region Camera')
    camera_data.type = 'ORTHO'
    camera_data.ortho_scale = 3.0
    camera = bpy.data.objects.new('Region Camera',camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    for name,location in [('front',(0,-6,1.1)),('back',(0,6,1.1)),('side',(6,0,1.1))]:
        camera.location = location
        camera.rotation_euler = (Vector((0,0,1.1))-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath = str(QA/('archangel_regions_'+name+'.png'))
        bpy.ops.render.render(write_still=True)

if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(QA/'archangel_prepared.blend'))
    obj = bpy.data.objects['Archangel_Working']
    coords,faces,labels = region_labels(obj)
    np.save(QA/'archangel_face_labels.npy',labels.astype('U24'))
    print('REGIONS', {name:int((labels==name).sum()) for name in set(labels)},flush=True)
    preview_regions(obj,labels)
