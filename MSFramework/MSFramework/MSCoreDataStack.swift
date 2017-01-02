//
//  MSCoreDataStack.swift
//  MSFramework
//
//  Created by Michael Schloss on 8/25/15.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

import CoreData

///The CoreData manager for MSFramework
class MSCoreDataStack
{
    private var persistentContainer     : NSPersistentContainer!
    var managedObjectContext            : NSManagedObjectContext?
    
    init() { }
    
    func load()
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
    
    private func coreDataObjectFrom(_ table: String) -> NSManagedObject?
    {
        //Make sure it's not empty
        guard table != "" else { return nil }
        
        let moc = MSFrameworkManager.default.managedObjectContext
        
        func objectFor(_ entityName: String) -> NSManagedObject?
        {
            if let entity = NSEntityDescription.entity(forEntityName: entityName, in: moc!)
            {
                return NSManagedObject(entity: entity, insertInto: moc)
            }
            else if let entity = NSEntityDescription.entity(forEntityName: entityName.capitalized, in: moc!)
            {
                return NSManagedObject(entity: entity, insertInto: moc)
            }
            else if let entity = NSEntityDescription.entity(forEntityName: entityName.uppercased(), in: moc!)
            {
                return NSManagedObject(entity: entity, insertInto: moc)
            }
            else if let entity = NSEntityDescription.entity(forEntityName: entityName.lowercased(), in: moc!)
            {
                return NSManagedObject(entity: entity, insertInto: moc)
            }
            
            return nil
        }
        
        //Try to do this automatically
        var trimmedString = table
        
        if let entity = objectFor(table)
        {
            return entity
        }
        
        if table.hasSuffix("es")
        {
            trimmedString = table.substring(to: table.index(table.endIndex, offsetBy: -2))
            let t = trimmedString + "e"
            if let entity = objectFor(t)
            {
                return entity
            }
        }
        else if table.hasSuffix("s")
        {
            trimmedString = table.substring(to: table.index(table.endIndex, offsetBy: -1))
        }
        
        if let entity = objectFor(trimmedString)
        {
            return entity
        }
        
        //Fallback onto application settings
        let coreDataInfo = MSFrameworkManager.default.dataSource.databaseToCoreDataInfo
        
        guard let cDTableName = coreDataInfo.first(where: { return $0.databaseTableName == table })?.coreDataTableName else { return nil }
        return NSManagedObject(entity: NSEntityDescription.entity(forEntityName: cDTableName, in: moc!)!, insertInto: moc)
    }
    
    private func coreDataAttributeFrom(_ attribute: String, `in` object: NSManagedObject) -> String?
    {
        guard attribute != "" else { return "" }
        //Try to do this automatically
        let properties = object.entity.properties
        
        func propertyFor(_ attributeName: String) -> String?
        {
            for property in properties
            {
                if attributeName == property.name || attributeName.lowercased() == property.name || attributeName.uppercased() == property.name || attributeName.capitalized == property.name
                {
                    return property.name
                }
            }
            
            return nil
        }
        
        if let attr = propertyFor(attribute)
        {
            return attr
        }
        
        var trimmedAtt = attribute
        
        if attribute.hasSuffix("ies")
        {
            trimmedAtt = attribute.substring(to: attribute.index(attribute.endIndex, offsetBy: -3))
            trimmedAtt += "y"
        }
        else if attribute.hasSuffix("es")
        {
            trimmedAtt = attribute.substring(to: attribute.index(attribute.endIndex, offsetBy: -2))
            let trimmedAttr = trimmedAtt + "e"
            if let attr = propertyFor(trimmedAttr)
            {
                return attr
            }
        }
        else if attribute.hasSuffix("s")
        {
            trimmedAtt = attribute.substring(to: attribute.index(attribute.endIndex, offsetBy: -1))
        }
        
        if let attr = propertyFor(trimmedAtt)
        {
            return attr
        }
        
        //Fallback onto application settings
        let entity = object.entity.name!
        
        let coreDataInfo = MSFrameworkManager.default.dataSource.databaseToCoreDataInfo
        
        for info in coreDataInfo
        {
            if info.coreDataTableName == entity
            {
                return info.attributesToCDAttributes[attribute]
            }
        }
        
        return nil
    }
    
    
    func storeDataInCoreData(_ returnData: [Any], sqlStatement: MSSQL)
    {
        for dataobject in returnData
        {
            guard let downloadedData = dataobject as? [String:Any] else { continue }
            
            let table = sqlStatement.fromTables.first!
            guard let cdObject = coreDataObjectFrom(table) else { fatalError("Could not convert '\(table)' into a Core Data object.  Please make sure you've added this table into the Data Source's databaseToCoreDataInfo property") }
            
            for (key, value) in downloadedData
            {
                guard let cdKey = coreDataAttributeFrom(key, in: cdObject) else { fatalError("Could not convert '\(key)' into a Core Data attribute for \(cdObject.entity.name!).  Please make sure you've added this attribute into the Data Source's databaseToCoreDataInfo property") }
                
                cdObject.setValue(value, forKey: cdKey)
            }
            try! saveCoreData()
        }
    }
}
