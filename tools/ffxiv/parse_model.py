"""Convert the model's high-detail geometry and Havok bind skeleton to JSON.

Read-only authoring parser for the supplied MDL. Field layout follows Lumina.
"""
from pathlib import Path
import struct, json, re, xml.etree.ElementTree as ET, sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from game_resources import QA, paths

def parse_skeleton(path):
    root=ET.parse(path).getroot()
    obj=next(o for o in root.iter('hkobject') if o.get('class')=='hkaSkeleton')
    parents=[int(x) for x in obj.find("hkparam[@name='parentIndices']").text.split()]
    names=[o.find("hkparam[@name='name']").text for o in obj.find("hkparam[@name='bones']")]
    pose=obj.find("hkparam[@name='referencePose']").text
    groups=re.findall(r'\(([^)]+)\)',pose)
    transforms=[]
    for i,name in enumerate(names):
        values=[[float(x) for x in groups[i*3+j].split()] for j in range(3)]
        transforms.append({'name':name,'parent':parents[i],'translation':values[0][:3],'rotation':values[1],'scale':values[2][:3]})
    return transforms

def parse_model(path):
    b=Path(path).read_bytes()
    header=struct.unpack_from('<3I2H12I4B',b)
    declarations=header[3];vertex_offsets=header[5:8];index_offsets=header[8:11]
    decl=[]
    for i in range(declarations):
        elements=[]
        for j in range(17):
            e=struct.unpack_from('<5B',b,68+i*136+j*8)
            if e[0]==255:break
            elements.append(e)
        decl.append(elements)
    p=68+declarations*136
    string_count,_,size=struct.unpack_from('<HHI',b,p);p+=8
    strings=b[p:p+size];p+=size
    mh=struct.unpack_from('<f9HBBHBBffHH4B3H6B',b,p)
    mesh_count,attrs,subcount,mats,bones,tables,shapes,shapemeshes,shapevalues=mh[1:10]
    element_count=mh[12];shadow_count=mh[13];flags2=mh[14];terrain_subcount=mh[18]
    p+=56+element_count*32
    lods=[struct.unpack_from('<HHff8H8I',b,p+i*60) for i in range(3)];p+=180
    if flags2&16:p+=3*40
    mesh_headers=[struct.unpack_from('<HHI4HI3I4B',b,p+i*36) for i in range(mesh_count)];p+=mesh_count*36
    def words(count):
        nonlocal p
        out=struct.unpack_from('<'+str(count)+'I',b,p);p+=count*4;return out
    attribute_offsets=words(attrs)
    p+=shadow_count*20
    submeshes=[struct.unpack_from('<3I2H',b,p+i*16) for i in range(subcount)];p+=subcount*16+terrain_subcount*12
    material_offsets=words(mats);bone_offsets=words(bones)
    def string(offset):return strings[offset:strings.find(b'\0',offset)].decode('ascii')
    materials=[string(o) for o in material_offsets];bone_names=[string(o) for o in bone_offsets]
    palettes=[]
    if header[0]&0xff==6:
        # Version 6 stores variable-length palettes, referenced from each entry.
        for i in range(tables):
            offset,count=struct.unpack_from('<HH',b,p+i*4)
            begin=p+i*4+offset*4
            palettes.append(list(struct.unpack_from('<'+str(count)+'H',b,begin)))
    else:
        for i in range(tables):palettes.append(list(struct.unpack_from('<64H',b,p+i*132)))
    result={'version':header[0],'materials':materials,'bones':bone_names,'meshes':[],
            'lods':lods,'palettes':palettes,'attributes':[string(o) for o in attribute_offsets]}
    for index,m in enumerate(mesh_headers[:lods[0][1]]):
        count,_,num_indices,material,substart,numsubs,palette,start,*tail=m
        offsets=tail[:3];strides=tail[3:6]
        vertices=[]
        for i in range(count):
            v={}
            for stream,offset,kind,usage,usageindex in decl[index]:
                pos=vertex_offsets[0]+offsets[stream]+i*strides[stream]+offset
                formats={0:'f',1:'2f',2:'3f',3:'4f',5:'4B',8:'4B',13:'2e',14:'4e'}
                value=list(struct.unpack_from('<'+formats[kind],b,pos))
                if kind==8:value=[x/255 for x in value]
                if usage==2:value=[bone_names[palettes[palette][x]] for x in value]
                v[{0:'position',1:'weights',2:'joints',3:'normal',4:'uv',5:'tangent',6:'binormal',7:'color'}[usage]]=value
            vertices.append(v)
        indices=list(struct.unpack_from('<'+str(num_indices)+'H',b,index_offsets[0]+start*2))
        result['meshes'].append({'material':materials[material],'vertices':vertices,'indices':indices,
             'submeshes':submeshes[substart:substart+numsubs]})
    return result

if __name__=='__main__':
    model=QA/'fandaniel_mod/chara/equipment/e8100/model/c0101e8100_top.mdl'
    r=parse_model(model);r['skeleton']=parse_skeleton(QA/'fandaniel_export/base.xml')
    out=QA/'fandaniel_export/model.json';out.write_text(json.dumps(r))
    print('MODEL',r['version'],r['materials'],len(r['bones']),'meshes',[(len(m['vertices']),len(m['indices'])) for m in r['meshes']])
    print('BONE_NAMES',r['bones']);print('PALETTES',r['palettes'])
    print('SKELETON',len(r['skeleton']))
    for p in (QA/'fandaniel_mod').rglob('*.mtrl'):
        if 'c0101' in p.name:print('MATERIAL',p.name,paths(p.read_bytes()),p.read_bytes()[:16].hex())
