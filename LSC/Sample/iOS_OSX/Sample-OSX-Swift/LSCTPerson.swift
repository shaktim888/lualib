//
//  LSCTPerson.swift
//  Sample
//
//  Created by admin on 16/12/1.
//  Copyright © 2016年 hy. All rights reserved.
//

import LuaScriptCore_OSX_Swift

@objc(LSCTPerson)
class LSCTPerson: NSObject, LuaExportType
{
    @objc var name : String? = nil;
    
    @objc func speak() -> Void
    {
        NSLog("%@ speak", name ?? "noname");
    }
    
    @objc func walk() -> Void
    {
        NSLog("%@ walk", name ?? "noname");
    }
    
}
