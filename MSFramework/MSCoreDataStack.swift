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
    class MSCoreDataStack: NSObject
    {
        ///Application Documents Directory URL
        lazy private var applicationDocumentsDirectory: NSURL = {
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return urls[urls.count-1]
        }()
        
        ///Managed Object Model for your CoreData model
        lazy private var managedObjectModel: NSManagedObjectModel = {
            let modelURL = NSBundle.mainBundle().URLForResource(coreDataModelName, withExtension: "momd")!
            return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
        
        ///The Persistent Store Coordinator.  This pulls up the SQL Database for CoreData
        lazy private var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
            var failureReason = "There was an error creating or loading the application's saved data."
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            do {
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
            } catch {
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
                dict[NSLocalizedFailureReasonErrorKey] = failureReason
                
                dict[NSUnderlyingErrorKey] = error as NSError
                let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
                NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
                abort()
            }
            
            return coordinator
        }()
        
        ///The Managed Object Context.  This object contains the references to all the objects stored in CoreData
        lazy var managedObjectContext: NSManagedObjectContext = {
            let coordinator = self.persistentStoreCoordinator
            var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = coordinator
            return managedObjectContext
        }()
    }
}
