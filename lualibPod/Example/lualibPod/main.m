//
//  main.m
//  lualibPod
//
//  Created by admin on 12/18/2019.
//  Copyright (c) 2019 admin. All rights reserved.
//

@import UIKit;
#import "LUAAppDelegate.h"

#import <lualib/luacore.h>
#import <WebKit/WKWebView.h>

int main(int argc, char * argv[])
{
    [WKWebView class];
    initLuaCore();
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([LUAAppDelegate class]));
    }
}
