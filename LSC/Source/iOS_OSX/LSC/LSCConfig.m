//
//  LSCConfig.m
//  LuaScriptCore
//
//  Created by admin on 2019/4/4.
//  Copyright © 2019年 hy. All rights reserved.
//

#import "LSCConfig.h"

@implementation LSCConfig

+ (instancetype)defaultConfig
{
    static LSCConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        config = [[LSCConfig alloc] init];
    });
    
    return config;
}

@end
