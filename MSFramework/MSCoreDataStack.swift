//
//  MSCoreDataStack.swift
//  MSFramework
//
//  Created by Michael Schloss on 8/25/15.
//  Copyright © 2015 Michael Schloss. All rights reserved.
//

import UIKit
import CoreData

//The CoreData extension that allows for CoreData use in MSFramework

extension MSDatabase
{
    ///The CoreData class for MSDatabase
    class MSCoreDataStack
    {
        fileprivate var loaded = false
        
        lazy var persistentContainer: NSPersistentContainer =
            {
            let container = NSPersistentContainer(name: coreDataModelName)
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as? NSError
                {
                    print("There's been an error loading the container! Error Details: \(error), \(error.userInfo)")
                }
                else
                {
                    self.loaded = true
                }
            })
            return container
        }()
        
        lazy var managedObjectContext : NSManagedObjectContext? =
            {
                return self.loaded ? self.persistentContainer.viewContext : nil
        }()
    }
}
