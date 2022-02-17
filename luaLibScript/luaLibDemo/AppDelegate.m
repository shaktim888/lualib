//
//  AppDelegate.m
//  luaLibDemo
//
//  Created by admin on 2019/12/18.
//  Copyright © 2019 admin. All rights reserved.
//

#import "AppDelegate.h"

#include <lualib/luacore.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskAll; // 这是自动旋转的参数，自己修改成对应的
}

@end
