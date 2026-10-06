"""Bake the original CharacterLegacy colorset using its supplied index maps."""
from pathlib import Path
import sys,struct,json,zipfile,hashlib
sys.path.insert(0,str(Path(__file__).resolve().parent))
from game_resources import ROOT,QA,GameResources,paths
from convert_resources import texture
sys.path.insert(0,str(ROOT/'.godot/qa/audio_tools/python_modules'))
import numpy as np
from PIL import Image

ART=ROOT/'art/characters/fandaniel'
OUT=ROOT/'assets/models/characters/fandaniel'
ART.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
(ART/'.gdignore').write_text('')
report={'source_mod':'Fandaniel+Elidibus Enshroud.pmp','author':'Dekken','option':'Hooded Fandaniel','materials':{}}
report['design_change']={'cloth_color':'original burgundy restored', 'palette_rows':'all original rows preserved'}
def save(name,array):
    p=OUT/name;Image.fromarray(np.uint8(np.clip(array,0,1)*255+.5)).save(p);return str(p)
for suffix in ['d','e']:
    name='mt_c0101e8100_top_'+suffix+'.mtrl'
    p=QA/'fandaniel_mod/chara/equipment/e8100/material/v0001'/name
    b=p.read_bytes();header=struct.unpack_from('<I4H4B',b)
    start=16+4*sum(header[5:8]);start+=header[3]+header[8]
    table=np.frombuffer(b[start:start+2048],dtype='<f2').reshape(32,32).astype(np.float32)
    prefix='v01_c0101e8100_top_'+suffix
    textures=QA/'fandaniel_mod/chara/equipment/e8100/texture'
    def read(kind):return np.asarray(texture((textures/(prefix+'_'+kind+'.tex')).read_bytes())).astype(np.float32)/255
    index=read('id');normal=read('n');mask=read('m')
    pair=np.clip(np.round(index[:,:,0]*255/17).astype(int),0,15)*2
    blend=1-index[:,:,1:2]
    color=table[pair]*(1-blend)+table[pair+1]*blend
    occlusion=np.asarray(Image.fromarray(np.uint8(mask[:,:,2]*255)).resize((index.shape[1],index.shape[0]),Image.Resampling.BILINEAR)).astype(float)/255
    # The public Penumbra exporter uses sqrt to encode the game table's colors.
    diffuse=np.sqrt(np.clip(color[:,:,:3],0,1))*occlusion[:,:,None]
    alpha=normal[:,:,2:3]
    files={'basecolor':save('fandaniel_'+suffix+'_basecolor.png',np.concatenate([diffuse,alpha],axis=2))}
    xy=normal[:,:,:2]*2-1
    z=np.sqrt(np.maximum(0,1-np.sum(xy*xy,axis=2)))
    rgb=np.concatenate([normal[:,:,:2],((z+1)/2)[:,:,None]],axis=2)
    files['normal']=save('fandaniel_'+suffix+'_normal.png',rgb)
    # Preserve the supplied legacy gloss response in a PBR roughness map.
    roughness=np.clip(1-mask[:,:,1],.12,.92)
    files['roughness']=save('fandaniel_'+suffix+'_roughness.png',roughness)
    files['emission']=save('fandaniel_'+suffix+'_emission.png',np.sqrt(np.clip(color[:,:,8:11],0,1)))
    report['materials'][name]={'colorset_sha256':hashlib.sha256(b).hexdigest(),'files':files,'source_textures':paths(b)}
    print('BAKED_ORIGINAL_COLORSET',name,files)

# Use the original Fandaniel face effect from the user's mod, rather than the
# original emblem previously created for the Priest.
game=GameResources()
with zipfile.ZipFile(Path.home()/'Downloads/Fandaniel+Elidibus Enshroud.pmp') as z:
    avfx=z.read('p2/face glyphs (non-lala)/fandaniel/vfx/common/eff/rrp_idle_stlp_c0x.avfx')
    (ART/'fandaniel_face.avfx').write_bytes(avfx)
    report['face_resources']=paths(avfx)
    for name in paths(avfx):
        if name.endswith('.atex'):
            try:
                data=game.read(name)
                output=OUT/(Path(name).name+'.png');texture(data).save(output)
                print('FACE_TEXTURE',name,output)
            except FileNotFoundError:print('FACE_MISSING',name)
(ART/'material_report.json').write_text(json.dumps(report,indent=2))
