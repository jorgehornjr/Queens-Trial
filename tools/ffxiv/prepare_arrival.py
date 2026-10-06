"""Port the arrival AVFX's authored geometry, curves, textures and source sound."""
from pathlib import Path
import sys,struct,json,shutil,hashlib
sys.path.insert(0,str(Path(__file__).resolve().parent))
from game_resources import ROOT,QA
from avfx import tagged,child,integer,floating,curve

OUT=ROOT/'assets/effects/ascian_arrival'
ART=ROOT/'art/effects/ascian_arrival'
OUT.mkdir(parents=True,exist_ok=True);ART.mkdir(parents=True,exist_ok=True)
(ART/'.gdignore').write_text('')
path=QA/'teleport_mod/vfx/common/eff/pop_tlep1t1h.avfx'
root=tagged(path.read_bytes())[0]
def axis(node):
    if not node:return {}
    return {c['tag']:curve(c) for c in node['children'] if curve(c)} | {'connect':integer(node,'ACT')}
def uv(node):return {'scale':axis(child(node,'Scl')),'scroll':axis(child(node,'Scr')),'rotation':curve(child(node,'Rot'))}
textures=[c['data'].decode().strip('\0') for c in root['children'] if c['tag']=='Tex']
for name in textures:shutil.copyfile(QA/'decoded'/(Path(name).name+'.png'),OUT/(Path(name).name+'.png'))
result={'source':'AscianTeleport.ttmp2 / pop_tlep1t1h.avfx','source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
        'bind_point':29, 'bind_description':'Center of character, relative to n_root',
        'frames_per_second':30,'duration_frames':160,'textures':[Path(n).name+'.png' for n in textures],
        'models':[],'particles':[],'emitters':[]}
for model in (c for c in root['children'] if c['tag']=='Modl'):
    vertices=child(model,'VDrw')['data'];indices=child(model,'VIdx')['data']
    mesh={'vertices':[],'indices':list(struct.unpack('<'+str(len(indices)//2)+'H',indices))}
    for p in range(0,len(vertices),36):
        mesh['vertices'].append({'position':list(struct.unpack_from('<4e',vertices,p))[:3],
            'color':[x/255 for x in vertices[p+16:p+20]],'uv':list(struct.unpack_from('<2e',vertices,p+20)),
            'uv2':list(struct.unpack_from('<2e',vertices,p+24))})
    result['models'].append(mesh)
for part in (c for c in root['children'] if c['tag']=='Ptcl'):
    source=child(part,'Data');kind=integer(part,'PrVT')
    p={'type':kind,'model':integer(source,'MNO',integer(source,'MdNo',-1)),
       'life':floating(child(part,'Life'),'Val',60),'billboard':integer(part,'RBDT'),
       'blend':integer(part,'RMT'),'scale':axis(child(part,'Scl')),'rotation':axis(child(part,'Rot')),
       'position':axis(child(part,'Pos')),'color':{c['tag']:curve(c) for c in child(part,'Col')['children']},
       'uv':[uv(c) for c in part['children'] if c['tag']=='UvSt'],
       'texture':integer(child(part,'TC1'),'TxNo',integer(child(part,'TC1'),'TLst',-1)),
       'color_to_alpha':bool(integer(child(part,'TC1'),'bC2A')),
       'distortion':integer(child(part,'TD'),'TxNo',-1)}
    if kind==12:
        p['disc']={n:curve(child(source,n)) for n in ['Ang','WB','WE','RB','RE']}
        p['disc']['color_inner']={c['tag']:curve(c) for c in child(source,'CEI')['children']}
        p['disc']['color_outer']={c['tag']:curve(c) for c in child(source,'CEO')['children']}
    result['particles'].append(p)
for e in (c for c in root['children'] if c['tag']=='Emit'):
    result['emitters'].append({'life':floating(child(e,'Life'),'Val',60),
        'position':axis(child(e,'Pos')),'creation':curve(child(e,'CrC')),'interval':curve(child(e,'CrI')),
        'items':[{'particle':integer(c,'TgtB'),'enabled':bool(integer(c,'bEnb')),
                  'count':integer(c,'CrCn'),'creation_time':integer(c,'CrTm'),
                  'override_life':integer(c,'OvrV') if integer(c,'bOvr') else -1,
                  'injection':[floating(c,t) for t in ['BIAX','BIAY','BIAZ']]}
                 for c in e['children'] if c['tag']=='ItPr']})
(OUT/'arrival.json').write_text(json.dumps(result,indent=2))
shutil.copyfile(path,ART/'original_arrival.avfx')
sound=QA/'decoded/SE_Vfx_Monster_c0101_wrp01.wav'
audio=ROOT/'assets/audio/sfx/ascian_arrival.wav';shutil.copyfile(sound,audio)
shutil.copyfile(QA/'game_resources/sound/vfx/monster7/SE_Vfx_Monster_c0101_wrp01.scd',ART/'original_arrival.scd')
(ART/'source_report.json').write_text(json.dumps({'mod':'Ascian and Ancient Teleport.rar','author':'Dekken',
    'arrival_only':'vfx/common/eff/pop_tlep1t1h.avfx','textures':textures,
    'audio':'sound/vfx/monster7/SE_Vfx_Monster_c0101_wrp01.scd','audio_sha256':hashlib.sha256(sound.read_bytes()).hexdigest(),
    'geometry_counts':[(len(m['vertices']),len(m['indices'])) for m in result['models']],
    'renderer':'Godot port of AVFX; source geometry, UVs, color/scale curves and texture resources preserved.'},indent=2))
print('ARRIVAL_PREPARED',len(result['particles']),'particle definitions',len(result['models']),'original models')
