//
//  DatabaseManager.swift
//  SwiftChat
//
//  Created by Антон on 03.06.16.
//  Copyright © 2016 Akademon Ltd. All rights reserved.
//

import Foundation
import CoreData
import XCGLogger

typealias ErrorList = [ErrorType]

protocol DataSource {
    
    func fetchEventsCount(count: Int, fromItemId: Int, resultHandler: (EventList?, ErrorList?) -> Void)
    func sendText(text: String, resultHandler: (Event?, ErrorList?) -> Void)
    func saveData()
    
}

class DatabaseManager: DataSource {
    
    // MARK: - DataSource

    func fetchEventsCount(count: Int, fromItemId: Int, resultHandler: (EventList?, ErrorList?) -> Void) {
        
    }
    func sendText(text: String, resultHandler: (Event?, ErrorList?) -> Void) {
        
    }
    func saveData() {
        let log = XCGLogger.defaultInstance()
        log.verbose("Save all managed object contexts")
        guard mainContext.hasChanges else {
            log.info("There are no changes in the current managed object context")
            return
        }
        mainContext.performBlockAndWait { [unowned self] in
            log.verbose("Save main managed object contexts - \(self.mainContext)")
            self.saveManagedObjectContext(self.mainContext)
            self.masterContext.performBlock {
                log.verbose("Save master managed object contexts - \(self.masterContext)")
                self.saveManagedObjectContext(self.masterContext)
            }
        }
    }
    
    // MARK: - Private - Core Data stack
    
    private lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file.
        // This code uses a directory named "ru.akademon.SwiftChat" in the application's documents Application Support directory.
        
        let log = XCGLogger.defaultInstance()
        log.verbose("Obtain application's document directory")
        
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
    }()
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional.
        // It is a fatal error for the application not to be able to find and load its model.
        
        let log = XCGLogger.defaultInstance()
        log.verbose("Load managed object model")

        let modelURL = NSBundle.mainBundle().URLForResource("SwiftChat", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application.
        // This implementation creates and returns a coordinator, having added the store for the application to it.
        // This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        
        let log = XCGLogger.defaultInstance()
        log.verbose("Initialize persistent store coordinator")
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            log.verbose("Add SQL persistent store at SQLite database")
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
            log.severe("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        log.verbose("SQL persistent store initialized successfully")
        return coordinator
    }()
    
    private lazy var masterContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
        // This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    private lazy var mainContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.parentContext = self.masterContext
        return managedObjectContext
    }()
    private lazy var workerContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = self.mainContext
        return managedObjectContext
    }()
    
    private func saveManagedObjectContext(managedObjectContext: NSManagedObjectContext) {
        do {
            try managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful during development.
            
            let nserror = error as NSError
            log.error("Failed to save the managed object context - \(managedObjectContext) - \(nserror), \(nserror.userInfo)")
            abort()
        }
        log.verbose("The managed object context saved successfully - \(managedObjectContext)")
    }
    
    // MARK: - Private - Logger

    private let log = XCGLogger.defaultInstance()

}
