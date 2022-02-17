//
//  NSObject+OCClassWrap.m
//  LuaScriptCore
//
//  Created by admin on 2019/12/6.
//  Copyright © 2019 hy. All rights reserved.
//

#import "OCClassWrap.h"
#import "LSCFunction.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "OCMethodSignature.h"
#import "Aspects.h"
#import "OCBlockWrapper.h"
#import "LSCValue.h"
#import "LSCExportsTypeManager.h"

static NSString *trim(NSString *string)
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@interface OCClassWrap() {
    Class cls;
}
@end

@implementation OCClassWrap
    
- (instancetype)initWithClass:(Class)c {
    if (self = [super init]) {
        cls = c;
    }
    return self;
}

+ (instancetype ) create: (NSString *)classDeclaration {
    NSScanner *scanner = [NSScanner scannerWithString:classDeclaration];
    
    NSString *className;
    NSString *superClassName;
    NSString *protocolNames;
    [scanner scanUpToString:@":" intoString:&className];
    if (!scanner.isAtEnd) {
        scanner.scanLocation = scanner.scanLocation + 1;
        [scanner scanUpToString:@"<" intoString:&superClassName];
        if (!scanner.isAtEnd) {
            scanner.scanLocation = scanner.scanLocation + 1;
            [scanner scanUpToString:@">" intoString:&protocolNames];
        }
    }
    className = trim(className);
    superClassName = trim(superClassName);
    Class c = NSClassFromString(className);
    if(c) {
        [LSCExportsTypeManager createTypeDescriptorWithClass:className typeName:className cls:c];
        return [[OCClassWrap alloc] initWithClass:c];
    }
    if (!superClassName) superClassName = @"NSObject";
    NSArray *protocols = [protocolNames length] ? [protocolNames componentsSeparatedByString:@","] : nil;
    
    Class s = NSClassFromString(superClassName);
    c = objc_allocateClassPair(s, [className UTF8String],0);
    objc_registerClassPair(c);
    class_addProtocol(c, @protocol(LSCExportType));
    for(int i = 0 ; i < protocols.count; i++) {
        Protocol * p = objc_getProtocol([trim(protocols[i]) UTF8String]);
        if(p) {
            class_addProtocol(c, p);
        }
    }
    return [[OCClassWrap alloc] initWithClass:c];
}

-(void) addM:(NSString *)mName sigString : (NSString *) sigString handler : (LSCFunction*) handler
{
    NSArray * funcNameArr = [mName componentsSeparatedByString:@":"];
    NSMutableString *selectorName = [funcNameArr.firstObject mutableCopy];
    OCBlockWrapper *blockWrapper = [[OCBlockWrapper alloc] initWithTypeString:sigString callbackFunction:handler isByInstance:true];
    id getBlock = blockWrapper.blockPtr;
    IMP getImp = imp_implementationWithBlock(getBlock);
    NSMutableString *typeDescStr = [NSMutableString string];
    [typeDescStr appendString:blockWrapper.signature.returnType];
    [typeDescStr appendString:@"@:"];
    for (int i = 1; i < blockWrapper.signature.argumentTypes.count; i ++) {
        if(i == 1) {
            [selectorName appendString:@":"];
        } else {
            if(funcNameArr.count > i) {
                [selectorName appendFormat:@"%@:", funcNameArr[i - 1]];
            } else {
                [selectorName appendFormat:@"arg%d:", i - 1];
            }
        }
        [typeDescStr appendString:blockWrapper.signature.argumentTypes[i]];
    }
    class_addMethod(cls, NSSelectorFromString(selectorName), getImp, [typeDescStr UTF8String]);
}

-(void) addMS:(NSString *)mName sigString : (NSString *) sigString handler : (LSCFunction*) handler
{
    NSArray * funcNameArr = [mName componentsSeparatedByString:@":"];
    NSMutableString *selectorName = [funcNameArr.firstObject mutableCopy];
    OCBlockWrapper *blockWrapper = [[OCBlockWrapper alloc] initWithTypeString:sigString callbackFunction:handler isByInstance:true];
    id getBlock = blockWrapper.blockPtr;
    IMP getImp = imp_implementationWithBlock(getBlock);
    NSMutableString *typeDescStr = [NSMutableString string];
    [typeDescStr appendString:blockWrapper.signature.returnType];
    [typeDescStr appendString:@"@:"];
    for (int i = 1; i < blockWrapper.signature.argumentTypes.count; i ++) {
        if(i == 1) {
            [selectorName appendString:@":"];
        } else {
            if(funcNameArr.count > i) {
                [selectorName appendFormat:@"%@:", funcNameArr[i - 1]];
            }else {
                [selectorName appendFormat:@"arg%d:", i - 1];
            }
        }
        [typeDescStr appendString:blockWrapper.signature.argumentTypes[i]];
    }
    class_addMethod(objc_getMetaClass([NSStringFromClass(cls) UTF8String]), NSSelectorFromString(selectorName), getImp, [typeDescStr UTF8String]);
}

- (bool) setM:(NSString *)selName
      handler:(LSCFunction *)handler
          isS:(BOOL)isClass
       option:(int)option
{
    Class class = cls;
    SEL selector = NSSelectorFromString(selName);
    Method m = NULL;
    if (isClass) {
        class = objc_getMetaClass([NSStringFromClass(class) UTF8String]);
        m = class_getClassMethod(cls, selector);
    } else {
        m = class_getInstanceMethod(cls, selector);
    }
    
    NSError *error;
    [class aspect_hookSelector:selector withOptions:option usingBlock:^(id<AspectInfo> aspectInfo) {
        NSMutableArray *params = [[NSMutableArray alloc] init];
        
        [aspectInfo.arguments enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            char *argType = method_copyArgumentType(m, (int)idx);
            LSCValue * v = [LSCValue nilValue];
            if (strcmp(argType, @encode(float)) == 0
                || strcmp(argType, @encode(double)) == 0
                || strcmp(argType, @encode(int)) == 0
                || strcmp(argType, @encode(int)) == 0
                || strcmp(argType, @encode(unsigned int)) == 0
                || strcmp(argType, @encode(long)) == 0
                || strcmp(argType, @encode(unsigned long)) == 0
                || strcmp(argType, @encode(short)) == 0
                || strcmp(argType, @encode(unsigned short)) == 0
                || strcmp(argType, @encode(char)) == 0
                || strcmp(argType, @encode(unsigned char)) == 0)
            {
                //浮点型数据
                v = [LSCValue numberValue:obj];
            }
            else if (strcmp(argType, @encode(BOOL)) == 0)
            {
                v = [LSCValue booleanValue:obj];
            }
            else if (strcmp(argType, @encode(id)) == 0)
            {
                v = [LSCValue objectValue:obj];
            }
            [params addObject:v];
        }];
        
        LSCValue * this = [LSCValue objectValue:aspectInfo.instance];
        [params addObject:this];
        
        // 创建一个luaFunction 传回去
        
        LSCValue * result = [handler invokeWithArguments:params];

        const char *argumentType = aspectInfo.originalInvocation.methodSignature.methodReturnType;

        switch (argumentType[0] == 'r' ? argumentType[1] : argumentType[0]) {

                #define OC_CALL_ARG_CASE(_typeString, _type, _selector) \
                case _typeString: {                              \
                _type value = (_type)[result _selector];                     \
                [aspectInfo.originalInvocation setReturnValue:&value];\
                break; \
                }
                OC_CALL_ARG_CASE('c', char, toInteger)
                OC_CALL_ARG_CASE('C', unsigned char, toInteger)
                OC_CALL_ARG_CASE('s', short, toInteger)
                OC_CALL_ARG_CASE('S', unsigned short, toInteger)
                OC_CALL_ARG_CASE('i', int, toInteger)
                OC_CALL_ARG_CASE('I', unsigned int, toInteger)
                OC_CALL_ARG_CASE('l', long, toInteger)
                OC_CALL_ARG_CASE('L', unsigned long, toInteger)
                OC_CALL_ARG_CASE('q', long long, toInteger)
                OC_CALL_ARG_CASE('Q', unsigned long long, toInteger)
                OC_CALL_ARG_CASE('f', float, toDouble)
                OC_CALL_ARG_CASE('d', double, toDouble)
                OC_CALL_ARG_CASE('B', BOOL, toBoolean)

            case ':': {
                SEL value = NSSelectorFromString([result toString]);
                [aspectInfo.originalInvocation setReturnValue:&value];
                break;
            }
            case '{': {
                void *pointer = (__bridge void *)([result toObject]);
                [aspectInfo.originalInvocation setReturnValue:&pointer];
                break;
            }
            default: {
                void *pointer = (__bridge void *)([result toObject]);
                if(pointer) {
                    [aspectInfo.originalInvocation setReturnValue:pointer];
                }
            }
        }
    } error:&error];
    
    if(error)
    {
        return false;
    }
    return true;
}

@end
