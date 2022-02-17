//
//  main.m
//  luaLibDemo
//
//  Created by admin on 2019/12/18.
//  Copyright © 2019 admin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#include <lualib/luacore.h>

int main(int argc, char * argv[]) {
    int ret = initLuaCore();
    if(ret) {
        printf("isOpen");
    } else {
        printf("isClosed");
    }
    NSLog(@"-----------%@", NSDefaultRunLoopMode);
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
