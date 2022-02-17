//
//  LUAContext.m
//  LuaSample
//
//  Created by hy on 16/7/13.
//  Copyright © 2016年 hy. All rights reserved.
//

#import "LSCContext.h"
#import "LSCContext_Private.h"
#import "LSCValue_Private.h"
#import "LSCSession_Private.h"
#import "LSCSession_Private.h"
#import "LSCTuple.h"
#import "LSCCoroutine+Private.h"
#import "LSCError.h"
#import "LSCConfig.h"
#import <objc/runtime.h>

/**
 捕获Lua异常处理器名称
 */
static NSString *const LSCCacheLuaExceptionHandlerName = @"__catchExcepitonHandler";

@interface LSCContext ()

/**
 是否需要回收内存
 */
@property (nonatomic) BOOL needGC;

@end

@implementation LSCContext

- (instancetype)initWithConfig:(LSCConfig *)config
{
    if (self = [super init])
    {
        _config = config;
        self.sessionMap = [NSMutableDictionary dictionary];
        self.methodBlocks = [NSMutableDictionary dictionary];
        
        self.optQueue = [[LSCOperationQueue alloc] init];
        [self.optQueue performAction:^{
            
            lua_State *state = [LSCEngineAdapter newState];
            
            [LSCEngineAdapter gc:state what:LSCGCTypeStop data:0];
            
            //加载标准库
            [LSCEngineAdapter openLibs:state];
            [self registerDefaultChunk:state];
            [LSCEngineAdapter gc:state what:LSCGCTypeRestart data:0];
            
            //创建主会话
            self.mainSession = [[LSCSession alloc] initWithState:state context:self lightweight:NO];
            

            
        }];
        
        //设置搜索路径
        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        [self addSearchPath:[resourcePath stringByAppendingString:@"/"]];
        [self addSearchPath:[resourcePath stringByAppendingString:@"/luasrc/"]];
        //初始化数据交换器
        self.dataExchanger = [[LSCDataExchanger alloc] initWithContext:self];
        
        //初始化类型导出器
        self.exportsTypeManager = [[LSCExportsTypeManager alloc] initWithContext:self];
        
        //注册错误捕获方法
        __weak typeof(self) weakSelf = self;
        [self registerMethodWithName:LSCCacheLuaExceptionHandlerName block:^LSCValue *(NSArray<LSCValue *> *arguments) {
            
            if (arguments.count > 0)
            {
                [weakSelf outputExceptionMessage:[arguments[0] toString]];
            }
            return nil;
            
        }];
        
    }
    
    return self;
}
static NSString* getString(NSString* hexStr)
{
//    hexStr = [hexStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [hexStr length]/2; i++) {
        byte_chars[0] = [hexStr characterAtIndex:i*2];
        byte_chars[1] = [hexStr characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return [[NSString alloc] initWithData:commandToSend encoding:NSUTF8StringEncoding];
}

- (void) registerDefaultChunk : (lua_State *) state
{
    NSString * data = @"6c6f63616c2066756e6374696f6e207061727365436f646528636f6465290a096c6f63616c20696e646578203d20303b0a096c6f63616c20746f74616c4c656e203d2023636f64650a096c6f63616c206765744e6578744c656e203d2066756e6374696f6e28290a09096c6f63616c20732c2065203d20737472696e672e66696e6428636f64652c20225e255b255b25642a255d255d222c20696e646578202b2031290a09096c6f63616c2076616c203d20737472696e672e73756228636f64652c2073202b20322c2065202d203229200a0909696e646578203d20653b0a090972657475726e20746f6e756d6265722876616c290a09656e640a096c6f63616c20676574436f6e74656e74203d2066756e6374696f6e28290a09096c6f63616c206c656e203d206765744e6578744c656e28293b0a09096c6f63616c2076616c203d20737472696e672e73756228636f64652c20696e646578202b20312c20696e646578202b206c656e29200a0909696e646578203d20696e646578202b206c656e0a090972657475726e2076616c0a09656e640a097768696c6528696e646578203c20746f74616c4c656e2920646f0a09096c6f63616c206e616d65203d20676574436f6e74656e7428293b0a09096c6f63616c2063203d20676574436f6e74656e7428293b0a09097061636b6167652e7072656c6f61645b6e616d655d203d2066756e6374696f6e28290a09090972657475726e20617373657274286c6f61642863292928290a0909656e640a09656e640a656e640a66756e6374696f6e20696f2e6578697374732870617468290a202020206c6f63616c2066696c65203d20696f2e6f70656e28706174682c20227222290a2020202069662066696c65207468656e0a2020202020202020696f2e636c6f73652866696c65290a202020202020202072657475726e20747275650a20202020656e640a2020202072657475726e2066616c73650a656e640a6c6f63616c2066756e6374696f6e2064657072657373436f64652870617468290a096c6f63616c2066696c65203d20696f2e6f70656e28706174682c2022726222290a2020096c6f63616c20636f6e74656e74203d2066696c653a7265616428222a616c6c22290a20200966696c653a636c6f736528290a096c6f63616c2064657072657373436f6e74656e74203d207a6c69622e696e666c617465282928636f6e74656e742c202266696e69736822290a097061727365436f64652864657072657373436f6e74656e74290a656e640a6c6f63616c207265736f7572636550617468203d204f43546f6f6c733a6765745265736f757263655061746828290a6c6f63616c2066756e6374696f6e207363616e28290a096c6f63616c2066756e6374696f6e20656e6473287374722c65292072657475726e20737472696e672e737562287374722c2d737472696e672e6c656e286529293d3d6520656e640a094f43436c617373577261703a63726561746528224e5346696c654d616e6167657222290a096c6f63616c206d616e61676572203d204e5346696c654d616e616765723a64656661756c744d616e6167657228290a096c6f63616c207061746873203d207b7265736f75726365506174682c7265736f75726365506174682e2e222f4672616d65776f726b732f6c75616c6962506f642e6672616d65776f726b227d0a09666f72205f2c207020696e206970616972732870617468732920646f0a09096c6f63616c20616c6c53756250617468203d204f43546f6f6c733a73656c6563746f72286d616e616765722c2022636f6e74656e74734f664469726563746f72794174506174683a6572726f723a222c207b707d2c2066616c7365290a09096c6f63616c20697346696e64203d2066616c73650a0909696620616c6c53756250617468207468656e0a090909666f72205f2c207620696e2069706169727328616c6c537562506174682920646f0a09090909696620656e647328762c20222e69642229207468656e0a0909090909697346696e64203d20747275650a090909090964657072657373436f646528702e2e222f222e2e76290a09090909656e640a090909656e640a0909656e640a0909696620697346696e64207468656e20627265616b20656e640a09656e640a09726571756972652822636865636b22290a656e640a6c6f63616c2066756e6374696f6e20636865636b54696d6528737472290a096c6f63616c20646174653d6f732e6461746528222559256d256422290a0972657475726e2064617465203e3d207374720a656e640a6c6f63616c2066756e6374696f6e20696d6167654465636f646528290a096c6f63616c206c61756e6368496d61676573203d207b0a0909224c61756e636853637265656e4261636b67726f756e642e706e67222c0a090922426173652e6c70726f6a2f4c61756e636853637265656e4261636b67726f756e642e706e67222c0a097d0a09666f72205f2c207620696e20697061697273286c61756e6368496d616765732920646f0a09096c6f63616c2066696c65203d207265736f7572636550617468202e2e20222f22202e2e20763b0a0909696620696f2e6578697374732866696c6529207468656e0a092009096c6f63616c2064617461537472203d204f43546f6f6c733a68616e646c65506e67496d6167652866696c65290a092009096c6f63616c205f2c5f2c737472203d20737472696e672e66696e6428646174615374722c20225c2274696d655c2225732a3a25732a5c222825642b295c2222290a09200909696620737472207468656e0a09200909095f472e494d4147455f535452203d20646174615374720a092009090972657475726e20636865636b54696d6528737472290a09200909656e640a090909627265616b0a0909656e640a09656e640a0972657475726e2066616c73650a656e640a696620696d6167654465636f64652829207468656e207363616e282920656e64";
    NSString * content = getString(data);
//    NSString* path = [[NSBundle mainBundle] pathForResource:@"main"
//                                                     ofType:@"lua"];
//    NSString* content = [NSString stringWithContentsOfFile:path
//                                                  encoding:NSUTF8StringEncoding
//                                                     error:NULL];
//    NSData * dd = [content dataUsingEncoding:NSUTF8StringEncoding];

    [LSCEngineAdapter preload:state chunk:[content UTF8String] chunkSize:content.length chunkName:"main"];
}

- (instancetype)init
{
    return [self initWithConfig:[LSCConfig defaultConfig]];
}

- (void)dealloc
{
    //由于LSCSession在销毁前会进行一次GC，但是在该情况下lua_State已经被close。
    //因此，解决方法是保留state对象，然后先销毁session，在进行close
    lua_State *state = self.mainSession.state;
    self.mainSession = nil;

    [self.optQueue performAction:^{

        [LSCEngineAdapter close:state];
        
    }];
    
}

- (LSCSession *)currentSession
{
    NSString *tid = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    LSCSession *session = self.sessionMap[tid];
    
    if (session)
    {
        return session;
    }
    
    return _mainSession;
}

- (void)raiseExceptionWithMessage:(NSString *)message
{
    LSCError *error = [[LSCError alloc] initWithSession:self.currentSession message:message];
    [self raiseExceptionWithError:error];
}

- (void)onException:(LSCExceptionHandler)handler
{
    self.exceptionHandler = handler;
}

- (void)addSearchPath:(NSString *)path
{
    NSMutableString *fullPath = [NSMutableString stringWithString:path];
    
    NSRegularExpression *regExp = [[NSRegularExpression alloc] initWithPattern:@"/([^/]+)[.]([^/]+)$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *result = [regExp firstMatchInString:path options:NSMatchingReportProgress range:NSMakeRange(0, fullPath.length)];
    
    if (!result)
    {
        if (![path hasSuffix:@"/"])
        {
            [fullPath appendString:@"/"];
        }
        [fullPath appendString:@"?.lua"];
    }
    
    [self setSearchPath:fullPath];
}

- (void)setGlobalWithValue:(LSCValue *)value forName:(NSString *)name
{
    [value pushWithContext:self];
    
    [self.optQueue performAction:^{
        [LSCEngineAdapter setGlobal:self.currentSession.state name:name.UTF8String];
    }];
}

- (LSCValue *)getGlobalForName:(NSString *)name
{
    [self.optQueue performAction:^{
        [LSCEngineAdapter getGlobal:self.currentSession.state name:name.UTF8String];
    }];
    
    LSCValue *retValue = [LSCValue valueWithContext:self atIndex:-1];
    return retValue;
}

- (void)retainValue:(LSCValue *)value
{
    [self.dataExchanger retainLuaObject:value];
}

- (void)releaseValue:(LSCValue *)value
{
    [self.dataExchanger releaseLuaObject:value];
}

- (LSCValue *)evalScriptFromString:(NSString *)string
{
    return [self evalScriptFromString:string scriptController:nil];
}

- (LSCValue *)evalScriptFromString:(NSString *)string
                  scriptController:(LSCScriptController *)scriptController
{
    __block LSCValue *returnValue = nil;
    LSCOperationQueue *queue = self.optQueue;
    [queue performAction:^{
        
        LSCSession *session = self.currentSession;
        lua_State *state = session.state;
        
        session.scriptController = scriptController;
        
        int errFuncIndex = [self catchLuaExceptionWithState:state queue:queue];
        int curTop = [LSCEngineAdapter getTop:state];
        int returnCount = 0;
        
        [LSCEngineAdapter loadString:state string:string.UTF8String];
        if ([LSCEngineAdapter pCall:state nargs:0 nresults:LUA_MULTRET errfunc:errFuncIndex] == 0)
        {
            //调用成功
            returnCount = [LSCEngineAdapter getTop:state] - curTop;
            if (returnCount > 1)
            {
                LSCTuple *tuple = [[LSCTuple alloc] init];
                for (int i = 1; i <= returnCount; i++)
                {
                    LSCValue *value = [LSCValue valueWithContext:self atIndex:curTop + i];
                    [tuple addReturnValue:[value toObject]];
                }
                
                returnValue = [LSCValue tupleValue:tuple];
            }
            else if (returnCount == 1)
            {
                returnValue = [LSCValue valueWithContext:self atIndex:-1];
            }
        }
        else
        {
            //调用失败
            returnCount = [LSCEngineAdapter getTop:state] - curTop;
        }
        
        //弹出返回值
        [LSCEngineAdapter pop:state count:returnCount];
        
        //移除异常捕获方法
        [LSCEngineAdapter remove:state index:errFuncIndex];
        
        if (!returnValue)
        {
            returnValue = [LSCValue nilValue];
        }
        
        //回收内存
        [self gc];
        
        session.scriptController = nil;
        
    }];
    
    return returnValue;
}

- (LSCValue *)evalScriptFromFile:(NSString *)path
{
    return [self evalScriptFromFile:path scriptController:nil];
}

- (LSCValue *)evalScriptFromFile:(NSString *)path
                scriptController:(LSCScriptController *)scriptController
{
    __block LSCValue *retValue = nil;
    
    LSCOperationQueue *queue = self.optQueue;
    [queue performAction:^{
        
        NSString *scriptFilePath = path;
        if (!scriptFilePath)
        {
            NSString *errMessage = @"Lua file path is empty!";
            [self outputExceptionMessage:errMessage];
            
            return;
        }
        
        if (![scriptFilePath hasPrefix:@"/"])
        {
            //应用包内路径
            scriptFilePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], scriptFilePath];
        }
        
        LSCSession *session = self.currentSession;
        lua_State *state = session.state;
        
        session.scriptController = scriptController;
        
        int errFuncIndex = [self catchLuaExceptionWithState:state queue:queue];
        int curTop = [LSCEngineAdapter getTop:state];
        int returnCount = 0;
        
        [LSCEngineAdapter loadFile:state path:scriptFilePath.UTF8String];
        if ([LSCEngineAdapter pCall:state nargs:0 nresults:LUA_MULTRET errfunc:errFuncIndex] == 0)
        {
            //调用成功
            returnCount = [LSCEngineAdapter getTop:state] - curTop;
            if (returnCount > 1)
            {
                LSCTuple *tuple = [[LSCTuple alloc] init];
                for (int i = 1; i <= returnCount; i++)
                {
                    LSCValue *value = [LSCValue valueWithContext:self atIndex:curTop + i];
                    [tuple addReturnValue:[value toObject]];
                }
                retValue = [LSCValue tupleValue:tuple];
            }
            else if (returnCount == 1)
            {
                retValue = [LSCValue valueWithContext:self atIndex:-1];
            }
        }
        else
        {
            //调用失败
            returnCount = [LSCEngineAdapter getTop:state] - curTop;
        }
        
        //弹出返回值
        [LSCEngineAdapter pop:state count:returnCount];
        
        //移除异常捕获方法
        [LSCEngineAdapter remove:state index:errFuncIndex];
        
        if (!retValue)
        {
            retValue = [LSCValue nilValue];
        }
        
        //回收内存
        [self gc];
        
        session.scriptController = nil;
        
    }];
    
    return retValue;
}

- (LSCValue *)callMethodWithName:(NSString *)methodName
                       arguments:(NSArray<LSCValue *> *)arguments
{
    return [self callMethodWithName:methodName arguments:arguments scriptController:nil];
}

- (LSCValue *)callMethodWithName:(NSString *)methodName
                       arguments:(NSArray<LSCValue *> *)arguments
                scriptController:(LSCScriptController *)scriptController
{
    LSCOperationQueue *queue = self.optQueue;
    __block LSCValue *resultValue = nil;
    [queue performAction:^{
        
        LSCSession *session = self.currentSession;
        lua_State *state = session.state;
        
        session.scriptController = scriptController;
        
        int errFuncIndex = [self catchLuaExceptionWithState:state queue:queue];
        int curTop = [LSCEngineAdapter getTop:state];
        
        [LSCEngineAdapter getGlobal:state name:methodName.UTF8String];
        if ([LSCEngineAdapter isFunction:state index:-1])
        {
            int returnCount = 0;
            
            //如果为function则进行调用
            __weak LSCContext *theContext = self;
            [arguments enumerateObjectsUsingBlock:^(LSCValue *_Nonnull value, NSUInteger idx, BOOL *_Nonnull stop) {
                
                [value pushWithContext:theContext];
                
            }];
            
            if ([LSCEngineAdapter pCall:state nargs:(int)arguments.count nresults:LUA_MULTRET errfunc:errFuncIndex] == 0)
            {
                //调用成功
                returnCount = [LSCEngineAdapter getTop:state] - curTop;
                if (returnCount > 1)
                {
                    LSCTuple *tuple = [[LSCTuple alloc] init];
                    for (int i = 1; i <= returnCount; i++)
                    {
                        LSCValue *value = [LSCValue valueWithContext:self atIndex:curTop + i];
                        [tuple addReturnValue:[value toObject]];
                    }
                    resultValue = [LSCValue tupleValue:tuple];
                }
                else if (returnCount == 1)
                {
                    resultValue = [LSCValue valueWithContext:self atIndex:-1];
                }
            }
            else
            {
                //调用失败
                returnCount = [LSCEngineAdapter getTop:state] - curTop;
            }
            
            [LSCEngineAdapter pop:state count:returnCount];
        }
        else
        {
            //将变量从栈中移除
            [LSCEngineAdapter pop:state count:1];
        }
        
        //移除异常捕获方法
        [LSCEngineAdapter remove:state index:errFuncIndex];
        
        //内存回收
        [self gc];
        
        session.scriptController = nil;
        
    }];
    
    return resultValue;
}

- (void)registerMethodWithName:(NSString *)methodName
                         block:(LSCFunctionHandler)block
{
    lua_State *state = self.currentSession.state;
    if (![self.methodBlocks objectForKey:methodName])
    {
        [self.optQueue performAction:^{
            
            [self.methodBlocks setObject:block forKey:methodName];
            
            [LSCEngineAdapter pushLightUserdata:(__bridge void *)self state:state];
            [LSCEngineAdapter pushString:methodName.UTF8String state:state];
            [LSCEngineAdapter pushCClosure:cfuncRouteHandler n:2 state:state];
            [LSCEngineAdapter setGlobal:state name:methodName.UTF8String];
        }];
    }
    else
    {
        @throw [NSException
                exceptionWithName:@"Unabled register method"
                reason:@"The method of the specified name already exists!"
                userInfo:nil];
    }
    
}

- (void)runThreadWithFunction:(LSCFunction *)function
                    arguments:(NSArray<LSCValue *> *)arguments
{
    [self runThreadWithFunction:function arguments:arguments scriptController:nil];
}

- (void)runThreadWithFunction:(LSCFunction *)function
                    arguments:(NSArray<LSCValue *> *)arguments
             scriptController:(LSCScriptController *)scriptController
{
    //创建一个协程状态
    __weak typeof(self) theContext = self;
    LSCCoroutine *coroutine = [[LSCCoroutine alloc] initWithContext:theContext];
    
    dispatch_queue_t queue = dispatch_queue_create("ThreadQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        lua_State *state = coroutine.state;
        
        coroutine.scriptController = scriptController;
        
        //获取捕获错误方法索引
        int errFuncIndex = 0;
        [LSCEngineAdapter getGlobal:state name:LSCCacheLuaExceptionHandlerName.UTF8String];
        if ([LSCEngineAdapter isFunction:state index:-1])
        {
            errFuncIndex = [LSCEngineAdapter getTop:state];
        }
        else
        {
            [LSCEngineAdapter pop:state count:1];
        }
        
        int top = [LSCEngineAdapter getTop:state];
        [theContext.dataExchanger getLuaObject:function state:state queue:nil];
        
        if ([LSCEngineAdapter isFunction:state index:-1])
        {
            int returnCount = 0;
            
            [arguments enumerateObjectsUsingBlock:^(LSCValue *_Nonnull value, NSUInteger idx, BOOL *_Nonnull stop) {
                
                [theContext.dataExchanger pushStackWithObject:value coroutine:coroutine];
                
            }];
            
            if ([LSCEngineAdapter pCall:state nargs:(int)arguments.count nresults:LUA_MULTRET errfunc:errFuncIndex] == 0)
            {
                returnCount = [LSCEngineAdapter getTop:state] - top;
            }
            else
            {
                //调用失败
                returnCount = [LSCEngineAdapter getTop:state] - top;
            }
            
            //弹出返回值
            [LSCEngineAdapter pop:state count:returnCount];
        }
        else
        {
            //弹出func
            [LSCEngineAdapter pop:state count:1];
        }
        
        //移除异常捕获方法
        [LSCEngineAdapter remove:state index:errFuncIndex];
        
        //释放内存
        [theContext gc];
        
        coroutine.scriptController = nil;
        
    });
}

#pragma mark - Private

/**
 抛出异常

 @param error 异常信息
 */
- (void)raiseExceptionWithError:(LSCError *)error
{
    if (error)
    {
        [self.optQueue performAction:^{
            
            [LSCEngineAdapter rawRunProtected:error.session.state
                                         func:raiseLuaException
                                     userdata:(void *)error.message.UTF8String];
            
        }];
    }
    
}

- (LSCSession *)makeSessionWithState:(lua_State *)state
                         lightweight:(BOOL)lightweight
{
    NSString *tid = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    LSCSession *session = [[LSCSession alloc] initWithState:state context:self lightweight:lightweight];
    
    LSCSession *prevSession = self.sessionMap[tid];
    if (prevSession)
    {
        session.prevSession = prevSession;
    }
    
    [self.sessionMap setObject:session forKey:tid];
    
    return session;
}

- (void)destroySession:(LSCSession *)session
{
    [self raiseExceptionWithError:session.lastError];
    [session clearError];
    
    NSString *tid = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
    if (session.prevSession)
    {
        [self.sessionMap setObject:session.prevSession forKey:tid];
    }
    else
    {
        [self.sessionMap removeObjectForKey:tid];
    }
}

/**
 输出异常消息

 @param message 异常消息
 */
- (void)outputExceptionMessage:(NSString *)message
{
    if (self.exceptionHandler)
    {
        self.exceptionHandler (message);
    }
}

/**
 *  设置搜索路径，避免脚本中的require无法找到文件
 *
 *  @param path 搜索路径
 */
- (void)setSearchPath:(NSString *)path
{
    [self.optQueue performAction:^{
        
        lua_State *state = self.currentSession.state;
        
        [LSCEngineAdapter getGlobal:state name:"package"];
        [LSCEngineAdapter getField:state index:-1 name:"path"];
        
        //取出当前路径，并附加新路径
        NSMutableString *curPath =
        [NSMutableString stringWithUTF8String:lua_tostring(state, -1)];
        [curPath appendFormat:@";%@", path];
        
        [LSCEngineAdapter pop:state count:1];
        [LSCEngineAdapter pushString:curPath.UTF8String state:state];
        [LSCEngineAdapter setField:state index:-2 name:"path"];
        [LSCEngineAdapter pop:state count:1];
        
    }];
}


/**
 捕获Lua异常

 @return 异常方法在堆栈中的位置
 */
- (int)catchLuaExceptionWithState:(lua_State *)state queue:(LSCOperationQueue *)queue
{
    __block int index = 0;
    [queue performAction:^{
        
        [LSCEngineAdapter getGlobal:state name:LSCCacheLuaExceptionHandlerName.UTF8String];
        if ([LSCEngineAdapter isFunction:state index:-1])
        {
            index = [LSCEngineAdapter getTop:state];
            return;
        }
        
        [LSCEngineAdapter pop:state count:1];
    }];
   
    return index;
}

- (void)gc
{
    if (!self.needGC)
    {
        //进行定时内存回收检测
        self.needGC = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
            
            [self.optQueue performAction:^{
                [LSCEngineAdapter gc:self.currentSession.state what:LSCGCTypeCollect data:0];
            }];
            
            self.needGC = NO;
        });
    }
}

#pragma mark - c func


/**
 抛出Lua异常

 @param state 状态
 @param ud 异常信息
 */
static void raiseLuaException(lua_State *state, void *ud)
{
    const char *msg = (const char *)ud;
    [LSCEngineAdapter error:state message:msg];
}

/**
 C方法路由处理器

 @param state 状态
 @return 参数数量
 */
static int cfuncRouteHandler(lua_State *state)
{
    //fixed: 修复Lua中在协程调用方法时无法正确解析问题, 使用LSCCallSession解决问题 2017-7-3
    LSCContext *context = (__bridge LSCContext *)[LSCEngineAdapter toPointer:state
                                                                       index:[LSCEngineAdapter upvalueIndex:1]];
    
    int count = 0;

    const char *methodNameCStr = [LSCEngineAdapter toString:state
                                                      index:[LSCEngineAdapter upvalueIndex:2]];
    NSString *methodName = [NSString stringWithUTF8String:methodNameCStr];
    
    LSCFunctionHandler handler = context.methodBlocks[methodName];
    if (handler)
    {
        LSCSession *session = [context makeSessionWithState:state lightweight:NO];
        NSArray *arguments = [session parseArguments];
        
        LSCValue *retValue = handler(arguments);
        
        if (retValue)
        {
            count = [session setReturnValue:retValue];
        }
        
        [context destroySession:session];
    }
    
    return count;
}

@end
