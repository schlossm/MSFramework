//
//  MSDataSizePrinter.swift
//  Purdue Cafes
//
//  Created by Michael Schloss on 4/17/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//
fileprivate enum Size : NSInteger
{
    case B, KB, MB, GB, TB, PB
}

class MSDataSizePrinter
{
    func printSize(_ dataSize: Int)
    {
        var startSize = 0
        
        var length = Double(dataSize)
        
        while length > 1024.0
        {
            startSize += 1
            length /= 1024.0
        }
        
        debugLog("Downloaded Data Size: \(String(format: "%.2f", length))\(Size(rawValue: startSize)!)")
    }
}
