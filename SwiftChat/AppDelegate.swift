//
//  AppDelegate.swift
//  SwiftChat
//
//  Created by Антон on 03.06.16.
//  Copyright © 2016 Akademon Ltd. All rights reserved.
//

import UIKit
import XCGLogger

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        configureLogger()
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        // or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates.
        // Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        log.info("Did enter background")
        runBackgroundSave()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state;
        // here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
        log.info("Application will terminate")
        saveData()
    }
    
    // MARK: - Private - Save Data
    
    private lazy var dataSource = DatabaseManager()
    private func saveData() {
        log.verbose("Save core data")
        dataSource.saveContext()
        log.verbose("Save core data")
    }
    private func runBackgroundSave() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] in
            guard let liveSelf = self else {
                let log = XCGLogger.defaultInstance()
                log.error("Self is nil, can't start background task to save core data")
                return
            }
            let backgroundTaskId = liveSelf.beginBackgroundUpdateTask()
            liveSelf.saveData()
            liveSelf.endBackgroundUpdateTask(backgroundTaskId)
        }
    }
    private func beginBackgroundUpdateTask() -> UIBackgroundTaskIdentifier {
        log.verbose("Start background task")
        var backgroundTaskId = UIBackgroundTaskInvalid
        backgroundTaskId = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
            let log = XCGLogger.defaultInstance()
            guard backgroundTaskId != UIBackgroundTaskInvalid else {
                log.warning("Background task's id is nil")
                return
            }
            log.warning("Background task with id '\(backgroundTaskId)' has been expired")
        }
        return backgroundTaskId
    }
    private func endBackgroundUpdateTask(backgroundTaskId: UIBackgroundTaskIdentifier) {
        UIApplication.sharedApplication().endBackgroundTask(backgroundTaskId)
        log.verbose("Background task finished")
    }
    
    // MARK: - Private - Logger
    
    private let log = XCGLogger.defaultInstance()
    private func configureLogger() {
        let logFileName = "SwiftChat.log"
        let tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tempFileURL = tempDirectoryURL.URLByAppendingPathComponent(logFileName)
        
        log.setup(.Debug,
                  showThreadName: true,
                  showLogLevel: true,
                  showFileNames: true,
                  showLineNumbers: true,
                  writeToFile: tempFileURL,
                  fileLogLevel: .Info)
    }
    
}
