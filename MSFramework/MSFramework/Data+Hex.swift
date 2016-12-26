//
//  Data+Hex.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/25/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

extension Data
{
    var hexEncoded : String
    {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

extension String
{
    var hexadecimal : Data?
    {
        var data = Data(capacity: characters.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else {
            return nil
        }
        
        return data
    }
}
