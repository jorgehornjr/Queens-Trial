"""Extract AVFX tagged blocks, animation curves and the embedded geometry."""
from pathlib import Path
import struct,json,sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from game_resources import ROOT,QA

def tagged(data):
    result=[];p=0
    while p+8<=len(data):
        tag,size=struct.unpack_from('<4sI',data,p)
        if size>len(data)-p-8:return []
        if not all(c==0 or 32<=c<127 for c in tag):return []
        body=data[p+8:p+8+size]
        result.append({'tag':tag[::-1].decode('ascii').strip('\0'),'data':body,'children':tagged(body) if size>=8 else []})
        p+=8+((size+3)&~3)
    return result if p==len(data) else []
def child(node,tag):return next((c for c in reversed(node['children']) if c['tag']==tag),None) if node else None
def integer(node,tag,default=0):
    c=child(node,tag)
    if not c:return default
    return int.from_bytes(c['data'][:4], 'little', signed=len(c['data'])>=4)
def floating(node,tag,default=0.0):
    c=child(node,tag);return struct.unpack_from('<f',c['data'])[0] if c else default
def curve(node):
    if not node:return []
    keys=child(node,'Keys')
    return [list(struct.unpack_from('<hh3f',keys['data'],i)) for i in range(0,len(keys['data']),16)] if keys else []
def compact(node):
    out={'tag':node['tag']}
    if node['children']:out['children']=[compact(c) for c in node['children']]
    elif node['tag']=='Keys':out['keys']=[list(k) for k in struct.iter_unpack('<hh3f',node['data'])]
    elif len(node['data'])==4:out.update(integer=struct.unpack('<i',node['data'])[0],number=struct.unpack('<f',node['data'])[0])
    elif node['data'] and all(c==0 or 32<=c<127 for c in node['data']):out['string']=node['data'].decode().strip('\0')
    else:out['hex']=node['data'].hex()
    return out

if __name__=='__main__':
    path=QA/'teleport_mod/vfx/common/eff/pop_tlep1t1h.avfx'
    root=tagged(path.read_bytes())[0]
    (QA/'arrival_parsed.json').write_text(json.dumps(compact(root),indent=2))
    print('TEXTURES',[c['data'].decode().strip('\0') for c in root['children'] if c['tag']=='Tex'])
    for i,p in enumerate(c for c in root['children'] if c['tag']=='Ptcl'):
        print('PARTICLE',i,'type',integer(p,'PrVT'),'life',floating(child(p,'Life'),'Val'),
              'color',{c['tag']:curve(c) for c in child(p,'Col')['children']},
              'scale',{c['tag']:curve(c) for c in child(p,'Scl')['children']})
    for i,e in enumerate(c for c in root['children'] if c['tag']=='Emit'):
        print('EMITTER',i,'life',floating(child(e,'Life'),'Val'),'creation',curve(child(e,'CrC')))
        for c in e['children']:
            if c['tag']=='ItPr':print('PARTICLE_ITEM',compact(c))
    for c in root['children']:
        if c['tag']=='TmLn':print('TIMELINE',compact(c))
