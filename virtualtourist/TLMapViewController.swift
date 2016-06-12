//
//  TLMapViewController.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/17/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TLMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var selectedPin: Pin? = nil
    var inEditMode = false
    
    let pinIdentifier = "pinIdentifier"
    
    var dragState = false
    
    lazy var sharedContext = {
        CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        addPin()
        
        let pins = fetchAllPins()
        
        if !pins.isEmpty {
            for pin in pins {
                mapView.addAnnotation(pin)
            }
        }

    }

    override func viewWillAppear(animated: Bool) {
        
        let location = fetchCurrentLocation()
        
        mapView.centerCoordinate.longitude = Double(location.latitude!)
        mapView.centerCoordinate.latitude = Double(location.longitude!)
        
        let mapSpan = MKCoordinateSpanMake(Double(location.latitudeDelta!), Double(location.longitudeDelta!))
        mapView.region = MKCoordinateRegionMake(mapView.centerCoordinate, mapSpan)
        
        displayEditButton()
        displayToolbar()
        
    }
    
    @IBAction func editButton(sender: AnyObject) {
        
        inEditMode = inEditMode == true ? false : true
        
        if inEditMode == true {
            editButton.title = "Done"
            removePin()
        } else {
            editButton.title = "Edit"
            addPin()
        }
        
        displayEditButton()
        displayToolbar()
    }

    @IBAction func segmentedControl(sender: UISegmentedControl) {
        
        switch (sender.selectedSegmentIndex) {
        case 0:
            mapView.mapType = .Standard
        case 1:
            mapView.mapType = .Satellite
        default:
            mapView.mapType = .Standard
        }
        
    }
    
    func addPin() {
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TLMapViewController.dropPin(_:)))
        longPressGestureRecognizer.minimumPressDuration = 1.0
        view.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func removePin() {
        view.removeGestureRecognizer(longPressGestureRecognizer)
    }
    
    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let touchCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let pin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, context: sharedContext)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        mapView.addAnnotation(pin)
        displayEditButton()
        getFlickrPhoto(pin)
        
    }
    
    func deletePin(pin: Pin) {
        mapView.removeAnnotation(pin)
        sharedContext.deleteObject(pin)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func updatePin(pin: Pin) {
        
        if pin.photo.isEmpty {
            for photo in pin.photo {
                photo.pin = nil
            }
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        getFlickrPhoto(pin)
        
    }
    
    func getFlickrPhoto(pin: Pin) {
        
        if pin.photoFetchInProgress == true {
            return
        } else {
            pin.photoFetchInProgress = true
        }
        
        FlickrClient.sharedInstance().downloadPhotosForPin(pin, completionHandler: {
            success, error in
            
            if error != nil {
                //alert
            } else {
                
            }
            pin.photoFetchInProgress = false
        })

    }
    
    private func displayEditButton() {
        if fetchAllPins().count > 0 {
            editButton.enabled = true
        } else {
            editButton.enabled = false
        }
    }
    
    private func displayToolbar() {
        if inEditMode == true {
            toolbar.hidden = false
        } else {
            toolbar.hidden = true
        }
    }
    
    func fetchAllPins() -> [Pin] {
        
        let fetchRequest = NSFetchRequest()
        
        fetchRequest.entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: sharedContext)
        
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch {
            return [Pin]()
        }
        
    }
    
    func fetchCurrentLocation() -> LocationModel {
        
        let fetchRequest = NSFetchRequest(entityName: "LocationModel")
        do {
            let infoArray = try sharedContext.executeFetchRequest(fetchRequest) as! [LocationModel]
            if infoArray.count > 0 {
                return infoArray[0]
            } else {
                NSEntityDescription.insertNewObjectForEntityForName("LocationModel", inManagedObjectContext: sharedContext) as! LocationModel
                let defaultInfo = makeMapDictionary()
                return LocationModel(dictionary: defaultInfo, context: sharedContext)
            }
        } catch let error as NSError {
            print("Error in fetchMapInfo(): \(error)")
            let defaultInfo = makeMapDictionary()
            return LocationModel(dictionary: defaultInfo, context: sharedContext)
        }
        
    }
    
    func saveLocation() {
        
        _ = makeMapDictionary()
        deleteLocation()
        _ = NSFetchRequest(entityName: "LocationModel")
        
        let location = NSEntityDescription.insertNewObjectForEntityForName("LocationModel", inManagedObjectContext: sharedContext) as! LocationModel
        
        location.latitude = NSNumber(double: mapView.centerCoordinate.latitude)
        location.longitude = NSNumber(double: mapView.centerCoordinate.longitude)
        location.latitudeDelta = NSNumber(double: mapView.region.span.latitudeDelta)
        location.longitudeDelta = NSNumber(double: mapView.region.span.longitudeDelta)
        
        saveContext()
        
    }
    
    func deleteLocation() {
        
        let fetchRequest = NSFetchRequest(entityName: "LocationModel")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try sharedContext.executeRequest(deleteRequest)
        } catch let error as NSError {
            print("Error in deleteLocation: \(error)")
        }
        
    }
    
    func makeMapDictionary() -> [String: AnyObject] {
        
        let mapDictionary = [
            "latitude": NSNumber(double: mapView.centerCoordinate.latitude),
            "longitude": NSNumber(double: mapView.centerCoordinate.longitude),
            "latitudeDelta": NSNumber(double: mapView.region.span.latitudeDelta),
            "longitudeDelta": NSNumber(double: mapView.region.span.longitudeDelta),
            "zoom": NSNumber(double: 1.0)
        ]
        
        return mapDictionary
        
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(pinIdentifier) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinIdentifier)
        } else {
            pinView?.annotation = annotation
        }
        
        pinView?.animatesDrop = true
        pinView?.draggable = true
        
        pinView?.setSelected(true, animated: false)
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        saveLocation()
        
        mapView.deselectAnnotation(view.annotation, animated: false)
        view.setSelected(true, animated: false)
        
        let pin = view.annotation as! Pin
        
        if dragState == true {
            deletePin(pin)
        } else {
            Selection.sharedInstance().selectedPin = pin
            self.performSegueWithIdentifier("showPhotoAlbum", sender: self)
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if newState == MKAnnotationViewDragState.Ending {
            dragState = true
        }
        
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        _ = makeMapDictionary()
        saveLocation()
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    func saveContext() {
        dispatch_async(dispatch_get_main_queue()) {
            _ = try? self.sharedContext.save()
        }
    }

    func alertAction(titleMessage: String) {
        let alert = UIAlertController(title: titleMessage, message: nil, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
