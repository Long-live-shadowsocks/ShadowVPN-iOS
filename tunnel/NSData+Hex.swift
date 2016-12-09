//
//  NSData+Hex.swift
//  ShadowVPN
//
//  Created by clowwindy on 8/9/15.
//  Copyright © 2015 clowwindy. All rights reserved.
//

import Foundation

extension Data {
    public static func fromHexString (_ string: String) -> Data {
        let data = NSMutableData()
        var temp = ""
        
        for char in string.characters {
            temp += String(char)
            if temp.lengthOfBytes(using: String.Encoding.utf8) == 2 {
                let scanner = Scanner(string: temp)
                var value: CUnsignedInt = 0
                scanner.scanHexInt32(&value)
                data.append(&value, length: 1)
                temp = ""
            }
            
        }
        
        return data as Data
    }
}
