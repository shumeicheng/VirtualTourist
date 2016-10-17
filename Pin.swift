//
//  Pin.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 8/1/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    convenience init( long:Int64, lat: Int64, context : NSManagedObjectContext){
        if let ent = NSEntityDescription.entityForName("Location",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.longitude = String(long)
            self.latitude = String (lat)
            print("store", String(long), String(lat))
            //self.album = Album(context: context)
        }else{
            fatalError("Unable to find Entity name!")
        }
        
        
    }

}
