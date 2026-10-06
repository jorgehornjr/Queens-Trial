"""Independently compare exported glTF positions, UVs and skin to the MDL data."""
from pathlib import Path
import sys,json,struct
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.godot/qa/audio_tools/python_modules'))
import numpy as np

path=ROOT/'assets/models/characters/fandaniel/fandaniel_mixamo.glb'
raw=path.read_bytes();size=struct.unpack_from('<I',raw,12)[0]
g=json.loads(raw[20:20+size]);binary=raw[size+28:]
def accessor(index):
    a=g['accessors'][index];v=g['bufferViews'][a['bufferView']]
    dtype={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']]
    count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    item=np.dtype(dtype).itemsize*count
    start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',item)
    return np.array([np.frombuffer(binary,dtype=dtype,count=count,offset=start+i*stride) for i in range(a['count'])])

source=json.loads((ROOT/'art/characters/fandaniel/source/model.json').read_text())
joints=[g['nodes'][i]['name'] for i in g['skins'][0]['joints']]
checked=0;geometry_error=0.0;weight_error=0.0
for original,mesh in zip(source['meshes'],g['meshes']):
    coordinates=np.array([v['position'][:3]+v['uv'][:2] for v in original['vertices']])
    for primitive in mesh['primitives']:
        attrs=primitive['attributes']
        positions=accessor(attrs['POSITION']);uv=accessor(attrs['TEXCOORD_0'])
        weights=accessor(attrs['WEIGHTS_0']);bones=accessor(attrs['JOINTS_0'])
        for i,(position,tex) in enumerate(zip(positions,uv)):
            target=np.concatenate([position,tex])
            differences=np.max(np.abs(coordinates-target),axis=1)
            candidates=np.flatnonzero(differences<2e-6)
            assert len(candidates)>0,('Changed geometry/UV',mesh['name'],i,target)
            actual={joints[int(j)]:float(w) for j,w in zip(bones[i],weights[i]) if w>1e-6}
            errors=[]
            for candidate in candidates:
                vertex=original['vertices'][candidate]
                expected={j:float(w) for j,w in zip(vertex['joints'],vertex['weights']) if w>1e-6}
                errors.append(max(abs(actual.get(j,0)-expected.get(j,0)) for j in actual.keys()|expected.keys()))
            weight_error=max(weight_error,min(errors))
            geometry_error=max(geometry_error,float(np.min(differences)))
            checked+=1
assert weight_error<1e-5
report={'checked_exported_vertices':checked,'maximum_position_or_uv_difference':geometry_error,
    'maximum_weight_difference':weight_error,'original_skeleton_bones':len(joints),'passed':True}
(ROOT/'art/characters/fandaniel/skin_verification.json').write_text(json.dumps(report,indent=2))
print('ORIGINAL_SKIN_VERIFIED',report)
