//
//  Person.h
//  LuaScriptCore
//
//  Created by admin on 16/11/14.
//  Copyright © 2016年 hy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSCExportType.h"
#import "LSCExportTypeAnnotation.h"

@class NativePerson;
@class LSCTuple;
@class LSCFunction;

@interface Person : NSObject <LSCExportType>

@property (nonatomic, copy) NSString *name;

- (void)speak:(NSString *)content;
- (void)speakWithAge:(BOOL)age;
- (LSCTuple *)test;

+ (void)printPersonName:(Person *)person;

+ (Person *)createPerson;

+ (NativePerson *)createNativePerson;

+ (void)testFuncRelease:(LSCFunction *)func;

+ (BOOL)returnBoolean;

+ (char)returnChar;

- (instancetype)initWithName:(NSString *)name;

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age;

@end
