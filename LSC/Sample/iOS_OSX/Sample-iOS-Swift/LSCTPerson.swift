//
//  LSCTPerson.swift
//  Sample
//
//  Created by admin on 16/12/1.
//  Copyright © 2016年 hy. All rights reserved.
//

import LuaScriptCore_iOS_Swift

@objc
class LSCTPerson : NSObject, LuaExportType
{
    var name : String? = nil;
    
    @objc func speak() -> Void
    {
        NSLog("%@ speak", name ?? "noname");
    }
    
    @objc func walk() -> Void
    {
        NSLog("%@ walk", name ?? "noname");
    }
}
