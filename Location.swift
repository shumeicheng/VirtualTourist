//
//  Location.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 7/31/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import CoreData


class Location: NSManagedObject {

 
   convenience init( long:Int64, lat: Int64, context : NSManagedObjectContext){
        if let ent = NSEntityDescription.entityForName("Location",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.longitude = NSNumber(longLong: long)
            self.latitude =  NSNumber(longLong: lat)
            Album(location: self,context: context)// create one empty album
            
        }else{
            fatalError("Unable to find Entity name!")
        }
        

    }
}
