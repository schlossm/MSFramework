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
    ///Displays the Network Activity Indicator when `showIndicator()` is called, and hides when `hideIndicator()` is called.<br><br>This class keeps track of the number of calls to prevent premature dismissing of the network indicator
    class MSNetworkActivityIndicatorManager: NSObject
    {
        private var numberOfActivityIndicatorRequests = 0
            {
            didSet
            {
                if numberOfActivityIndicatorRequests == 0
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                else
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                }
            }
        }
        
        ///Shows the Network Activity Indicator
        ///- SeeAlso: `hideIndicator()`
        func showIndicator()
        {
            numberOfActivityIndicatorRequests++
        }
        
        ///Hides the Network Activity Indicator
        ///- Note: If multiple calls to `showIndicator()` have been made, the same number of calls must be made to this method to fully dismiss the Network Activity Indicator
        ///- SeeAlso: `showIndicator()`
        func hideIndicator()
        {
            numberOfActivityIndicatorRequests = max(numberOfActivityIndicatorRequests - 1, 0)
        }
    }
}
