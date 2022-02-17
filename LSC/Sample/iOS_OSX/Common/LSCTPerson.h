//
//  LSCTPerson.h
//  Sample
//
//  Created by admin on 16/9/22.
//  Copyright © 2016年 hy. All rights reserved.
//

#import "LuaScriptCore.h"

@interface LSCTPerson : NSObject <LSCExportType>

@property (nonatomic, copy) NSString *name;

- (void)speak;

- (void)walk;

@end
