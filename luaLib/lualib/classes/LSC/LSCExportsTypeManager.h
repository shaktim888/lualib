//
//  LSCModuleExporter.h
//  LuaScriptCore
//
//  Created by admin on 2017/9/5.
//  Copyright © 2017年 hy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSCExportType.h"
#import "LSCEngineAdapter.h"
#import "LSCExportTypeDescriptor.h"

@class LSCContext;
@class LSCOperationQueue;

/**
 类型导出器
 */
@interface LSCExportsTypeManager : NSObject

/**
 初始化
 
 @param context 上下文对象
 @return 导出器对象
 */
- (instancetype)initWithContext:(LSCContext *)context;

/**
 检测对象实例是否为一个导出类型

 @param object 对象实例
 @return YES 是导出类型，否则不是.
 */
- (BOOL)checkExportsTypeWithObject:(id)object;

/**
 根据一个原生对象创建一个Lua对象

 @param object 对象实例
 */
- (void)createLuaObjectByObject:(id)object;

/**
 根据一个原生对象创建一个Lua对象

 @param object 对象实例
 @param state 状态
 @param queue 队列
 */
- (void)createLuaObjectByObject:(id)object
                          state:(lua_State *)state
                          queue:(LSCOperationQueue *)queue;


+ (LSCExportTypeDescriptor *) createTypeDescriptorWithClass:(NSString*) name typeName: (NSString *) typeName cls: (Class) cls;
@end
