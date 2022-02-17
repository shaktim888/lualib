//
//  LuaManagedValue.swift
//  LuaScriptCore
//
//  Created by admin on 2017/5/24.
//  Copyright © 2017年 hy. All rights reserved.
//

public class LuaManagedValue: NSObject
{
    var _source : LuaValue?;
    weak var _context : LuaContext?;
    
    public init(source : LuaValue, context : LuaContext)
    {
        _source = source;
        _context = context;
        
        _context?.retainValue(value:_source!);
    }
    
    deinit
    {
        _context?.releaseValue(value: _source!);
    }
    
    
    /// 获取源值对象
    public var source : LuaValue
    {
        get
        {
            return _source!;
        }
    }
}
