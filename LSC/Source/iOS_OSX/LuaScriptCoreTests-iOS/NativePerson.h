//
//  NativePerson.h
//  LuaScriptCore
//
//  Created by admin on 17/3/22.
//  Copyright © 2017年 hy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSCExportType.h"

@class Person;

@interface NativePerson : NSObject <LSCExportType>

@property (nonatomic, copy) NSString *name;

- (void)speak:(NSString *)content;

+ (void)printPersonName:(NativePerson *)person;

+ (Person *)createPerson;

@end
