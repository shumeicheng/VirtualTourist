

//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 7/24/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//
// Allow the user to download and edit an album for a location
import Foundation

import MapKit
import CoreData

protocol PhotoAlbumViewControllerDelegate {
    func photoAlbum(controller: PhotoAlbumViewController)
}


class PhotoAlbumViewController: UIViewController , MKMapViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate, NSFetchedResultsControllerDelegate{
    var annotation: MKAnnotation!
    var delegate: PhotoAlbumViewControllerDelegate?
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet var albumUIVIew: UIView!
    @IBOutlet weak var albumView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
  
    
    var waitingForLoading = true
    var colums: CGFloat = 3.0
    var selectedPin: Location!
    var currentAlbum: Album!
    var pageIndex = 0
    let PICPERPAGE = 9
    var numberOfPicToShowPerPage = 9
    var lastIndex = 0
    var selectedPicToRemove = [NSIndexPath:Picture]()
    var needDeletePictures :Bool = false
    var stack : CoreDataStack!
    var fetchedResultsController: NSFetchedResultsController!
    var travelLocationController : TravelLocationMapViewController!
    
    // use fetechedResultsController to get the update data changes
    func initNSFetchedResultsController (){
        fetchedResultsController = nil
        let request = NSFetchRequest(entityName: "Picture")
        let urlStringSort = NSSortDescriptor(key: "urlString", ascending:true)
        request.sortDescriptors = [urlStringSort]
   
        request.predicate = NSPredicate(format: "album == %@", currentAlbum!)

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        performSearchForPictures()
        
    }
    
    func performSearchForPictures (){
        do {
          
            try fetchedResultsController.performFetch()
      
        }catch{
            fatalError("Failed to initialize FetchedResultsController for Pictures: \(error)")
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initNSFetchedResultsController()
        
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        stack = delegate.stack

        self.mapView.delegate = self
        if (fetchedResultsController.fetchedObjects!.count == 0){
            newCollectionButton.enabled = false
        }else {
            debugPrint("total pic to shows", fetchedResultsController.fetchedObjects!.count)
            albumView.reloadData()
        }
        
        let space: CGFloat = 1.0
        let dimension = (view.frame.size.width - (2 * space)) / colums
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        
        albumView.allowsMultipleSelection = true;
 
        self.fetchedResultsController.delegate = self
      
        do {
            try fetchedResultsController.performFetch()
            
        } catch{
            fatalError("failed to fetch core data!")
        }
     }
    
    override func viewWillAppear(animated: Bool) {
        // zoom in view
        let span = MKCoordinateSpanMake(0.075, 0.075)
        let lat = annotation.coordinate.latitude
        let long = annotation.coordinate.longitude
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), span: span)
        mapView.setRegion(region, animated: true)
        var arrayOfAnnotations = [MKAnnotation]()
        arrayOfAnnotations.append(annotation)
        mapView.showAnnotations(arrayOfAnnotations, animated: true)
    }
 
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      
        let num = fetchedResultsController.fetchedObjects?.count
        debugPrint("show pictures", num)
        return num!
    }
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // remember which cells seletected
        changeButtonText(true)
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture

        selectedPicToRemove[indexPath] = picture
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        // remove the cell from the selections
        selectedPicToRemove.removeValueForKey(indexPath)
    }
   
    func displayImage(cell: PhotoAlbumViewCell, imageData: NSData){
         // use main queue to display
        dispatch_async(dispatch_get_main_queue()) {
            cell.imageView.image = UIImage(data:imageData)
            cell.indicatorView.stopAnimating()
        }
    }
    
    func loadURLImage(cell: PhotoAlbumViewCell,picture:Picture, nsurl:NSURL)-> NSData!{
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: nsurl)
        var imageData : NSData! 
        let task = session.dataTaskWithRequest(request){ (data,response,error) in
            
            guard( error == nil ) else {
                print("Error: when loading url image.")
                return
            }
            guard( data != nil ) else{
                print ("failed to load image from url")
                return
            }
            // save image data to CoreData
            self.displayImage(cell, imageData: data!)
            imageData = data
        }
        task.resume()
        return imageData
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoAlbumViewCell", forIndexPath: indexPath) as! PhotoAlbumViewCell
        cell.imageView.image = nil
        cell.indicatorView.startAnimating()
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        let imageData = picture.picImage
        if( imageData == nil){ // URL image is not loaded yet.
            loadURLImage(cell, picture: picture, nsurl:NSURL(string: picture.urlString!)! )
            picture.setValue(imageData, forKey: "picImage")
            stack.save()
        }else {
           displayImage(cell, imageData: imageData!)
        }

        return cell
    }
    
    func changeButtonText(deleteMode:Bool){
        if(deleteMode == true) {
            newCollectionButton.setTitle( "Remove selected Pictures", forState:.Normal)
            needDeletePictures = true
        }else{
            newCollectionButton.setTitle ( "New Collection" , forState: .Normal)
            needDeletePictures = false
        }
        
    }
    
    func getNextAlbum() -> Album?{
        pageIndex = pageIndex + 1
        if(pageIndex == selectedPin.album!.count ){
            return nil
        }else {
            return selectedPin.album![pageIndex] as? Album
        }
    }
    
      @IBAction func getNewCollection(sender: AnyObject) {
        if((needDeletePictures) == true){
            var indexpaths = [ NSIndexPath]()
            
            for ( indexPath ,pic) in selectedPicToRemove {
                indexpaths.append(indexPath)
                // delete from the CoreData
                stack.context.deleteObject(pic)
                stack.save()
            }
            //numberOfPicToShowPerPage = PICPERPAGE -  indexpaths.count
            performSearchForPictures()
           // albumView.deleteItemsAtIndexPaths(indexpaths)
            selectedPicToRemove.removeAll()
            changeButtonText(false) // back to newCollection button
            albumView.reloadData()
          
        }else {
            newCollectionButton.enabled = true
            
            currentAlbum =  getNextAlbum()
            if( currentAlbum == nil) {
              currentAlbum = Album(location: selectedPin, context: stack.context)
              travelLocationController.currentAlbum = currentAlbum
              let long = Double(annotation.coordinate.longitude)
              let lat = Double((annotation?.coordinate.latitude)!)
              // get another new set of photos from flickr
              travelLocationController.flickrDB.searchByLocation(long, latitude: lat, completionHandler:   travelLocationController.savePhotos)
            }else{
          
              initNSFetchedResultsController()
              albumView.reloadData()
            }
            
        }
       
 
    }

}

