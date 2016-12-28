//
//  MSCoreDataStack.swift
//  MSFramework
//
//  Created by Michael Schloss on 8/25/15.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

import CoreData

///The CoreData manager for MSFramework
internal class MSCoreDataStack
{
    var persistentContainer     : NSPersistentContainer
    var managedObjectContext    : NSManagedObjectContext?
    
    init()
    {
        persistentContainer = NSPersistentContainer(name: MSFrameworkManager.default.dataSource.coreDataModelName)
        persistentContainer.loadPersistentStores(completionHandler: { [unowned self] (storeDescription, error) in
            if let error = error as? NSError
            {
                print("There's been an error loading the container! Error Details: \(error), \(error.userInfo)")
            }
            else
            {
                self.managedObjectContext = self.persistentContainer.viewContext
            }
        })
    }
}
