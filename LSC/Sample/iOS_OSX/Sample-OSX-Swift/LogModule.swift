//
//  LogModule.swift
//  Sample
//
//  Created by admin on 16/12/1.
//  Copyright © 2016年 hy. All rights reserved.
//

import LuaScriptCore_OSX_Swift

@objc(LogModule)
class LogModule: NSObject, LuaExportType
{
    @objc static func writeLog(message : String) -> Void
    {
        NSLog("** message = %@", message);
    }
}
