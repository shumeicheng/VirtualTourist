//
//  TravelLocationMapViewController.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 7/24/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//
// Allows the user to drop pins around the world
import UIKit
import MapKit
import CoreData


class TravelLocationMapViewController: UIViewController , MKMapViewDelegate, PhotoAlbumViewControllerDelegate, NSFetchedResultsControllerDelegate

{
    @IBOutlet var myView: UIView!
    
    @IBOutlet weak var editButton: UIButton!

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    var selectedPin :Location!
    var currentAlbum : Album!
    var saveAnnotation: MKAnnotation!
    var savePointAnnotation: MKPointAnnotation!
    var AlbumViewController: PhotoAlbumViewController!
    var stack : CoreDataStack!
    var flickrDB = FlickrDB()
    
    var toRemove = false
    var selectedPinFetchedResultsController: NSFetchedResultsController!
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        // load pins from core data
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "longitude", ascending: true)]
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
    }()
    
    var sharedContext: NSManagedObjectContext {
        //return CoreDataStack.stack.context
        return stack.context
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if((saveAnnotation) != nil){
          //debugPrint("deselect pin")
          mapView.deselectAnnotation(saveAnnotation, animated: true)
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Get the stack
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        stack = delegate.stack

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationMapViewController.action(_:)))
        longPress.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPress)
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch{
            fatalError("failed to fetch core data!")
        }
        fetchedResultsController.delegate = self
    }
    
    func performUIUpdatesOnMain(updates: () -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            updates()
        }
    }

    func errorAlert(error:String, viewController:UIViewController){
        performUIUpdatesOnMain() {
            let alert = UIAlertController(title: "Alert", message: error , preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            if(viewController.presentedViewController==nil){
                viewController.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    // load pins from core data
    func mapViewWillStartLoadingMap(mapView: MKMapView) {
        
        stack.save()
        do {
             try fetchedResultsController.performFetch()
            
        } catch{}
        let pins = fetchedResultsController.fetchedObjects as! [Location]
        if ( pins.count == 0 ) {
            return
        }
        for index in 0  ... pins.count - 1  {
            let lat = self.myDouble (pins[index].latitude!.longLongValue )
            let long = self.myDouble (pins[index].longitude!.longLongValue)
         
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: long)
            createAnnotation(coord)
        }
    }
    
    func searchCoreData (long: Int64, lat: Int64, context: NSManagedObjectContext) -> Location? {
        // load pins from core data
        let fetchRequest = NSFetchRequest(entityName: "Location")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "longitude", ascending: true)]
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        let pred1 = NSPredicate(format: "longitude == \(long)")
        let pred2 = NSPredicate(format: "latitude == \(lat)")
        
        let compound = NSCompoundPredicate.init(
            andPredicateWithSubpredicates :[pred1,pred2])
        fetchRequest.predicate = compound
 
        selectedPinFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: context,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        do {
            try selectedPinFetchedResultsController.performFetch()
            
        } catch{}
       
        if(selectedPinFetchedResultsController.fetchedObjects!.count == 0 ){
            // no location in Core Data yet.
           return nil
        }
        let pins = selectedPinFetchedResultsController.fetchedObjects as! [Location]
        return pins[0]
    }
    
    // selected pin
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // create location entity 
        let long = Double((view.annotation?.coordinate.longitude)!)
        let lat = Double((view.annotation?.coordinate.latitude)!)
        saveAnnotation = view.annotation
        // while search for photos
        // either from coreData or download from Flickr
        selectedPin = searchCoreData(myInt(long),lat: myInt(lat),context: sharedContext)
        if(toRemove){
            mapView.removeAnnotation(view.annotation!)
            if(selectedPin != nil) {
               sharedContext.deleteObject(selectedPin)
               stack.save()
            }
            return // end of remove pin
        }

        // go to PhotoAlbumView now
        currentAlbum = selectedPin.album![0] as! Album
        self.performSegueWithIdentifier("PhotoAlbumSegue", sender: self)
        if( (selectedPin  != nil ) && (currentAlbum.pictures!.count == 0 )){ // no pictures yet!
            
            debugPrint("Waiting for loading")
            debugPrint(currentAlbum?.pictures!.count)
            flickrDB.searchByLocation(Double(long), latitude: Double(lat),  completionHandler: self.savePhotos)
        }
        self.photoAlbum(AlbumViewController)
    }

    func photoAlbum(controller: PhotoAlbumViewController) {
        controller.waitingForLoading = true
        controller.selectedPin = selectedPin
        controller.currentAlbum = currentAlbum
        controller.annotation = saveAnnotation
        controller.stack = stack
        controller.travelLocationController = self
    }

    func updateCollectionView(){
        AlbumViewController.waitingForLoading = false
        AlbumViewController.selectedPin = selectedPin
        AlbumViewController.initNSFetchedResultsController()
        AlbumViewController.albumView.reloadData()
        AlbumViewController.newCollectionButton.enabled = true
    }
    
    func createAnnotation(coord: CLLocationCoordinate2D) {
        let newAnotation = MKPointAnnotation()
        newAnotation.coordinate = coord
        mapView.addAnnotation(newAnotation)
        savePointAnnotation = newAnotation
    }
    
    func getGesturePoint(gesture: UIGestureRecognizer) -> CLLocationCoordinate2D {
        var newCoord:CLLocationCoordinate2D!
        var touchPoint : CGPoint!
        
        touchPoint = gesture.locationInView(self.mapView)
        newCoord = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

        return newCoord
    }
    
    // for mapview adding new pins
    func action(gestureRecognizer:UIGestureRecognizer) {
        var newCoord: CLLocationCoordinate2D
        
        switch (gestureRecognizer.state){
           
        case .Began:
           
            newCoord = self.getGesturePoint(gestureRecognizer)
            createAnnotation(newCoord)
            
        case .Changed:
         
            newCoord = getGesturePoint(gestureRecognizer)
            savePointAnnotation.coordinate=newCoord
            
        case .Ended, .Cancelled:
       
            newCoord = getGesturePoint(gestureRecognizer)

            if(searchCoreData(self.myInt(newCoord.longitude),lat: self.myInt(newCoord.latitude) ,context:sharedContext) != nil ) {
                return
            }
            
            _ = Location(long: self.myInt(newCoord.longitude),lat: self.myInt(newCoord.latitude),context: self.sharedContext)
            //save the context here immediately after it is droppeed
            
            stack.save()

        default:break
        }
     }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Ok"
        navigationItem.backBarButtonItem = backItem
        AlbumViewController = segue.destinationViewController as! PhotoAlbumViewController
        AlbumViewController.delegate = self
        
        
    }
    
    func savePhotos( photoArray:[[String:AnyObject]],pageNo:Int32){
        if(photoArray.count == 0 ){
            errorAlert("no album found", viewController: self)
            return
        }
        debugPrint("found ", photoArray.count, "pictures")
        // child context  when it is saved, it should be accessible by parent contex
        stack.context.performBlock {
          // currentAlbum should be set already
          self.currentAlbum.setValue(NSNumber(int: pageNo), forKey: "pageNo")
          for index in 0 ... photoArray.count - 1 {
            let picArray = photoArray[index] as? [String:AnyObject]
            self.savePhoto(picArray!,album: self.currentAlbum)
          }
        }
        self.performUIUpdatesOnMain {
            self.updateCollectionView()
        }
    }
    
    func savePhoto(picArray:  [String:AnyObject], album:Album)  {
        if (picArray[Constants.FlickrResponseKeys.MediumURL] != nil) {
            let urlString = (picArray[Constants.FlickrResponseKeys.MediumURL] as? String)!
            //download image on demand in PhotoAlbumViewController
          
            var imageData:NSData?
            _ = Picture(urlString: urlString, album: album,context: sharedContext)
            stack.save()
            
        }
        
    }
    
    func removeAnnotation(gesture: UIGestureRecognizer) {
        
       if gesture.state == UIGestureRecognizerState.Ended {
        
            toRemove = true
            let touchPoint = gesture.locationInView(self.mapView)
            let newCoord:CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
     
            self.mapView.removeAnnotation(saveAnnotation)
            saveAnnotation = nil
            sharedContext.deleteObject(selectedPin)
       }
    }
    
    @IBAction func DeleteButtonPressed(sender: AnyObject) {
        if(editButton.titleLabel!.text == "Edit") {
            toRemove = true
            editButton.setTitle("Done", forState: .Normal)
            infoLabel.hidden = false
            UIView.animateWithDuration(1, animations: {
       
            self.mapView.frame.origin.y -= 66 // 66 is the label height
            self.infoLabel.hidden = false
            })
        }else{
            
            do {try sharedContext.save()}
            catch{}
            toRemove = false
            editButton.setTitle("Edit", forState: .Normal)
            self.mapView.frame.origin.y += 66
            self.infoLabel.hidden = true
        }
    }

    // precision for latitude and longitude Double -> Int 
    private func myInt(value: Double) -> Int64{
        return  Int64(value * 100000 )
    }
    
    private func myDouble(value: Int64) -> Double {
        return Double ( Double(value) * 0.00001)
    }
}

