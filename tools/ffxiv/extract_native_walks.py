"""Extract original human cinematic walks and export them with their own skin rig.

Game files are read only. XAT's published native exporter handles Havok sampling.
"""
from pathlib import Path
import struct,json,sys,subprocess,hashlib
sys.path.insert(0,str(Path(__file__).resolve().parent))
from game_resources import ROOT,QA,GameResources

OUT=QA/'native_walk'
OUT.mkdir(parents=True,exist_ok=True)
TOOL=QA/'tools/xat_release/XATHavokInterop.exe'
game=GameResources()
base=QA/'fandaniel_export/base.hkx'
report={}
def run(*args):
    r=subprocess.run([str(TOOL),*map(str,args)],capture_output=True,text=True)
    if r.returncode:raise RuntimeError((args,r.stdout,r.stderr))
    return r.stdout
for file in ['event_walk_loop','event_swalk_loop']:
    path=f'chara/human/c0101/animation/a0001/bt_common/event/{file}.pap'
    data=game.read(path);(OUT/(file+'.pap')).write_bytes(data)
    count=struct.unpack_from('<H',data,8)[0];info,start,end=struct.unpack_from('<3I',data,14)
    hkx=OUT/(file+'.hkx');hkx.write_bytes(data[start:end])
    entries=[]
    for i in range(count):
        entry=data[info+i*40:info+(i+1)*40]
        name=entry[:32].split(b'\0')[0].decode();idx=struct.unpack_from('<H',entry,34)[0]
        merged=OUT/(name+'.hkt');fbx=OUT/(name+'.fbx')
        run('createContainer',merged)
        run('addSkeleton',merged,base,0,merged)
        run('addAnimation',merged,hkx,idx,merged)
        result=run('toFbxAnimation',merged,0,0,fbx)
        entries.append({'name':name,'havok_index':idx,'fbx':str(fbx.relative_to(ROOT)),'export':result[-100:]})
        print('NATIVE_WALK_EXPORTED',file,name,fbx.name,result[-100:])
    report[file]={'game_path':path,'sha256':hashlib.sha256(data).hexdigest(),'animations':entries}
(OUT/'extraction_report.json').write_text(json.dumps(report,indent=2))
