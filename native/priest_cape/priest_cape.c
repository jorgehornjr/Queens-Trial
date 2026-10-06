/* Original XPBD cape solver, using Godot's stable C extension interface.
 * State owns its bytes; incoming arrays are copied on write by Godot.
 * No threads, engine objects, or skeleton updates enter the numerical loop. */
#include "gdextension_interface.h"
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct { float x,y,z; } V3;
typedef struct { float x,y,z,w; } V4;
typedef union { uint64_t align; unsigned char data[64]; } Opaque;
static GDExtensionClassLibraryPtr library;
static GDExtensionInterfaceGetVariantToTypeConstructor to_type;
static GDExtensionInterfaceGetVariantFromTypeConstructor from_type;
static GDExtensionInterfaceVariantGetType variant_type;
static GDExtensionInterfaceVariantNewNil new_nil;
static GDExtensionInterfacePackedByteArrayOperatorIndex bytes_write;
static GDExtensionInterfacePackedByteArrayOperatorIndexConst bytes_read;
static GDExtensionInterfaceStringNameNewWithUtf8Chars name_new;
static GDExtensionInterfaceVariantGetPtrDestructor get_destructor;
static GDExtensionInterfaceClassdbConstructObject construct_object;
static GDExtensionInterfaceObjectSetInstance set_instance;
static GDExtensionInterfaceClassdbUnregisterExtensionClass unregister_class;
static GDExtensionPtrBuiltInMethod array_size;
static Opaque class_name, parent_name;

static V3 add(V3 a,V3 b){return (V3){a.x+b.x,a.y+b.y,a.z+b.z};}
static V3 sub(V3 a,V3 b){return (V3){a.x-b.x,a.y-b.y,a.z-b.z};}
static V3 mul(V3 a,float s){return (V3){a.x*s,a.y*s,a.z*s};}
static float dot(V3 a,V3 b){return a.x*b.x+a.y*b.y+a.z*b.z;}
static V3 transform(const float *m,V3 p){return (V3){m[0]*p.x+m[3]*p.y+m[6]*p.z+m[9],m[1]*p.x+m[4]*p.y+m[7]*p.z+m[10],m[2]*p.x+m[5]*p.y+m[8]*p.z+m[11]};}

static void simulate(unsigned char *state,const unsigned char *frame){
    const uint32_t *h=(const uint32_t*)state;
    int n=h[0],pinned=h[1],count=h[2],spheres=*(const uint32_t*)frame;
    const V4 *links=(const V4*)(state+12);
    V3 *p=(V3*)(state+12+count*16),*old=p+n;
    const float *params=(const float*)(frame+4);
    V3 wind={params[0],params[1],params[2]};
    const float *floor_matrix=params+8,*floor_inverse=params+20;
    const V3 *anchors=(const V3*)(frame+132);
    const V4 *colliders=(const V4*)(frame+132+pinned*12);
    const float dt=1.0f/120.0f;
    float lambda[5000]={0};
    for(int i=0;i<n;i++){
        if(i<pinned){p[i]=old[i]=anchors[i];continue;}
        V3 position=p[i],motion=sub(p[i],old[i]);
        V3 air=mul(sub(wind,mul(motion,1.0f/dt)),.65f);
        air.y-=params[3];
        p[i]=add(position,add(mul(motion,.997f),mul(air,dt*dt)));
        old[i]=position;
    }
    for(int iteration=0;iteration<12;iteration++){
        for(int c=0;c<count;c++){
            int a=(int)links[c].x,b=(int)links[c].y;
            float wa=a<pinned?0.0f:1.0f,wb=b<pinned?0.0f:1.0f;
            if(wa+wb==0)continue;
            V3 diff=sub(p[a],p[b]);float length=sqrtf(dot(diff,diff));
            if(length<.000001f)continue;
            float alpha=links[c].w/(dt*dt);
            float correction=(-(length-links[c].z)-alpha*lambda[c])/(wa+wb+alpha);
            lambda[c]+=correction;
            V3 displacement=mul(diff,correction/length);
            p[a]=add(p[a],mul(displacement,wa));p[b]=sub(p[b],mul(displacement,wb));
        }
        if(iteration%2==0)continue;
        for(int i=pinned;i<n;i++){
            for(int c=0;c<spheres;c++){
                V3 center={colliders[c].x,colliders[c].y,colliders[c].z};
                V3 diff=sub(p[i],center);float sq=dot(diff,diff),radius=colliders[c].w;
                if(sq<radius*radius&&sq>.000000001f)p[i]=add(center,mul(diff,radius/sqrtf(sq)));
            }
            if(params[5]>.5f){
                V3 local=transform(floor_inverse,p[i]);
                float height=params[7]+.018f*params[4];
                if(fabsf(local.x)<params[6]&&fabsf(local.z)<params[6]&&local.y<height){local.y=height;p[i]=transform(floor_matrix,local);}
            }
        }
    }
}

static void advance(void *userdata,GDExtensionClassInstancePtr instance,const GDExtensionConstVariantPtr *args,GDExtensionInt argc,GDExtensionVariantPtr ret,GDExtensionCallError *error){
    (void)userdata;(void)instance;error->error=GDEXTENSION_CALL_OK;
    if(argc!=2){error->error=GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;new_nil(ret);return;}
    for(int i=0;i<2;i++)if(variant_type(args[i])!=GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY){error->error=GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;error->argument=i;new_nil(ret);return;}
    Opaque state,frame;
    to_type(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)(&state,(GDExtensionVariantPtr)args[0]);
    to_type(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)(&frame,(GDExtensionVariantPtr)args[1]);
    int64_t state_size=0,frame_size=0;array_size(&state,NULL,&state_size,0);array_size(&frame,NULL,&frame_size,0);
    unsigned char *s=state_size>=12?bytes_write(&state,0):NULL;
    const unsigned char *f=frame_size>=132?bytes_read(&frame,0):NULL;
    int valid=s&&f;
    if(valid){
        const uint32_t *h=(const uint32_t*)s;uint32_t cols=*(const uint32_t*)f;
        valid=h[0]>0&&h[0]<=512&&h[1]<=h[0]&&h[2]<=5000&&cols<=256&&state_size==(int64_t)(12+h[2]*16+h[0]*24)&&frame_size==(int64_t)(132+h[1]*12+cols*16);
        const V4 *links=(const V4*)(s+12);
        if(valid)for(uint32_t c=0;c<h[2];c++)if(!isfinite(links[c].x)||!isfinite(links[c].y)||links[c].x<0||links[c].y<0||links[c].x>=h[0]||links[c].y>=h[0]){valid=0;break;}
    }
    if(valid){simulate(s,f);from_type(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)(ret,&state);}else{error->error=GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;new_nil(ret);}
    get_destructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)(&state);
    get_destructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)(&frame);
}

static GDExtensionObjectPtr create(void *userdata){
    (void)userdata;GDExtensionObjectPtr object=construct_object(&parent_name);
    set_instance(object,&class_name,calloc(1,1));return object;
}
static void destroy(void *userdata,GDExtensionClassInstancePtr instance){(void)userdata;free(instance);}
static void initialize(void *userdata,GDExtensionInitializationLevel level){
    if(level!=GDEXTENSION_INITIALIZATION_SCENE)return;
    GDExtensionInterfaceGetProcAddress get=(GDExtensionInterfaceGetProcAddress)userdata;
    name_new(&class_name,"PriestCapeSolver");name_new(&parent_name,"RefCounted");
    GDExtensionClassCreationInfo2 info={0};info.is_exposed=1;info.create_instance_func=create;info.free_instance_func=destroy;
    ((GDExtensionInterfaceClassdbRegisterExtensionClass2)get("classdb_register_extension_class2"))(library,&class_name,&parent_name,&info);
    Opaque method_name,size_name,empty_name,empty_string,arg_names[2];
    name_new(&method_name,"advance");name_new(&size_name,"size");name_new(&empty_name,"");
    name_new(&arg_names[0],"state");name_new(&arg_names[1],"frame");
    ((GDExtensionInterfaceVariantGetPtrConstructor)get("variant_get_ptr_constructor"))(GDEXTENSION_VARIANT_TYPE_STRING,0)(&empty_string,NULL);
    array_size=((GDExtensionInterfaceVariantGetPtrBuiltinMethod)get("variant_get_ptr_builtin_method"))(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,&size_name,3173160232);
    GDExtensionPropertyInfo properties[3]={0};
    for(int i=0;i<3;i++){properties[i].type=GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY;properties[i].name=i<2?&arg_names[i]:&empty_name;properties[i].class_name=&empty_name;properties[i].hint_string=&empty_string;}
    GDExtensionClassMethodArgumentMetadata metadata[2]={0};
    GDExtensionClassMethodInfo method={0};method.name=&method_name;method.call_func=advance;method.method_flags=GDEXTENSION_METHOD_FLAG_NORMAL|GDEXTENSION_METHOD_FLAG_VARARG;method.has_return_value=1;method.return_value_info=&properties[2];method.argument_count=2;method.arguments_info=properties;method.arguments_metadata=metadata;
    ((GDExtensionInterfaceClassdbRegisterExtensionClassMethod)get("classdb_register_extension_class_method"))(library,&class_name,&method);
    get_destructor(GDEXTENSION_VARIANT_TYPE_STRING)(&empty_string);
    get_destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&method_name);get_destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&size_name);get_destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&empty_name);
    for(int i=0;i<2;i++)get_destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&arg_names[i]);
}
static void deinitialize(void *userdata,GDExtensionInitializationLevel level){
    (void)userdata;if(level!=GDEXTENSION_INITIALIZATION_SCENE)return;
    unregister_class(library,&class_name);
    get_destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&class_name);get_destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&parent_name);
}
#define LOAD(name,type,symbol) name=(type)get(symbol)
__declspec(dllexport) GDExtensionBool priest_cape_init(GDExtensionInterfaceGetProcAddress get,GDExtensionClassLibraryPtr lib,GDExtensionInitialization *init){
    library=lib;
    LOAD(to_type,GDExtensionInterfaceGetVariantToTypeConstructor,"get_variant_to_type_constructor");LOAD(from_type,GDExtensionInterfaceGetVariantFromTypeConstructor,"get_variant_from_type_constructor");LOAD(variant_type,GDExtensionInterfaceVariantGetType,"variant_get_type");LOAD(new_nil,GDExtensionInterfaceVariantNewNil,"variant_new_nil");LOAD(bytes_write,GDExtensionInterfacePackedByteArrayOperatorIndex,"packed_byte_array_operator_index");LOAD(bytes_read,GDExtensionInterfacePackedByteArrayOperatorIndexConst,"packed_byte_array_operator_index_const");LOAD(name_new,GDExtensionInterfaceStringNameNewWithUtf8Chars,"string_name_new_with_utf8_chars");LOAD(get_destructor,GDExtensionInterfaceVariantGetPtrDestructor,"variant_get_ptr_destructor");LOAD(construct_object,GDExtensionInterfaceClassdbConstructObject,"classdb_construct_object");LOAD(set_instance,GDExtensionInterfaceObjectSetInstance,"object_set_instance");LOAD(unregister_class,GDExtensionInterfaceClassdbUnregisterExtensionClass,"classdb_unregister_extension_class");
    init->minimum_initialization_level=GDEXTENSION_INITIALIZATION_SCENE;init->userdata=(void*)get;init->initialize=initialize;init->deinitialize=deinitialize;return 1;
}
