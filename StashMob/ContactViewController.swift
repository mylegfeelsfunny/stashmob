//
//  ContactViewController.swift
//  StashMob
//
//  Created by Scott Jones on 8/21/16.
//  Copyright © 2016 Scott Jones. All rights reserved.
//

import UIKit
import CoreData
import StashMobModel

class ContactViewController: UIViewController, ManagedObjectContextSettable, ManagedContactable, SegueHandlerType {
    
    weak var managedObjectContext: NSManagedObjectContext!
    weak var contactManager: Contactable!
    
    private typealias Data = DefaultDataProvider<ContactViewController>
    private var dataSource:TableViewDataSource<ContactViewController, Data, PlaceTableViewCell>!
    private var dataProvider: Data!
    
    var theView:TwoListViewable {
        guard let v = view as? TwoListViewable else { fatalError("The view is not a TwoListViewable") }
        return v
    }
    
    var remoteContact : RemoteContact!
    var sendPlaces:[RemotePlace]!
    var recievedPlaces:[RemotePlace]!
    var remotePlaceSelected:RemotePlace?
    var selectedPlaceRelation:PlaceRelation = .Sent
    
    enum SegueIdentifier:String {
        case PushToPlace                         = "pushToPlace"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let v = theView as? ContactView
        v?.didload()
        v?.populate(remoteContact)
        sentPicked()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if #available(iOS 8.3, *) {
            managedObjectContext.refreshAllObjects()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addHandlers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        removeHandlers()
    }
    
    func addHandlers() {
        theView.leftButton?.addTarget(self, action: #selector(sentPicked), forControlEvents: .TouchUpInside)
        theView.rightButton?.addTarget(self, action: #selector(receivedPicked), forControlEvents: .TouchUpInside)
        theView.backButton?.addTarget(self, action: #selector(pop), forControlEvents: .TouchUpInside)
    }
    
    func removeHandlers() {
        theView.leftButton?.removeTarget(self, action: #selector(sentPicked), forControlEvents: .TouchUpInside)
        theView.rightButton?.removeTarget(self, action: #selector(receivedPicked), forControlEvents: .TouchUpInside)
        theView.backButton?.removeTarget(self, action: #selector(pop), forControlEvents: .TouchUpInside)
    }
    
    var wasSent:Bool {
        return theView.leftButton?.backgroundColor == UIColor.blueColor()
    }
    
    // MARK: ButtonHandlers
    func pop() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func receivedPicked() {
        let received                                = managedObjectContext.receivedPlacesFrom(remoteContact)
        theView.highlightRecieved()
        
        if received.count == 0 {
            theView.emptyForRight()
            return
        }
        theView.hideEmptyState()
        dataProvider                                = DefaultDataProvider(items:received, delegate :self)
        dataSource                                  = TableViewDataSource(tableView:theView.tableView!, dataProvider: dataProvider, delegate:self)
        theView.tableView?.delegate                 = self
    }
    
    func sentPicked() {
        let sent                                    = managedObjectContext.sentPlacesTo(remoteContact)
        theView.highlightSent()
        
        if sent.count == 0 {
            theView.emptyForLeft()
            return
        }
        theView.hideEmptyState()
        dataProvider                                = DefaultDataProvider(items:sent, delegate :self)
        dataSource                                  = TableViewDataSource(tableView:theView.tableView!, dataProvider: dataProvider, delegate:self)
        theView.tableView?.delegate                 = self
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let mcs                               = segue.destinationViewController as? ManagedObjectContextSettable else { fatalError("DestinationViewController \(segue.destinationViewController.self) is not ManagedObjectContextSettable") }
        mcs.managedObjectContext                    = managedObjectContext
        
        switch segueIdentifierForSegue(segue) {
        case .PushToPlace:
            guard let vc = mcs as? DetailPlaceViewController else {
                fatalError("DestinationViewController \(segue.destinationViewController.self) is not DetailPlaceViewController")
            }
            guard let rps = remotePlaceSelected else { fatalError("Contact selected with out remoteContactSelected") }
            print(remoteContact)
            vc.remoteContact                        = remoteContact
            vc.placeRelation                        = selectedPlaceRelation
            vc.placeId                              = rps.placeId
            vc.remotePlace                          = rps
        }
    }
    
}

extension ContactViewController : UITableViewDelegate {
   
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let place = dataProvider.objectAtIndexPath(indexPath)
        remotePlaceSelected     = place
        selectedPlaceRelation   = (wasSent) ? .Sent : .Received
        
        performSegue(.PushToPlace)
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return PlaceTableViewCellHeight
    }
    
}

extension ContactViewController : DataProviderDelegate {
    func dataProviderDidUpdate(updates:[DataProviderUpdate<RemotePlace>]?) {
    }
}

extension ContactViewController : DataSourceDelegate {
    func cellIdentifierForObject(object:RemotePlace) -> String {
        return PlaceTableViewCell.Identifier
    }
}