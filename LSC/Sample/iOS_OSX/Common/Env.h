//
//  Env.h
//  Sample
//
//  Created by admin on 2019/3/11.
//  Copyright © 2019年 hy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LuaScriptCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface Env : NSObject

+ (LSCContext *)defaultContext;

+ (LSCScriptController *)runScriptConfig;

@end

NS_ASSUME_NONNULL_END
