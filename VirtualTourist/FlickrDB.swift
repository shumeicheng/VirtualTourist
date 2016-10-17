//
//  FlickrDB.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 8/7/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import UIKit

class FlickrDB {
    typealias CompletionHandler = (photoArray: [[String:AnyObject]],pageNo:Int32) -> Void
    private func bboxString(lo:Double, lat: Double)-> String{
        var maxLo = min(lo + Constants.Flickr.SearchBBoxHalfWidth,Constants.Flickr.SearchLonRange.1)
        
        var minLo = max(lo - Constants.Flickr.SearchBBoxHalfWidth,Constants.Flickr.SearchLonRange.0)
        var maxLa = min(lat + Constants.Flickr.SearchBBoxHalfWidth,Constants.Flickr.SearchLatRange.1)
        
        var minLa = max(lat - Constants.Flickr.SearchBBoxHalfWidth,Constants.Flickr.SearchLatRange.0)
        
        
        var retString = String(minLo) + "," + String(minLa) + "," + String(maxLo) + "," + String(maxLa)
        return retString
    }
    //
    func searchByLocation(longitude:Double, latitude:Double,  completionHandler: CompletionHandler){
        let bboxS = bboxString(longitude,  lat:latitude)
        var methodParameters: [String: String!] = [:]
        methodParameters[Constants.FlickrParameterKeys.SafeSearch]=Constants.FlickrParameterValues.UseSafeSearch
        //methodParameters[Constants.FlickrParameterKeys.BoundingBox]=Constants.FlickrParameterValues.
        methodParameters[Constants.FlickrParameterKeys.BoundingBox]=bboxS
        methodParameters[Constants.FlickrParameterKeys.PerPage] = "20"
        methodParameters[Constants.FlickrParameterKeys.Page] = "40"
     
        methodParameters[Constants.FlickrParameterKeys.Extras]=Constants.FlickrParameterValues.MediumURL
        methodParameters[Constants.FlickrParameterKeys.APIKey]=Constants.FlickrParameterValues.APIKey
        methodParameters[Constants.FlickrParameterKeys.Method]=Constants.FlickrParameterValues.SearchMethod
        methodParameters[Constants.FlickrParameterKeys.Format]=Constants.FlickrParameterValues.ResponseFormat
        methodParameters[Constants.FlickrParameterKeys.NoJSONCallback]=Constants.FlickrParameterValues.DisableJSONCallback
        
        searchImageFromFlickrBySearch(methodParameters,  completionHandler: completionHandler)
        
        
    }


    func searchImageFromFlickrBySearch(methodParameters: [String:AnyObject],completionHandler:CompletionHandler) {
        
            let session = NSURLSession.sharedSession()
            let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
            let task = session.dataTaskWithRequest(request){ (data,response,error) in
            
            func displayError(error:String){
                print(error)
            }
            
            guard(error == nil ) else{
                displayError("There was an error with your reuqest: \(error)")
                return
            }
            
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard (data != nil)else {
                displayError("No data was returned by the request!")
                return
            }
            // parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String where stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }

            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject],
                photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                    displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                    return
                    
            }
            
            guard let  pages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int where pages > 0 else {
                displayError("no page found")
                return
                
            }
            let pageLimit = min(pages,40)
            let pageNo = Int32(arc4random_uniform(UInt32(pageLimit ))) + 1
            // TODO: need to make sure not repeat the same random
            debugPrint("found",photoArray.count,pageNo, "from website")
            completionHandler(photoArray: photoArray,pageNo: pageNo)
        }
        task.resume()
    }
    
    //  Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }

}