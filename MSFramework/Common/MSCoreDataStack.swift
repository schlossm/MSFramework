//
//  MSCoreDataStack.swift
//  MSFramework
//
//  Created by Michael Schloss on 8/25/15.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

import CoreData

///The CoreData manager for MSFramework
final class MSCoreDataStack
{
    private var persistentContainer : NSPersistentContainer!
    var managedObjectContext : NSManagedObjectContext?
    
    init() { }
    
    func load()
    {
        guard let dataSource = MSFrameworkManager.default.dataSource else { return }
        persistentContainer = NSPersistentContainer(name: dataSource.coreDataModelName)
        persistentContainer.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error
            {
                print("There's been an error loading the container! Error Details: \(error)")
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
        guard table != "", let moc = managedObjectContext else { return nil }
        
        func objectFor(_ entityName: String) -> NSManagedObject?
        {
            if let entity = NSEntityDescription.entity(forEntityName: entityName, in: moc)
            {
                return NSManagedObject(entity: entity, insertInto: moc)
            }
            else if let entity = NSEntityDescription.entity(forEntityName: entityName.capitalized, in: moc)
            {
                return NSManagedObject(entity: entity, insertInto: moc)
            }
            else if let entity = NSEntityDescription.entity(forEntityName: entityName.uppercased(), in: moc)
            {
                return NSManagedObject(entity: entity, insertInto: moc)
            }
            else if let entity = NSEntityDescription.entity(forEntityName: entityName.lowercased(), in: moc)
            {
                return NSManagedObject(entity: entity, insertInto: moc)
            }
            
            return nil
        }
        
        if let entity = objectFor(table) { return entity }
        
        var trimmedString = table
        if table.hasSuffix("es")
        {
            trimmedString = String(table[table.startIndex..<table.index(table.endIndex, offsetBy: -2)])
            let t = trimmedString + "e"
            if let entity = objectFor(t)
            {
                return entity
            }
        }
        else if table.hasSuffix("s")
        {
            trimmedString = String(table[table.startIndex..<table.index(table.endIndex, offsetBy: -1)])
        }
        
        if let entity = objectFor(trimmedString) { return entity }
        
        //Fallback onto application settings
        guard let cDTableName = MSFrameworkManager.default.dataSource?.databaseToCoreDataInfo.first(where: { return $0.table == table })?.entity, let entity = NSEntityDescription.entity(forEntityName: cDTableName, in: moc) else { return nil }
        return NSManagedObject(entity: entity, insertInto: moc)
    }
    
    private func coreDataAttributeFrom(_ attribute: String, `in` object: NSManagedObject) -> String?
    {
        guard attribute != "" else { return "" }
        
        let properties = object.entity.properties
        func propertyFor(_ attributeName: String) -> String?
        {
            return properties.first { attributeName == $0.name || attributeName.lowercased() == $0.name || attributeName.uppercased() == $0.name || attributeName.capitalized == $0.name }?.name
        }
        
        if let attribute = propertyFor(attribute) { return attribute }
        
        var trimmedAttribute = attribute
        if attribute.hasSuffix("ies")
        {
            trimmedAttribute = String(attribute[attribute.startIndex..<attribute.index(attribute.endIndex, offsetBy: -3)])
            trimmedAttribute += "y"
        }
        else if attribute.hasSuffix("es")
        {
            trimmedAttribute = String(attribute[attribute.startIndex..<attribute.index(attribute.endIndex, offsetBy: -2)])
            trimmedAttribute += "e"
        }
        else if attribute.hasSuffix("s")
        {
            trimmedAttribute = String(attribute[attribute.startIndex..<attribute.index(attribute.endIndex, offsetBy: -1)])
        }
        
        if let attribute = propertyFor(trimmedAttribute) { return attribute }
        
        //Fallback onto application settings
        guard let entity = object.entity.name else { return nil }
        return MSFrameworkManager.default.dataSource?.databaseToCoreDataInfo.first { $0.entity == entity }?.attributesToCDAttributes[attribute]
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
