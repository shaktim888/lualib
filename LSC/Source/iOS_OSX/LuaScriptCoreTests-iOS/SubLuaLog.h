//
//  SubLuaLog.h
//  LuaScriptCore
//
//  Created by admin on 2017/9/7.
//  Copyright © 2017年 hy. All rights reserved.
//

#import "LuaLog.h"
#import "LSCExportTypeAnnotation.h"

@interface SubLuaLog : LuaLog <LSCExportTypeAnnotation>

@property (nonatomic, copy) NSString *name;

- (void)printName;

@end
