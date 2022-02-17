//
//  LogModule.h
//  Sample
//
//  Created by admin on 16/9/22.
//  Copyright © 2016年 hy. All rights reserved.
//

#import "LuaScriptCore.h"

/**
 *  日志模块
 */
@interface LogModule : NSObject <LSCExportType>

/**
 *  写入日志
 *
 *  @param message 日志信息
 */
+ (void)writeLog:(NSString *)message;

@end
