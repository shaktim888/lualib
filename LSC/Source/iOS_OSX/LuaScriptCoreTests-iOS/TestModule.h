//
//  TestModule.h
//  LuaScriptCore
//
//  Created by admin on 16/11/14.
//  Copyright © 2016年 hy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSCExportType.h"

@interface TestModule : NSObject <LSCExportType>

+ (NSString *)test;

+ (NSString *)testWithMsg:(NSString *)msg;

@end
