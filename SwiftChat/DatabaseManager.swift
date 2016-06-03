//
//  DatabaseManager.swift
//  SwiftChat
//
//  Created by Антон on 03.06.16.
//  Copyright © 2016 Akademon Ltd. All rights reserved.
//

import Foundation
import CoreData

protocol DataSource {
    
    var managedObjectContext: NSManagedObjectContext { get }
    func saveContext()
    
}

class DatabaseManager: DataSource {
    
    // MARK: - Public interface

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
        // This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    func saveContext() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    // MARK: - Core Data stack
    
    private lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file.
        // This code uses a directory named "ru.akademon.SwiftChat" in the application's documents Application Support directory.
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional.
        // It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("SwiftChat", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application.
        // This implementation creates and returns a coordinator, having added the store for the application to it.
        // This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error as NSError
            
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        return coordinator
    }()

}