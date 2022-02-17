//
//  LogModule.m
//  Sample
//
//  Created by admin on 16/9/22.
//  Copyright © 2016年 hy. All rights reserved.
//

#import "LogModule.h"

@implementation LogModule

+ (void)writeLog:(NSString *)message
{
    NSLog(@"** message = %@", message);
}

@end
