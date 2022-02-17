//
//  LSCRunScriptConfig.m
//  LuaScriptCore
//
//  Created by admin on 2019/3/12.
//  Copyright © 2019年 hy. All rights reserved.
//

#import "LSCScriptController.h"
#import "LSCScriptController+Private.h"

@implementation LSCScriptController

- (void)setTimeout:(NSInteger)timeout
{
    _timeout = timeout;
}

- (void)forceExit
{
    self.isForceExit = YES;
}


@end
