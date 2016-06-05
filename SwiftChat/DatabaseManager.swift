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
    
    func reloadData(resultHandler: (EventList?, ErrorList?) -> Void)
    func fetchEventsCount(count: Int, fromItemId: Int, resultHandler: (EventList?, ErrorList?) -> Void)
    func sendText(text: String, resultHandler: (Event?, ErrorList?) -> Void)
    func saveData()
    
}

class DatabaseManager: DataSource {
    
    // MARK: - DataSource
    
    func reloadData(resultHandler: (EventList?, ErrorList?) -> Void) {
        fetchEventsCount(defaultNumberOfEventsToLoad, fromItemId: -1, resultHandler: resultHandler)
    }
    func fetchEventsCount(count: Int, fromItemId: Int, resultHandler: (EventList?, ErrorList?) -> Void) {
        
    }
    func sendText(text: String, resultHandler: (Event?, ErrorList?) -> Void) {
        
    }
    func saveData() {
        log.verbose("Save all managed object contexts")
        mainContext.performBlockAndWait { [unowned self] in
            self.log.verbose("Save main managed object contexts: \(self.mainContext)")
            self.saveManagedObjectContext(self.mainContext)
            self.masterContext.performBlock {
                self.log.verbose("Save master managed object contexts: \(self.masterContext)")
                self.saveManagedObjectContext(self.masterContext)
            }
        }
    }
    
    // MARK: - Public interface
    
    func configureCoreData(databaseFilename: String, resultHandler: () -> Void) {
        log.verbose("Initialize persistent store coordinator")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [unowned self] in
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.storeDirectory.URLByAppendingPathComponent(databaseFilename)
            let failureReason = "There was an error creating or loading the application's saved data."
            
            do {
                self.log.verbose("Add SQL persistent store at SQLite database")
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
            } catch {
                // Report any error we got.
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
                dict[NSLocalizedFailureReasonErrorKey] = failureReason
                dict[NSUnderlyingErrorKey] = error as NSError
                
                let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
                self.log.severe("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
                abort()
            }
            self.log.verbose("SQL persistent store initialized successfully")
            self.persistentStoreCoordinator = coordinator
        }
    }
    
    // MARK: - Lifecycle
    
    init(storeDirectory: NSURL, managedObjectModel: NSManagedObjectModel) {
        self.storeDirectory = storeDirectory
        self.managedObjectModel = managedObjectModel
    }
    
    // MARK: - Private - Core Data stack
    
    private let defaultNumberOfEventsToLoad = 20
    private let storeDirectory: NSURL
    private var managedObjectModel: NSManagedObjectModel
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    private lazy var masterContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    private lazy var mainContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.parentContext = self.masterContext
        return managedObjectContext
    }()
    private var workerContext: NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = self.mainContext
        return managedObjectContext
    }
    
    private func saveManagedObjectContext(managedObjectContext: NSManagedObjectContext) {
        guard managedObjectContext.hasChanges else {
            log.verbose("There are no changes in the managed object context: \(managedObjectContext)")
            return
        }
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            log.error("Failed to save the managed object context: \(managedObjectContext) - \(nserror), \(nserror.userInfo)")
            abort()
        }
        log.verbose("The managed object context saved successfully: \(managedObjectContext)")
    }
    
    // MARK: - Private - Logger

    private let log = XCGLogger.defaultInstance()

}
