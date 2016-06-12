//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Victor Hong on 3/17/16.
//  Copyright © 2016 Victor Hong. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    var pin = Selection.sharedInstance().selectedPin
    
    let cellReuseIdentifier = "PhotoCollectionViewCell"
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
       
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    let cellsPerRowInPortrait: CGFloat = 3
    let cellsPerRowInLandscape: CGFloat = 6
    let minimumSpacingPerCell: CGFloat = 5
    
    private let photoPlaceHolder = UIImage(named: "photoPlaceHolder")
    
    private struct ToolbarButtonTitle {
        static let newCollection = "New Collection"
        static let delete = "Delete Selected Photos"
    }
    
    private var selectedIndex = [NSIndexPath]()
    private var insertedIndex: [NSIndexPath]!
    private var deletedIndex: [NSIndexPath]!
    private var updatedIndex: [NSIndexPath]!
    private var numberOfPhotoCurrentlyDownloading = 0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var button: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doubleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PhotoAlbumViewController.didDoubleTapCollectionView(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        doubleTapGesture.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(doubleTapGesture)
        
        noImageLabel.hidden = true
        mapView.userInteractionEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        activityIndicator.hidesWhenStopped = true
        setToolbarTitle()
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Fetch failed: \(error)")
        }
        
        if (pin?.photo.isEmpty) != nil {
            
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let region = MKCoordinateRegionMakeWithDistance((pin?.coordinate)!, 100_000, 100_000)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(pin!)
        
        displayToolbarState()
        
    }

    @IBAction func toolbarButtonAction(sender: AnyObject) {
        
        if selectedIndex.count > 0 {
            deleteSelectedPhotos()
        }else {
            createNewPhoto()
        }
        
    }
    
    private func getFlickrPhoto() {
        
        activityIndicator.startAnimating()
        
        if pin?.photoFetchInProgress == true {
            return
        } else {
            pin?.photoFetchInProgress = true
        }
        
        noImageLabel.hidden = true
        button.enabled = false
        
        FlickrClient.sharedInstance().downloadPhotosForPin(pin!, completionHandler: {
            success, error in
            
            if error != nil {
                self.activityIndicator.stopAnimating()
                self.button.enabled = true
                self.noImageLabel.hidden = false
            } else {
                self.activityIndicator.stopAnimating()
                self.button.enabled = true
            }
            self.pin?.photoFetchInProgress = false
        })
        
    }
    
    private func createNewPhoto() {
        
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for object in fetchedObjects {
                let photo = object as! Photo
                sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        getFlickrPhoto()
        
    }
    
    private func deleteSelectedPhotos() {
        
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndex {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        selectedIndex = [NSIndexPath]()
        setToolbarTitle()
        displayToolbarState()
        
    }
    
    private func setToolbarTitle() {
        if selectedIndex.count > 0 {
            button.title = ToolbarButtonTitle.delete
        } else {
            button.title = ToolbarButtonTitle.newCollection
        }
    }
    
    private func displayToolbarState() {
        if button.title == ToolbarButtonTitle.newCollection {
            if pin?.photoFetchInProgress == true || numberOfPhotoCurrentlyDownloading > 0 {
                button.enabled = false
            } else {
                button.enabled = true
            }
        } else {
            button.enabled = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = UICollectionViewFlowLayout()
        
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = minimumSpacingPerCell
        layout.minimumInteritemSpacing = minimumSpacingPerCell
        
        var width: CGFloat!
        
        if UIApplication.sharedApplication().statusBarOrientation.isLandscape == true {
            width = (CGFloat(collectionView.frame.size.width) / cellsPerRowInLandscape) - (minimumSpacingPerCell - (minimumSpacingPerCell / cellsPerRowInLandscape))
        } else {
            width = (CGFloat(collectionView.frame.size.width) / cellsPerRowInPortrait) - (minimumSpacingPerCell - (minimumSpacingPerCell / cellsPerRowInPortrait))
        }
        
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
        
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        collectionView.performBatchUpdates(nil, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if photo.didFetchImage == false {
            return false
        }
        
        return true
        
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if photo.didFetchImage == false {
            return false
        }
        
        return true
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        selectedIndex.append(indexPath)
        
        setToolbarTitle()
        displayToolbarState()
        
    
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        if let index = selectedIndex.indexOf(indexPath) {
            selectedIndex.removeAtIndex(index)
        }
        
        setToolbarTitle()
        displayToolbarState()
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = self.fetchedResultsController.sections![section]
        print(sectionInfo.numberOfObjects)
        
        return sectionInfo.numberOfObjects
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
        
    }
    
    func configureCell(cell: PhotoAlbumCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let imageData = photo.imageData {
            cell.activityIndicator.stopAnimating()
            cell.backgroundView = UIImageView(image: imageData)
        } else {
            cell.backgroundView = UIImageView(image: photoPlaceHolder)
            cell.activityIndicator.startAnimating()
            
            if photo.fetchInProgress == false {
                numberOfPhotoCurrentlyDownloading += 1
                photo.fetchImageData { fetchComplete in
                    self.numberOfPhotoCurrentlyDownloading -= 1
                    if fetchComplete == true {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.displayToolbarState()
                        }
                    }
                }
            }
        }
        
        displayToolbarState()
        
        let backgroundView = UIView(frame: cell.contentView.frame)
        backgroundView.backgroundColor = UIColor(red: 200, green: 200, blue: 200, alpha: 0.8)
        
        let checkmarkImageViewFrame = CGRect(x: cell.contentView.frame.origin.x, y: cell.contentView.frame.origin.y, width: cell.frame.width, height: cell.frame.height)
        let checkmarkImageView = UIImageView(frame: checkmarkImageViewFrame)
        checkmarkImageView.contentMode = UIViewContentMode.BottomRight
        checkmarkImageView.image = UIImage(named: "checkmark")
        backgroundView.addSubview(checkmarkImageView)
        
        cell.selectedBackgroundView = backgroundView
        
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertedIndex = [NSIndexPath]()
        deletedIndex = [NSIndexPath]()
        updatedIndex = [NSIndexPath]()
        
        self.activityIndicator.stopAnimating()
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndex.append(newIndexPath!)
        case .Delete:
            deletedIndex.append(indexPath!)
        case .Update:
            updatedIndex.append(indexPath!)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndex {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndex {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndex {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: nil)
    }
    
    func didDoubleTapCollectionView(gesture: UITapGestureRecognizer) {
        
        if gesture.state != .Ended {
            return
        }
        
        let point = gesture.locationInView(self.collectionView)
        if let indexPath = self.collectionView.indexPathForItemAtPoint(point) {
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            Selection.sharedInstance().selectedImage = photo.imageURL
            self.performSegueWithIdentifier("showImage", sender: self)
        }
        
    }
}
