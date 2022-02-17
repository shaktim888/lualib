//
//  TestModule.m
//  LuaScriptCore
//
//  Created by admin on 16/11/14.
//  Copyright © 2016年 hy. All rights reserved.
//

#import "TestModule.h"
#import "LSCTuple.h"

@implementation TestModule

+ (NSString *)test
{
    return @"Hello World!";
}

+ (NSString *)testWithMsg:(NSString *)msg
{
    return [NSString stringWithFormat:@"test msg = %@", msg];
}

+ (LSCTuple *)testTuple
{
    LSCTuple *tuple = [[LSCTuple alloc] init];
    [tuple addReturnValue:@"Hello"];
    [tuple addReturnValue:@"World"];
    
    return tuple;
}


@end
