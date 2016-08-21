//
//  RecievedPlaceViewController.swift
//  StashMob
//
//  Created by Scott Jones on 8/20/16.
//  Copyright © 2016 Scott Jones. All rights reserved.
//

import UIKit
import CoreData
import GooglePlaces
import StashMobModel

enum PlaceRelation {
    case Received
    case Sent
}
extension PlaceRelation {
    var asString:String {
        switch self {
        case .Received:
            return NSLocalizedString("sent you", comment: "PlaceRelation : Recieved : text")
        case .Sent:
            return NSLocalizedString("was sent", comment: "PlaceRelation : Sent : text")
        }
    }
}

class PlaceViewController: UIViewController, ManagedObjectContextSettable, ManagedContactable {
        
    weak var managedObjectContext: NSManagedObjectContext!
    weak var contactManager: Contactable!
    private var gmController:GMCenteredController!
    
    var remoteContact:RemoteContact!
    var placeRelation:PlaceRelation!
    var remotePlace:RemotePlace? {
        didSet {
           updatePlaceAndMap()
        }
    }
    var placeId:String?
    private typealias Data = DefaultDataProvider<PlaceViewController>
    private var dataSource:TableViewDataSource<PlaceViewController, Data, PlaceFeatureTableViewCell>!
    private var dataProvider: Data!
    
    var theView:PlaceView {
        guard let v = view as? PlaceView else { fatalError("The view is not a PlaceView") }
        return v
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        theView.didload()
        theView.populateContact(remoteContact, placeRelation:placeRelation)
        if let pm = placeId {
            fetchPlace(pm)
        } else if let pm = remotePlace?.placeId {
            fetchPlace(pm)
        }
        updatePlaceAndMap()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        theView.exitButton?.addTarget(self, action: #selector(dismiss), forControlEvents: .TouchUpInside)
    }
    
    func removeHandlers() {
        theView.exitButton?.removeTarget(self, action: #selector(dismiss), forControlEvents: .TouchUpInside)
    }
    
    // MARK : Button handlers
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
   
    func savePlace() {
        guard let rp = remotePlace else {
            return
        }
        managedObjectContext.recieve(rp, fromContact:self.remoteContact)
    }
    
    func fetchPlace(placeId:String) {
        let placeClient             = GMSPlacesClient()
        placeClient.lookUpPlaceID(placeId, callback: { [weak self] place, error in
            if let _ = error {
                self?.alertBadThingsWithRetryBlock {
                    self?.dismiss()
                }
                return
            }
            
            if let place = place {
                self?.remotePlace = place.toRemotePlace()
                self?.savePlace()
            } else {
                self?.alertBadThingsWithRetryBlock {
                    self?.dismiss()
                }
            }
        })

    }
    
    func updatePlaceAndMap() {
        guard let rp = remotePlace else {
            return
        }
        theView.populatePlace(rp)
        let image = (placeRelation == .Received) ? remoteContact.getPinImage() : UIImage(named:"event_pin")
        gmController                                = GMCenteredController(mapView: theView.mapView!, coordinate:rp.coordinate, image:image)
        
        dataProvider                                = DefaultDataProvider(items:rp.tableData, delegate :self)
        dataSource                                  = TableViewDataSource(tableView:theView.tableView!, dataProvider: dataProvider, delegate:self)
        theView.tableView?.delegate                 = self
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Alert
    
    func alertBadThingsWithRetryBlock(block:()->()) {
        let alertTitle              = NSLocalizedString("Whoa! Thats not a place", comment: "RecievedPlaceViewController : error : alertTitle  ")
        let alertMessage            = NSLocalizedString("Lets get outta here!", comment: "RecievedPlaceViewController : error : message")
        let dismissText             = NSLocalizedString("Dismiss", comment: "RecievedPlaceViewController : error : forgetit")
        
        let alertController         = UIAlertController(title:alertTitle, message:alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        let dismissAction          = UIAlertAction(title: dismissText, style: .Default)  { action in
            block()
        }
        alertController.addAction(dismissAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
}


extension PlaceViewController : UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return PlaceFeatureTableViewCellHeight
    }
    
}

extension PlaceViewController : DataProviderDelegate {
    func dataProviderDidUpdate(updates:[DataProviderUpdate<PlaceFeature>]?) {
    }
}

extension PlaceViewController : DataSourceDelegate {
    func cellIdentifierForObject(object:PlaceFeature) -> String {
        return PlaceFeatureTableViewCell.Identifier
    }
}
