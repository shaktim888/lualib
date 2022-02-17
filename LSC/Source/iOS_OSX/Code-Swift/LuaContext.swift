//
//  LuaContext.swift
//  LuaScriptCore
//
//  Created by admin on 16/11/30.
//  Copyright © 2016年 hy. All rights reserved.
//

/// Lua上下文对象
public class LuaContext: NSObject
{
    /// 原始的上下文对象
    var rawContext : LSCContext;
    
    /// 初始化LuaContext
    public override init ()
    {
        self.rawContext = LSCContext();
    }
    
    public init (config : LuaConfig)
    {
        self.rawContext = LSCContext(config: config);
    }
    
    /// 添加搜索路径，对于不在应用主Bundle根目录的lua脚本如果需要require时，则需要指定其搜索路径。
    ///
    /// - Parameter path: 路径字符串
    public func addSearchPath(path : String) -> Void
    {
        self.rawContext.addSearchPath(path);
    }
    
    
    /// 运行异常时触发
    ///
    /// - Parameter handler: 事件处理器
    public func onException (handler : @escaping (String?) -> Void) -> Void
    {
        self.rawContext.onException { (message : String?) in
            
            handler (message);
            
        }
    }
    
    
    /// 抛出异常
    ///
    /// - Parameter message: 异常消息
    public func raiseException(message : String) throws -> Void
    {
        self.rawContext.raiseException(withMessage: message);
    }
    
    /// 设置全局变量
    ///
    /// - Parameters:
    ///   - name: 变量名称
    ///   - value: 变量值
    public func setGlobal (name : String, value : LuaValue) -> Void
    {
        self.rawContext.setGlobalWith(value.rawValue, forName: name);
    }
    
    /// 获取全局变量
    ///
    /// - Parameter name: 变量名称
    /// - Returns: 变量值
    public func getGlobal (name : String) -> LuaValue
    {
        let value : LSCValue =  self.rawContext.getGlobalForName(name);
        return LuaValue(rawValue: value);
    }
    
    
    /// 保留Lua层的变量引用，使其不被GC所回收。
    /// 注：判断value能否被保留取决于value所保存的真实对象，所以只要保证保存对象一致，即使value为不同对象并不影响实际效果。
    /// 即：LuaValue *val1 = LuaValue(objectValue:obj1);与LuaValue *val2 = LuaValue(objectValue:obj1);传入方法中效果相同。
    ///
    /// - Parameter value: 对应Lua层变量的原生对象Value，如果value为非Lua回传对象则调用此方法无任何效果。
    public func retainValue (value : LuaValue) -> Void
    {
        self.rawContext.retain(value.rawValue);
    }
    
    
    /// 释放Lua层的变量引用，使其内存管理权交回Lua。
    /// 注：判断value能否被释放取决于value所保存的真实对象，所以只要保证保存对象一致，即使value为不同对象并不影响实际效果。
    /// 即：LSCValue *val1 = [LSCValue objectValue:obj1]与LSCValue *val2 = [LSCValue objectValue:obj1]传入方法中效果相同。
    ///
    /// - Parameter value: 对应Lua层变量的原生对象Value，如果value为非Lua回传对象则调用此方法无任何效果。
    public func releaseValue (value : LuaValue) -> Void
    {
        self.rawContext.release(value.rawValue);
    }
    
    /// 解析脚本
    ///
    /// - Parameter script: 脚本字符串
    /// - Returns: 返回值对象
    public func evalScript (script : String) -> LuaValue
    {
        return evalScript(script: script, scriptController: nil);
    }
    
    /// 解析脚本
    ///
    /// - Parameters:
    ///   - script: 脚本字符串
    ///   - config: 执行脚本配置
    /// - Returns: 返回值对象
    public func evalScript (script : String, scriptController : LuaScriptController?) -> LuaValue
    {
        let retValue : LSCValue = self.rawContext.evalScript(from: script, scriptController: scriptController);
        return LuaValue(rawValue: retValue as LSCValue);
    }
    
    /// 解析脚本
    ///
    /// - Parameter filePath: 文件路径
    /// - Returns: 返回值对象
    public func evalScript (filePath : String) -> LuaValue
    {
        return evalScript(filePath: filePath, scriptController: nil);
    }
    
    /// 解析脚本
    ///
    /// - Parameters:
    ///   - filePath: 文件路径
    ///   - config: 执行脚本配置
    /// - Returns: 返回值对象
    public func evalScript (filePath : String, scriptController : LuaScriptController?) -> LuaValue
    {
        let retValue : LSCValue = self.rawContext.evalScript(fromFile: filePath, scriptController: scriptController);
        return LuaValue(rawValue: retValue as LSCValue);
    }
    
    /// 调用方法
    ///
    /// - Parameters:
    ///   - methodName: 方法名称
    ///   - arguments: 参数列表
    /// - Returns: 返回值对象
    public func callMethod (methodName : String, arguments : Array<LuaValue>) -> LuaValue
    {
        return callMethod(methodName: methodName, arguments: arguments, scriptController: nil);
    }
    
    /// 调用方法
    ///
    /// - Parameters:
    ///   - methodName: 方法名称
    ///   - arguments: 参数列表
    ///   - config: 执行脚本配置
    /// - Returns: 返回值对象
    public func callMethod (methodName : String,
                            arguments : Array<LuaValue>,
                            scriptController : LuaScriptController?) -> LuaValue
    {
        self.registerMethod(methodName: "testMethod") { (arguments) -> LuaValue in
            return LuaValue(stringValue: "Hello World");
        }
        
        var args : Array<LSCValue> = Array<LSCValue>();
        for item in arguments {
            args.append(item.rawValue);
        }
        
        let retValue : LSCValue = self.rawContext.callMethod(withName: methodName, arguments: args, scriptController: scriptController);
        return LuaValue(rawValue: retValue as LSCValue);
    }
    
    /// 注册方法
    ///
    /// - Parameters:
    ///   - methodName: 方法名称
    ///   - block: 方法处理
    public func registerMethod (methodName : String, block: @escaping (Array<LuaValue>) -> LuaValue) -> Void
    {
        self.rawContext.registerMethod(withName: methodName, block: {(arguments : Array<LSCValue>?) in
            
            var args : Array<LuaValue> = Array<LuaValue> ();
            if ((arguments) != nil)
            {
                for item in arguments! {
                    args.append(LuaValue(rawValue: item));
                }
            }
            
            let retValue : LuaValue? = block (args);
            if ((retValue) != nil)
            {
                return retValue?.rawValue;
            }
            
            return nil;
            
        });
    }
    
    
    /// 执行线程
    ///
    /// - Parameters:
    ///   - function: 线程处理器
    ///   - arguments: 参数列表
    public func runThread(function : LuaFunction, arguments: Array<LuaValue>) -> Void
    {
        runThread(function: function, arguments: arguments, scriptController: nil);
    }
    
    
    /// 执行线程
    ///
    /// - Parameters:
    ///   - function: 线程处理器
    ///   - arguments: 参数列表
    ///   - config: 执行脚本配置
    public func runThread(function : LuaFunction,
                          arguments: Array<LuaValue>,
                          scriptController: LuaScriptController?) -> Void
    {
        var args : Array<LSCValue> = Array<LSCValue>();
        for item in arguments {
            args.append(item.rawValue);
        }
        
        rawContext.runThread(with: function, arguments: args, scriptController: scriptController);
    }
}
