"""Read-only SqPack and TTMP resources, following Lumina's public formats.

Authoring utility. Never opens the installed game's files in a writable mode.
Format references: NotAdam/Lumina and TexTools/xivModdingFramework.
"""
from pathlib import Path
import struct, zlib, zipfile, json, re

GAME = Path(r'C:\Program Files (x86)\SquareEnix\FINAL FANTASY XIV - A Realm Reborn\game')
ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / '.godot/qa/ffxiv'

def blocks(data, offset=0):
    header, kind, raw, _, _, count = struct.unpack_from('<6I',data,offset)
    if kind != 2: raise ValueError(('Expected standard SqPack resource',kind))
    result = bytearray()
    for i in range(count):
        relative, _, _ = struct.unpack_from('<IHH',data,offset+24+i*8)
        p=offset+header+relative
        size, _, compressed, uncompressed = struct.unpack_from('<4I',data,p)
        chunk=data[p+size:p+size+(uncompressed if compressed==32000 else compressed)]
        result.extend(chunk if compressed==32000 else zlib.decompress(chunk,-15))
    assert len(result)==raw,(len(result),raw)
    return bytes(result)

class GameResources:
    def __init__(self, game=GAME):
        self.game=Path(game)
        self.indexes={}
        self.used=[]
    def index(self,path):
        if path not in self.indexes:
            data=path.read_bytes()
            header=struct.unpack_from('<I',data,12)[0]
            offset,size=struct.unpack_from('<2I',data,header+8)
            self.indexes[path]=dict(struct.iter_unpack('<II',data[offset:offset+size]))
        return self.indexes[path]
    def locate(self,name):
        name=name.replace('\\','/').lower()
        crc=zlib.crc32(name.encode())^0xffffffff
        category={'common':'00','bgcommon':'01','bg':'02','cut':'03','chara':'04','shader':'05','ui':'06','sound':'07','vfx':'08','exd':'0a'}.get(name.split('/')[0])
        for p in self.game.joinpath('sqpack').glob('*/'+str(category)+'*.win32.index2'):
            index=self.index(p)
            if crc in index:
                entry=index[crc]
                if entry&1: raise ValueError(('Synonym entry',name))
                dat=p.with_suffix('.dat'+str((entry&14)>>1))
                return dat,(entry&~15)*8
        raise FileNotFoundError(name)
    def read(self,name):
        dat,offset=self.locate(name)
        with dat.open('rb') as f:
            f.seek(offset);hdr=f.read(24)
            size,kind,raw,_,_,count=struct.unpack('<6I',hdr)
            f.seek(offset);head=f.read(size)
            if kind==2:
                end=max(struct.unpack_from('<IHH',head,24+i*8)[0]+struct.unpack_from('<IHH',head,24+i*8)[1] for i in range(count))
                f.seek(offset);data=f.read(size+end+128)
                result=blocks(data)
            elif kind==4:
                lods=[struct.unpack_from('<5I',head,24+i*20) for i in range(count)]
                f.seek(offset+size);result=bytearray(f.read(lods[0][0]))
                table=24+count*20
                for relative,comp,uncomp,block_start,block_count in lods:
                    p=offset+size+relative
                    for i in range(block_count):
                        f.seek(p);bsize,_,compressed,decompressed=struct.unpack('<4I',f.read(16))
                        f.seek(p+bsize);chunk=f.read(decompressed if compressed==32000 else compressed)
                        result.extend(chunk if compressed==32000 else zlib.decompress(chunk,-15))
                        p+=struct.unpack_from('<H',head,table)[0];table+=2
                result=bytes(result)
            else: raise ValueError(('Unsupported resource type',kind,name))
        self.used.append({'path':name,'sqpack':str(dat),'size':len(result)})
        return result
    def extract(self,name,root=QA/'game_resources'):
        output=Path(root)/name;output.parent.mkdir(parents=True,exist_ok=True)
        output.write_bytes(self.read(name));return output

def mod_effects(package,output=QA/'teleport_mod'):
    output.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(package) as z:
        metadata=json.loads(z.read('TTMPL.mpl').decode('utf-8-sig'))
        data=z.read('TTMPD.mpd')
        for entry in metadata['SimpleModsList']:
            p=output/entry['FullPath'];p.parent.mkdir(parents=True,exist_ok=True)
            p.write_bytes(blocks(data,entry['ModOffset']))
    (output/'manifest.json').write_text(json.dumps(metadata,indent=2))
    return output

def paths(data):
    return sorted(set(s.decode('ascii') for s in re.findall(rb'[a-zA-Z0-9_./-]+\.(?:atex|tex|scd|sdm|mdl|mtrl)',data)))

if __name__=='__main__':
    package=ROOT/'.godot/qa/ascian_teleport_source/Ascian and Ancient Teleport/Ascian/AscianTeleport.ttmp2'
    output=mod_effects(package)
    game=GameResources()
    deps=set()
    for p in output.rglob('*.avfx'):
        found=paths(p.read_bytes());print(p.name,p.stat().st_size,found);deps.update(found)
    for name in sorted(deps):
        try: print('EXTRACTED',game.extract(name))
        except Exception as e:print('MISSING',name,e)
    (QA/'teleport_resources.json').write_text(json.dumps(game.used,indent=2))
