//
//  MSNetworkActivityIndicatorManager.swift
//  High School Sports
//
//  Created by Michael Schloss on 5/28/15.
//  Copyright (c) 2015 Michael Schloss. All rights reserved.
//

import UIKit

//The Network Activity Indicator extension for MSDatabase
//Shows the loading wheel in the status bar when MSFramework is using the internet.

//It is recommended your app uses this class to manage the Network Activity Indicator across the entire application as this class can prematurely dismiss the Network Activity Indicator

extension MSDatabase
{
    ///Displays the Network Activity Indicator when `show()` is called, and hides when `hide()` is called.
    ///
    ///This class keeps track of the number of calls to prevent premature dismissing of the network indicator
    class MSNetworkActivityIndicatorManager: NSObject
    {
        private var numberOfActivityIndicatorRequests = 0
            {
            didSet
            {
                if numberOfActivityIndicatorRequests == 0
                {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                else
                {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
            }
        }
        
        ///Shows the Network Activity Indicator
        ///- SeeAlso: `hide()`
        func show()
        {
            numberOfActivityIndicatorRequests += 1
        }
        
        ///Hides the Network Activity Indicator
        ///- Note: If multiple calls to `show()` have been made, the same number of calls must be made to this method to fully dismiss the Network Activity Indicator
        ///- SeeAlso: `show()`
        func hide()
        {
            numberOfActivityIndicatorRequests = max(numberOfActivityIndicatorRequests - 1, 0)
        }
    }
}
