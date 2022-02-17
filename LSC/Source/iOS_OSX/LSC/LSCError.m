//
//  LSCError.m
//  LuaScriptCore
//
//  Created by admin on 2019/3/11.
//  Copyright © 2019年 hy. All rights reserved.
//

#import "LSCError.h"

@implementation LSCError

- (instancetype)initWithSession:(LSCSession *)session
                        message:(NSString *)message
{
    if (self = [super init])
    {
        _session = session;
        _message = [message copy];
    }
    return self;
}

@end
