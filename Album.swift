//
//  Album.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 7/31/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import CoreData


class Album: NSManagedObject {

    convenience init(  location: Location , context: NSManagedObjectContext){
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entityForName("Album",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.pageNo = 0
            // set pageNo when loading pictures, now create empty album
            self.location = location
            
            
        }else{
            fatalError("Unable to find Entity name!")
        }
        
        
    }

}
