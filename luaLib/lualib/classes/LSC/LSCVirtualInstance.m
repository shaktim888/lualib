//
//  LSCObjectDescriptor.m
//  LuaScriptCore
//
//  Created by admin on 2017/12/27.
//  Copyright © 2017年 hy. All rights reserved.
//

#import "LSCVirtualInstance.h"

@implementation LSCVirtualInstance

- (instancetype)initWithTypeDescriptor:(LSCExportTypeDescriptor *)typeDescriptor
{
    if (self = [super init])
    {
        _typeDescriptor = typeDescriptor;
    }
    
    return self;
}

@end
