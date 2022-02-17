////
//  ViewController.m
//  Sample
//
//  Created by hy on 16/7/15.
//  Copyright © 2016年 hy. All rights reserved.
//

#import "LuaScriptCore.h"
#import "ViewController.h"
#import "LogModule.h"
#import "LSCTPerson.h"
#import "LSCTNativeData.h"
#import "Env.h"
#import <objc/runtime.h>
#import "LuaCore.h"

@interface ViewController ()

/**
 lua上下文
 */
@property(nonatomic, strong) LSCContext *context;

/**
 是否注册方法
 */
@property(nonatomic) BOOL hasRegMethod;

/**
 *  是否注册模块
 */
@property (nonatomic) BOOL hasRegModule;

/**
 *  是否注册类
 */
@property (nonatomic) BOOL hasRegClass;


/**
 是否导入类
 */
@property (nonatomic) BOOL hasImportClass;

@end

@implementation ViewController

- (void) pinttt
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    initLuaCore();
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
