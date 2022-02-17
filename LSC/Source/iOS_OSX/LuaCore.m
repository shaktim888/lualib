//
//  LuaCore.m
//  LuaScriptCore
//
//  Created by admin on 2019/12/17.
//  Copyright © 2019 vimfung. All rights reserved.
//

#import "LuaCore.h"
#import "LSCContext.h"

void initLuaCore(void) {
    LSCContext * context = [[LSCContext alloc] init];
    //捕获异常
    [context onException:^(NSString *message) {
        NSLog(@"error = %@", message);
    }];
    [context evalScriptFromString:@"require(\"main\");"];
}
