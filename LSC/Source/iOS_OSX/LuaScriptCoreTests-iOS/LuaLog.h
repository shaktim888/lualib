//
//  LuaLog.h
//  LuaScriptCore
//
//  Created by admin on 2017/9/6.
//  Copyright © 2017年 hy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSCExportType.h"

@interface LuaLog : NSObject <LSCExportType>

+ (void)writeLog:(NSString *)msg;

@end
