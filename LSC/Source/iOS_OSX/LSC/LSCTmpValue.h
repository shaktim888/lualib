//
//  LSCTmpValue.h
//  LuaScriptCore
//
//  Created by admin on 2017/12/13.
//  Copyright © 2017年 hy. All rights reserved.
//

#import "LSCValue.h"

@class LSCContext;

/**
 临时值
 */
@interface LSCTmpValue : LSCValue

/**
 初始化

 @param context 上下文对象
 @param index 索引
 @return 临时值对象
 */
- (instancetype)initWithContext:(LSCContext *)context
                          index:(NSInteger)index;

@end
