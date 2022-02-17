//
//  JPBlock.m
//  JSPatch
//
//  Created by bang on 1/19/17.
//  Copyright © 2017 bang. All rights reserved.
//

#import "OCBlock.h"
#import "OCBlockWrapper.h"
#import <objc/runtime.h>

@implementation OCBlock
//+ (void)main:(JSContext *)context
//{
//    context[@"__genBlock"] = ^id(NSString *typeString, JSValue *cb) {
//        OCBlockWrapper *blockWrapper = [[OCBlockWrapper alloc] initWithTypeString:typeString callbackFunction:cb];
//        return blockWrapper;
//    };
//}

+ (id)blockWithBlockObj:(OCBlockWrapper *)blockObj
{
    return [blockObj blockPtr];
}
@end
