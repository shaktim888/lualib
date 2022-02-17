//
//  EncodingModuleViewController.swift
//  Sample-iOS-Swift
//
//  Created by admin on 2018/8/21.
//  Copyright © 2018年 hy. All rights reserved.
//

import UIKit
import LuaScriptCore_iOS_Swift

class EncodingModuleViewController: UITableViewController {

    let context : LuaContext = LuaContext();
    
    override func viewDidLoad() {
        
        context.onException { (msg) in
            print("lua exception = \(msg!)");
        }
        
        _ = context.evalScript(filePath: "Encoding-Sample.lua");
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row
        {
        case 0:
           _ = context.evalScript(script: "Encoding_Sample_urlEncode()");
        case 1:
           _ = context.evalScript(script: "Encoding_Sample_urlDecode()");
        case 2:
            _ = context.evalScript(script: "Encoding_Sample_base64Encode()");
        case 3:
            _ = context.evalScript(script: "Encoding_Sample_base64Decode()");
        case 4:
            _ = context.evalScript(script: "Encoding_Sample_jsonEndode()");
        case 5:
            _ = context.evalScript(script: "Encoding_Sample_jsonDecode()");
        case 6:
            _ = context.evalScript(script: "Encoding_Sample_hexEncode()");
        case 7:
            _ = context.evalScript(script: "Encoding_Sample_hexDecode()");
        default:
            break;
        }
    }
    
}
