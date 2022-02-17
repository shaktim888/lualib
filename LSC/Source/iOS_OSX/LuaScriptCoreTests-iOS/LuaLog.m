//
//  LuaLog.m
//  LuaScriptCore
//
//  Created by admin on 2017/9/6.
//  Copyright © 2017年 hy. All rights reserved.
//

#import "LuaLog.h"

@implementation LuaLog

+ (void)writeLog:(NSString *)msg
{
    NSLog(@"%@ log = %@", self, msg);
}

@end
