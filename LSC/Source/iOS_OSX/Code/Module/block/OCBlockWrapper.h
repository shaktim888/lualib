//
//  JPBlockWrapper.h
//  JSPatch
//
//  Created by bang on 1/19/17.
//  Copyright © 2017 bang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSCFunction.h"
#import "OCMethodSignature.h"

@interface OCBlockWrapper : NSObject
@property (nonatomic,strong) OCMethodSignature *signature;

- (void *)blockPtr;
- (id)initWithTypeString:(NSString *)typeString callbackFunction:(LSCFunction *) function isByInstance : (BOOL) isByInstance;
@end
