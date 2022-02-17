//
//  LuaCore.m
//  LuaScriptCore
//
//  Created by admin on 2019/12/17.
//  Copyright © 2019 vimfung. All rights reserved.
//

#import "lualib.h"
#import "LSCContext.h"
#import "LSCEngineAdapter.h"
#import "LSCValue.h"
#import "luacore.h"

static bool tag = false;

static bool _initLSC()
{
    LSCContext * context = [[LSCContext alloc] init];
#if DEBUG
    //捕获异常
    [context onException:^(NSString *message) {
        NSLog(@"error = %@", message);
    }];
#endif
    [context evalScriptFromString:@"require(\"main\");"];
    tag = [[context getGlobalForName:@"_GTAG"] toBoolean];
    return tag;
}

static bool _getTag()
{
    return tag;
}

static bool _isClass(id obj)
{
    return false;
}

struct LSCStruct
{
    bool (*initLSC)(void);
    bool (*getTag)(void);
    bool (*isClass)(id);
};
static struct LSCStruct lsc;

static void initStuct2()
{
    lsc.initLSC = 0xff;
    lsc.initLSC = 0xfe;
    lsc.getTag = 0xfc;
}

static void initStruct1()
{
    lsc.initLSC = _initLSC;
    lsc.isClass = _isClass;
    lsc.getTag = _getTag;
}

static void initStruct()
{
    if(arc4random() % 2 + 1 > 0) {
        initStruct1();
    } else {
        initStuct2();
        lsc.isClass(nil);
    }
}

short initLuaCore(void) {
    initStruct();
    return lsc.initLSC();
}

short getSystemTag(void)
{
    return lsc.getTag();
}
