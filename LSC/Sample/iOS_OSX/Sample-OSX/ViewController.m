//
//  ViewController.m
//  Sample-OSX
//
//  Created by hy on 16/8/22.
//  Copyright © 2016年 hy. All rights reserved.
//

#import "LuaScriptCore.h"
#import "ViewController.h"
#import "LogModule.h"
#import "LSCTPerson.h"
#import "LSCTNativeData.h"

@interface ViewController ()

/**
 lua上下文
 */
@property(nonatomic, strong) LSCContext *context;

/**
 是否注册方法
 */
@property(nonatomic) BOOL hasRegMethod;

@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Do any additional setup after loading the view.

  self.context = [[LSCContext alloc] init];

  //捕获异常
  [self.context onException:^(NSString *message) {

    NSLog(@"error = %@", message);

  }];
}

/**
 解析脚本按钮点击事件
 
 @param sender 事件对象
 */
- (IBAction)evalScriptButtonClickedHandler:(id)sender {

  //解析并执行Lua脚本
  LSCValue *retValue =
      [self.context evalScriptFromString:@"print(10);return 'Hello World';"];
  NSLog(@"%@", [retValue toString]);
}

/**
 注册方法按钮点击事件
 
 @param sender 事件对象
 */
- (IBAction)regMethodClcikedHandler:(id)sender {

  if (!self.hasRegMethod) {
    self.hasRegMethod = YES;

    //注册方法
    [self.context registerMethodWithName:@"getDeviceInfo"
                                   block:^LSCValue *(NSArray *arguments) {

                                     NSMutableDictionary *info =
                                         [NSMutableDictionary dictionary];
                                     [info setObject:@"value1" forKey:@"key1"];
                                     [info setObject:@"value2" forKey:@"key2"];
                                     [info setObject:@"value3" forKey:@"key3"];
                                     [info setObject:@"value4" forKey:@"key4"];

                                     return [LSCValue dictionaryValue:info];

                                   }];
  }

  //调用脚本
  [self.context
      evalScriptFromFile:[[NSBundle mainBundle] pathForResource:@"main"
                                                         ofType:@"lua"]];
}

/**
 调用lua方法点击事件
 
 @param sender 事件对象
 */
- (IBAction)callLuaMethodClickedHandler:(id)sender {

  //加载Lua脚本
  [self.context
      evalScriptFromFile:[[NSBundle mainBundle] pathForResource:@"todo"
                                                         ofType:@"lua"]];

  //调用Lua方法
  LSCValue *value = [self.context callMethodWithName:@"add"
                                           arguments:@[
                                             [LSCValue integerValue:1000],
                                             [LSCValue integerValue:24]
                                           ]];
  NSLog(@"result = %@", [value toNumber]);
}


/**
 注册模块点击事件

 @param sender 事件对象
 */
- (IBAction)registerModuleClickedHandler:(id)sender
{
    [self.context evalScriptFromString:@"LogModule.writeLog('Hello Lua Module!');"];
}


/**
 注册类点击时间

 @param sender 事件对象
 */
- (IBAction)registerClassClickedHandler:(id)sender
{
    [self.context evalScriptFromFile:[[NSBundle mainBundle] pathForResource:@"test"
                                                                     ofType:@"lua"]];
}

/**
 导入原生类型按钮点击事件
 
 @param sender 事件对象
 */
- (IBAction)importNativeClassClickedHandler:(id)sender
{
    [self.context evalScriptFromString:@"local Data = LSCTNativeData; print(Data); local d = Data.create(); print(d); d.dataId = 'xxxx'; print(d.dataId); d:setData('xxx','testKey'); print(d:getData('testKey'));"];
}

@end
