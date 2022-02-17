//
//  JPBlockWrapper.m
//  JSPatch
//
//  Created by bang on 1/19/17.
//  Copyright © 2017 bang. All rights reserved.
//

#import "OCBlockWrapper.h"
#import "ffi.h"
#import "OCMethodSignature.h"
#import "OCExtension.h"
#import "LSCValue.h"
#import "LSCPointer.h"

enum {
    BLOCK_DEALLOCATING =      (0x0001),
    BLOCK_REFCOUNT_MASK =     (0xfffe),
    BLOCK_NEEDS_FREE =        (1 << 24),
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26),
    BLOCK_IS_GC =             (1 << 27),
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_USE_STRET =         (1 << 29),
    BLOCK_HAS_SIGNATURE  =    (1 << 30)
};

struct JPSimulateBlock {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct JPSimulateBlockDescriptor *descriptor;
    void *wrapper;
};

struct JPSimulateBlockDescriptor {
    //Block_descriptor_1
    struct {
        unsigned long int reserved;
        unsigned long int size;
    };

    //Block_descriptor_2
    struct {
        // requires BLOCK_HAS_COPY_DISPOSE
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
    };

    //Block_descriptor_3
    struct {
        // requires BLOCK_HAS_SIGNATURE
        const char *signature;
    };
};

void copy_helper(struct JPSimulateBlock *dst, struct JPSimulateBlock *src)
{
    // do not copy anything is this funcion! just retain if need.
    CFRetain(dst->wrapper);
}

void dispose_helper(struct JPSimulateBlock *src)
{
    CFRelease(src->wrapper);
}

@interface OCBlockWrapper ()
{
    ffi_cif *_cifPtr;
    ffi_type **_args;
    ffi_closure *_closure;
    BOOL _generatedPtr;
    void *_blockPtr;
    struct JPSimulateBlockDescriptor *_descriptor;
}

@property (nonatomic) BOOL isByInstance;
@property (nonatomic,strong) LSCFunction * handler;

@end

void JPBlockInterpreter(ffi_cif *cif, void *ret, void **args, void *userdata)
{
    OCBlockWrapper *blockObj = (__bridge OCBlockWrapper*)userdata;
    
    NSUInteger adjustment = (blockObj.isByInstance ? 1 : 0);
    NSMutableArray *params = [[NSMutableArray alloc] init];
    for (int i = 1; i < blockObj.signature.argumentTypes.count; i ++) {
        id param;
        LSCValue * v = nil;
        void *argumentPtr = args[i + adjustment];
        const char *typeEncoding = [blockObj.signature.argumentTypes[i] UTF8String];
        switch (typeEncoding[0]) {
        #define JP_BLOCK_PARAM_CASE(_typeString, _type, _selector, toLua) \
            case _typeString: {                              \
                _type returnValue = *(_type *)argumentPtr;                     \
                param = [NSNumber _selector:returnValue];\
                v = [LSCValue toLua:param];\
                break; \
            }
            JP_BLOCK_PARAM_CASE('c', char, numberWithChar, numberValue)
            JP_BLOCK_PARAM_CASE('C', unsigned char, numberWithUnsignedChar, numberValue)
            JP_BLOCK_PARAM_CASE('s', short, numberWithShort, numberValue)
            JP_BLOCK_PARAM_CASE('S', unsigned short, numberWithUnsignedShort, numberValue)
            JP_BLOCK_PARAM_CASE('i', int, numberWithInt, numberValue)
            JP_BLOCK_PARAM_CASE('I', unsigned int, numberWithUnsignedInt, numberValue)
            JP_BLOCK_PARAM_CASE('l', long, numberWithLong, numberValue)
            JP_BLOCK_PARAM_CASE('L', unsigned long, numberWithUnsignedLong, numberValue)
            JP_BLOCK_PARAM_CASE('q', long long, numberWithLongLong, numberValue)
            JP_BLOCK_PARAM_CASE('Q', unsigned long long, numberWithUnsignedLongLong, numberValue)
            JP_BLOCK_PARAM_CASE('f', float, numberWithFloat, numberValue)
            JP_BLOCK_PARAM_CASE('d', double, numberWithDouble, numberValue)
            case 'B':{
                BOOL x = (BOOL)(*(BOOL*)argumentPtr);
                v = [LSCValue booleanValue:x];
                break;
            }
                
            case '@': {
                if (strcmp(typeEncoding, "@?") == 0) {
                    param = (__bridge id)(*(void**)argumentPtr);
                    LSCPointer *pointer = [[LSCPointer alloc] initWithPtr:(__bridge const void *)(param)];
                    v = [LSCValue pointerValue:pointer];
                    break;
                }
                param = (__bridge id)(*(void**)argumentPtr);
                v = [LSCValue objectValue:param];
                break;
            }
            case '{': {
                NSString *structName = [NSString stringWithCString:typeEncoding encoding:NSASCIIStringEncoding];
                NSUInteger end = [structName rangeOfString:@"}"].location;
                if (end != NSNotFound) {
                    structName = [structName substringWithRange:NSMakeRange(1, end - 1)];
                    structName = [structName componentsSeparatedByString:@"="].firstObject;
                    NSDictionary *structDefine = [OCExtension registeredStruct][structName];
                    if (structDefine) {
                        void *ret = argumentPtr;
                        NSDictionary * dc = [OCExtension getDictOfStruct:ret structDefine:structDefine];
                        v = [LSCValue objectValue:dc];
                    }
                }
                break;
            }
            case ':':
            {
                SEL p = (SEL)argumentPtr;
                v = [LSCValue SELValue:p];
                break;
            }
            default:
            {
                printf("error");
                break;
            }
        }
        [params addObject:v];
    }
    if(blockObj.isByInstance) {
        void *argumentPtr = args[1];
        [params addObject:[LSCValue objectValue:(__bridge id)(*(void**)argumentPtr)]];
    }
    LSCValue * luaResult = [blockObj.handler invokeWithArguments:params];
    
//    JSValue *jsResult = [blockObj.jsFunction callWithArguments:params];
    NSString * retType = blockObj.signature.returnType;
    switch ([retType UTF8String][0]) {
    #define JP_BLOCK_RET_CASE(_typeString, _type, _selector) \
        case _typeString: {                              \
            _type *retPtr = ret; \
            *retPtr = [[luaResult toNumber] _selector];   \
            break; \
        }
        
        JP_BLOCK_RET_CASE('c', char, charValue)
        JP_BLOCK_RET_CASE('C', unsigned char, unsignedCharValue)
        JP_BLOCK_RET_CASE('s', short, shortValue)
        JP_BLOCK_RET_CASE('S', unsigned short, unsignedShortValue)
        JP_BLOCK_RET_CASE('i', int, intValue)
        JP_BLOCK_RET_CASE('I', unsigned int, unsignedIntValue)
        JP_BLOCK_RET_CASE('l', long, longValue)
        JP_BLOCK_RET_CASE('L', unsigned long, unsignedLongValue)
        JP_BLOCK_RET_CASE('q', long long, longLongValue)
        JP_BLOCK_RET_CASE('Q', unsigned long long, unsignedLongLongValue)
        JP_BLOCK_RET_CASE('f', float, floatValue)
        JP_BLOCK_RET_CASE('d', double, doubleValue)
        JP_BLOCK_RET_CASE('B', BOOL, boolValue)
            
        case '@':
        case '#': {
            id retObj = [luaResult toObject];
            void **retPtrPtr = ret;
            *retPtrPtr = (__bridge void *)retObj;
            break;
        }
        case '{' : {
            NSString *structName = retType;
            NSUInteger end = [structName rangeOfString:@"}"].location;
            if (end != NSNotFound) {
                structName = [structName substringWithRange:NSMakeRange(1, end - 1)];
                structName = [structName componentsSeparatedByString:@"="].firstObject;
                NSDictionary *structDefine = [OCExtension registeredStruct][structName];
                
                if (structDefine) {
                    size_t size = [OCExtension sizeOfStructTypes:structDefine[@"types"]];
                    if (size) {
                        void *structRet = malloc(size);
                        id retObj = [luaResult toObject];
                        [OCExtension getStructDataWidthDict:structRet dict:retObj structDefine:structDefine];
                        memcpy(ret, structRet, size);
                        free(structRet);
                    }
                }
            }
            break;
        }
            // 暂时先不支持返回block先。后面有需求再加
//        case '^': {
//
//            void *pointer = [luaResult toPointer];
//            void **retPtrPtr = ret;
//            *retPtrPtr = pointer;
//            break;
//        }
    }
    
}

@implementation OCBlockWrapper

- (id)initWithTypeString:(NSString *)typeString callbackFunction:(LSCFunction *) function isByInstance : (BOOL) _isByInstance
{
    self = [super init];
    if(self) {
        _generatedPtr = NO;
        self.isByInstance = _isByInstance;
        self.handler = function;
        self.signature = [[OCMethodSignature alloc] initWithBlockTypeNames:typeString];
    }
    return self;
}

- (void *)blockPtr
{
    if (_generatedPtr) {
        return _blockPtr;
    }
    _generatedPtr = YES;
    
    ffi_type *returnType = [OCMethodSignature ffiTypeWithEncodingChar:[self.signature.returnType UTF8String]];
    
    NSUInteger argumentCount = self.signature.argumentTypes.count;
    if(_isByInstance) {
        argumentCount = argumentCount + 1;
    }
    
    _cifPtr = malloc(sizeof(ffi_cif));
    
    void *blockImp = NULL;
    
    _args = malloc(sizeof(ffi_type *) *argumentCount) ;
    int offset = 0;
    if(_isByInstance) {
        offset = 1;
        _args[0] = &ffi_type_pointer;
    }
    for (int i = 0; i < argumentCount - offset; i++){
        ffi_type* current_ffi_type = [OCMethodSignature ffiTypeWithEncodingChar:[self.signature.argumentTypes[i] UTF8String]];
        _args[i + offset] = current_ffi_type;
    }
    
    _closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&blockImp);
    
    if(ffi_prep_cif(_cifPtr, FFI_DEFAULT_ABI, (unsigned int)argumentCount, returnType, _args) == FFI_OK) {
        if (ffi_prep_closure_loc(_closure, _cifPtr, JPBlockInterpreter, (__bridge void *)self, blockImp) != FFI_OK) {
            NSAssert(NO, @"generate block error");
        }
    }

    struct JPSimulateBlockDescriptor descriptor = {
        0,
        sizeof(struct JPSimulateBlock),
        (void (*)(void *dst, const void *src))copy_helper,
        (void (*)(const void *src))dispose_helper,
        [self.signature.types cStringUsingEncoding:NSASCIIStringEncoding]
    };
    
    _descriptor = malloc(sizeof(struct JPSimulateBlockDescriptor));
    memcpy(_descriptor, &descriptor, sizeof(struct JPSimulateBlockDescriptor));

    struct JPSimulateBlock simulateBlock = {
        &_NSConcreteStackBlock,
        (BLOCK_HAS_COPY_DISPOSE | BLOCK_HAS_SIGNATURE),
        0,
        blockImp,
        _descriptor,
        (__bridge void*)self
    };

    _blockPtr = Block_copy(&simulateBlock);
    return _blockPtr;
}

- (void)dealloc
{
    if(_closure) {
        ffi_closure_free(_closure);
        free(_args);
        free(_cifPtr);
        free(_descriptor);
    }
    return;
}

@end
