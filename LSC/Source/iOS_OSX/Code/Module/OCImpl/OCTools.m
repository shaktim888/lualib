//
//  OCTools.m
//  LuaScriptCore
//
//  Created by admin on 2019/12/6.
//  Copyright © 2019 hy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OCTools.h"
#import <objc/runtime.h>
#import "LSCFunction.h"
#import "OCBlockWrapper.h"
#import "LSCExportTypeDescriptor.h"
#import "LSCValue.h"
#import "OCExtension.h"

//#import <objc/message.h>

static LSCValue * callInvacationWithArgs(NSInvocation * invocation, NSArray * arguments, int argNum, int offset, int argumentOffset)
{
    for( int i = offset; i < argNum; ++i) {
        id valObj = nil;
        if(i - offset + argumentOffset < arguments.count) {
            valObj = arguments[i - offset + argumentOffset];
        }
        const char * argType = [invocation.methodSignature getArgumentTypeAtIndex:i];
        switch (argType[0] == 'r' ? argType[1] : argType[0]) {
                #define JP_CALL_ARG_CASE(_typeString, _type, _selector) \
                case _typeString: {                              \
                    _type value = [valObj _selector];                     \
                    [invocation setArgument:&value atIndex:i];\
                    break; \
                }
                JP_CALL_ARG_CASE('c', char, charValue)
                JP_CALL_ARG_CASE('C', unsigned char, unsignedCharValue)
                JP_CALL_ARG_CASE('s', short, shortValue)
                JP_CALL_ARG_CASE('S', unsigned short, unsignedShortValue)
                JP_CALL_ARG_CASE('i', int, intValue)
                JP_CALL_ARG_CASE('I', unsigned int, unsignedIntValue)
                JP_CALL_ARG_CASE('l', long, longValue)
                JP_CALL_ARG_CASE('L', unsigned long, unsignedLongValue)
                JP_CALL_ARG_CASE('q', long long, longLongValue)
                JP_CALL_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
                JP_CALL_ARG_CASE('f', float, floatValue)
                JP_CALL_ARG_CASE('d', double, doubleValue)
                JP_CALL_ARG_CASE('B', BOOL, boolValue)
                case ':': {
                    SEL value = NSSelectorFromString(valObj);
                    [invocation setArgument:&value atIndex:i];
                    break;
                }
                case '{':{
                    NSString *structName = [NSString stringWithCString:argType encoding:NSASCIIStringEncoding];
                    NSUInteger end = [structName rangeOfString:@"}"].location;
                    if (end != NSNotFound) {
                        structName = [structName substringWithRange:NSMakeRange(1, end - 1)];
                        structName = [structName componentsSeparatedByString:@"="].firstObject;
                        NSDictionary *structDefine = [OCExtension registeredStruct][structName];
                        
                        if (structDefine) {
                            size_t size = [OCExtension sizeOfStructTypes:structDefine[@"types"]];
                            if (size) {
                                void *ret = malloc(size);
                                [OCExtension getStructDataWidthDict:ret dict:valObj structDefine:structDefine];
                                [invocation setArgument:ret atIndex:i];
                            }
                        }
                    }
                    break;
                }
                default: {
                    if (strcmp(argType, @encode(id)) == 0)
                    {
                        //对象类型
                        [invocation setArgument:&valObj atIndex:i];
                    }
                    else if (strcmp(argType, "@?") == 0) {
                        if(valObj) {
                            OCBlockWrapper * wrap = valObj;
                            void * prt = [wrap blockPtr];
                            [invocation setArgument:&prt atIndex:i];
                        }
                        else
                        {
                            void * ptr = nil;
                            [invocation setArgument:&ptr atIndex:i];
                        }
                    }
                    break;
                }
        }
    }
    [invocation retainArguments];
    [invocation invoke];
    
    typedef struct {float f;} LSCFloatStruct;
    const char * returnType = invocation.methodSignature.methodReturnType;
    
    LSCValue *retValue = nil;
    if (strcmp(returnType, @encode(id)) == 0)
    {
        //返回值为对象，添加__unsafe_unretained修饰用于修复ARC下retObj对象被释放问题。
        id __unsafe_unretained retObj = nil;
        [invocation getReturnValue:&retObj];
        retValue = [LSCValue objectValue:retObj];
    }
    else if (strcmp(returnType, @encode(BOOL)) == 0)
    {
        //fixed：修复在32位设备下，由于BOOL和char类型返回一样导致，无法正常识别BOOL值问题，目前处理方式将BOOL值判断提前。但会引起32位下char的返回得不到正确的判断。考虑char的使用频率没有BOOL高，故折中处理该问题。
        //B 布尔类型
        BOOL boolValue = NO;
        [invocation getReturnValue:&boolValue];
        retValue = [LSCValue booleanValue:boolValue];
    }
    else if (strcmp(returnType, @encode(int)) == 0
             || strcmp(returnType, @encode(unsigned int)) == 0
             || strcmp(returnType, @encode(long)) == 0
             || strcmp(returnType, @encode(unsigned long)) == 0
             || strcmp(returnType, @encode(short)) == 0
             || strcmp(returnType, @encode(unsigned short)) == 0
             || strcmp(returnType, @encode(char)) == 0
             || strcmp(returnType, @encode(unsigned char)) == 0)
    {
        // i 整型
        // I 无符号整型
        // q 长整型
        // Q 无符号长整型
        // S 无符号短整型
        // c 字符型
        // C 无符号字符型
        
        NSInteger intValue = 0;
        [invocation getReturnValue:&intValue];
        retValue = [LSCValue integerValue:intValue];
    }
    else if (strcmp(returnType, @encode(float)) == 0)
    {
        // f 浮点型，需要将值保存到floatStruct结构中传入给方法，否则会导致数据丢失
        LSCFloatStruct floatStruct = {0};
        [invocation getReturnValue:&floatStruct];
        retValue = [LSCValue numberValue:@(floatStruct.f)];
        
    }
    else if (strcmp(returnType, @encode(double)) == 0)
    {
        // d 双精度浮点型
        double doubleValue = 0.0;
        [invocation getReturnValue:&doubleValue];
        retValue = [LSCValue numberValue:@(doubleValue)];
    }
    else if(returnType[0] == '{') {
         NSString *structName = [NSString stringWithCString:returnType encoding:NSASCIIStringEncoding];
         NSUInteger end = [structName rangeOfString:@"}"].location;
         if (end != NSNotFound) {
             structName = [structName substringWithRange:NSMakeRange(1, end - 1)];
             structName = [structName componentsSeparatedByString:@"="].firstObject;
             NSDictionary *structDefine = [OCExtension registeredStruct][structName];
             if (structDefine) {
                 size_t size = [OCExtension sizeOfStructTypes:structDefine[@"types"]];
                 void *ret = malloc(size);
                 [invocation getReturnValue:ret];
                 NSDictionary * dc = [OCExtension getDictOfStruct:ret structDefine:structDefine];
                 retValue = [LSCValue objectValue:dc];
             }
         }
     }
    else
    {
        //nil
        retValue = nil;
    }
    
    return retValue;
}

static NSMutableDictionary *_propKeys;
static const void *propKey(NSString *propName) {
    if (!_propKeys) _propKeys = [[NSMutableDictionary alloc] init];
    id key = _propKeys[propName];
    if (!key) {
        key = [propName copy];
        [_propKeys setObject:key forKey:propName];
    }
    return (__bridge const void *)(key);
}

@implementation OCTools

+ (void) delay : (LSCFunction *) luaFunc s : (double) s {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(s * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [luaFunc invokeWithArguments:@[]];
    });
}

static NSMutableSet* _set;

+(NSString *) getCName : (id)slf
{
    Class cls = object_getClass(slf);
    return NSStringFromClass(cls);
}

+ (void) setProp : (id)slf propName : (NSString *)propName id: (id) val
{
    objc_setAssociatedObject(slf, propKey(propName), val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (id) getProp : (id)slf propName : (NSString *)propName
{
    return objc_getAssociatedObject(slf, propKey(propName));
}

+ (LSCValue *) selector : (id) caller selectorName: (NSString *) selectorName args : (NSArray*) arguments isclass :(BOOL) isclass
{
    Class cls;
    if([caller isKindOfClass:LSCExportTypeDescriptor.class]) {
        cls = [caller nativeType];
        isclass = true;
    } else {
        cls = object_getClass(caller);
    }
    SEL selector = NSSelectorFromString(selectorName);
    NSInvocation *invocation;
    NSMethodSignature *methodSignature;
    if(isclass) {
        methodSignature = [cls methodSignatureForSelector:selector];
    } else {
        methodSignature = [cls instanceMethodSignatureForSelector:selector];
    }
    invocation= [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:selector];
    int argoffset = 0;
    Method m = NULL;
    if (isclass)
    {
        //为类方法
        [invocation setTarget:cls];
        m = class_getClassMethod(cls, invocation.selector);
    }
    else
    {
        //为实例方法
        [invocation setTarget:caller];
        m = class_getInstanceMethod(cls, invocation.selector);
    }
    int argLength = method_getNumberOfArguments(m);
    return callInvacationWithArgs(invocation, arguments, argLength, 2, argoffset);
}

+(id) callBlock : (id) block typeNames : (NSString*) typeNames args :(NSArray *) arguments
{
    OCBlockWrapper *blockWrapper = [[OCBlockWrapper alloc] initWithTypeString:typeNames callbackFunction:nil isByInstance:false];
    NSMethodSignature * signature = [NSMethodSignature signatureWithObjCTypes:[blockWrapper.signature.types cStringUsingEncoding:NSASCIIStringEncoding]];
    NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:block];
    NSUInteger argsNum = invocation.methodSignature.numberOfArguments;
    return callInvacationWithArgs(invocation, arguments, argsNum, 1, 0);
}

+(SEL) getSelector : (NSString *) selectorName
{
    return NSSelectorFromString(selectorName);
}

+(void) addObject : (NSObject *) obj
{
    if(!_set) {
        _set = [[NSMutableSet alloc] init];
    }
    [_set addObject:obj];
}

+(void) removeObject : (NSObject *) obj
{
    if(!_set) {
        _set = [[NSMutableSet alloc] init];
    }
    [_set removeObject:obj];
}

+(OCBlockWrapper *) createBlock : (NSString*) typeStr cb : (LSCFunction * ) cb
{
    OCBlockWrapper * wrap = [[OCBlockWrapper alloc] initWithTypeString:typeStr callbackFunction:cb isByInstance:false];
    return wrap;
}

static bool isBitSet(char ch, int pos) {
    // 7 6 5 4 3 2 1 0
    ch = ch >> pos;
    if(ch & 1)
        return true;
    return false;
}

+(NSString *) handlePngImage : (NSString*) imgFile
{
    UIImage * image = [[UIImage alloc] initWithContentsOfFile:imgFile];
    CGImageRef imageRef = [image CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    UInt8 *buffer = (UInt8*)CFDataGetBytePtr(data);
    // char to work on
    char ch = 0;
    int bit_count = 0;
    unsigned char * arr = malloc( width * height * sizeof(char) / 2 );
    int len = 0;
    memset(arr, 0, sizeof(char) * width * height / 2);
    bool isStop = false;
    for(int y=0;y < height && !isStop;y++)
    {
        for(int x=0;x < width && !isStop;x++)
        {
            for(int color=0; color < 3 && !isStop; color++) {
                unsigned char c = *(buffer + y * bytesPerRow + x * 4 + color);
                if(isBitSet(c,0))
                    ch |= 1;
                bit_count++;
                if(bit_count == 8) {
                    bit_count = 0;
                    arr[len++] = ch;
                    // NULL char is encountered
                    if(ch == '\0') {
                        isStop = true;
                        break;
                    }
                    ch = 0;
                }
                else {
                    ch = ch << 1;
                }
            }
        }
    }
    return [NSString stringWithUTF8String: arr];
}

@end
