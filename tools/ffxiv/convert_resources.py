"""Convert extracted FFXIV texture and ADPCM resources without resynthesizing."""
from pathlib import Path
import sys,struct,io,subprocess
sys.path.insert(0,str(Path(__file__).resolve().parent))
from game_resources import QA,ROOT
sys.path.insert(0,str(ROOT/'.godot/qa/audio_tools/python_modules'))
from PIL import Image

def texture(data):
    attr,fmt,w,h,d,mips=struct.unpack_from('<II4H',data)
    start=struct.unpack_from('<I',data,28)[0] or 80
    # DDS header + DX10 extension for BC5/BC7. Preserve source pixel channels.
    compression={0x3420:b'DXT1',0x3430:b'DXT3',0x3431:b'DXT5',0x6120:b'DX10',0x6230:b'DX10',0x6432:b'DX10'}
    if fmt in compression:
        dx10=compression[fmt]==b'DX10'
        linear=((w+3)//4)*((h+3)//4)*(8 if fmt in [0x3420,0x6120] else 16)
        header=b'DDS '+struct.pack('<7I11I',124,0x81007,h,w,linear,0,1,*([0]*11))
        header+=struct.pack('<II4s5I',32,4,compression[fmt],0,0,0,0,0)
        header+=struct.pack('<5I',0x1000,0,0,0,0)
        if dx10:header+=struct.pack('<5I',{0x6120:80,0x6230:83,0x6432:98}[fmt],3,0,1,0)
        return Image.open(io.BytesIO(header+data[start:])).convert('RGBA')
    if fmt in [0x1450,0x1451]:return Image.frombytes('RGBA',(w,h),data[start:start+w*h*4],'raw','BGRA')
    if fmt in [0x1130,0x1131]:return Image.frombytes('L',(w,h),data[start:start+w*h]).convert('RGBA')
    raise ValueError(('Unsupported texture',hex(fmt),w,h))

def scd_audio(path,output):
    data=path.read_bytes()
    base=struct.unpack_from('<H',data,14)[0]
    count=struct.unpack_from('<H',data,base+4)[0]
    table=struct.unpack_from('<I',data,base+12)[0]
    for i in range(count):
        offset=struct.unpack_from('<I',data,table+i*4)[0]
        size,channels,rate,kind,loop_start,loop_end,info,flags=struct.unpack_from('<8I',data,offset)
        if kind!=12:raise ValueError(('Expected MS ADPCM',kind))
        wave_header=data[offset+32:offset+32+info]
        compressed=data[offset+32+info:offset+32+info+size]
        body=b'WAVEfmt '+struct.pack('<I',len(wave_header))+wave_header+b'data'+struct.pack('<I',len(compressed))+compressed
        raw=output.with_suffix('.adpcm.wav');raw.parent.mkdir(parents=True,exist_ok=True)
        raw.write_bytes(b'RIFF'+struct.pack('<I',len(body))+body)
        subprocess.run(['ffmpeg','-y','-v','error','-i',str(raw),'-c:a','pcm_s16le',str(output)],check=True)
        print('ORIGINAL_SCD_AUDIO',path.name,rate,channels,size,'=>',output)

if __name__=='__main__':
    out=QA/'decoded';out.mkdir(parents=True,exist_ok=True)
    for root in [QA/'game_resources',QA/'fandaniel_mod']:
        for p in root.rglob('*'):
            if p.suffix in ['.tex','.atex'] and ('c0101' in p.name or p.suffix=='.atex'):
                target=out/(p.name+'.png');texture(p.read_bytes()).save(target)
                print('TEXTURE',target.name)
    for p in (QA/'game_resources/sound').rglob('*.scd'):
        scd_audio(p,out/(p.stem+'.wav'))
