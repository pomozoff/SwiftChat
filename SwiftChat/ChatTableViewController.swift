//
//  ChatTableViewController.swift
//  SwiftChat
//
//  Created by Антон on 03.06.16.
//  Copyright © 2016 Akademon Ltd. All rights reserved.
//

import UIKit
import XCGLogger

class ChatTableViewController: UITableViewController {
    
    // MARK: - Properties

    var dataSource: DataSource? {
        didSet {
            log.debug("Data source has been updated to: \(dataSource)")
            guard let newDataSource = dataSource else {
                log.warning("Data source is nil, clear table")
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.eventList = EventList()
                    self?.tableView.reloadData()
                }
                return
            }
            newDataSource.reloadData() { [weak self] eventList, errorList in
                guard let liveSelf = self else {
                    XCGLogger.defaultInstance().debug("ChatTableViewController is dead")
                    return
                }
                if let gotErrorList = errorList {
                    liveSelf.log.error("Failed to reload data: \(gotErrorList)")
                    return
                }
                guard let newEventList = eventList else {
                    liveSelf.log.error("Failed to reload data, new event list is nil")
                    return
                }
                dispatch_async(dispatch_get_main_queue()) {
                    liveSelf.log.verbose("Load new events: \(newEventList)")
                    liveSelf.eventList = newEventList
                    liveSelf.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    
    // MARK: - Private - Logger
    
    private let log = XCGLogger.defaultInstance()
    
    private var eventList = EventList()

}
