//
//  NativePerson.m
//  LuaScriptCore
//
//  Created by admin on 17/3/22.
//  Copyright © 2017年 hy. All rights reserved.
//

#import "NativePerson.h"
#import "Person.h"

@implementation NativePerson

- (void)speak:(NSString *)content
{
    NSLog(@"%@ speak:\"%@\"", self.name, content);
}

+ (void)printPersonName:(NativePerson *)person
{
    NSLog(@"person name = %@", person.name);
}

+ (Person *)createPerson
{
    return [[Person alloc] init];
}

@end
