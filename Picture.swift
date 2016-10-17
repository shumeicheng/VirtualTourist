//
//  Picture.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 7/31/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import CoreData


class Picture: NSManagedObject {

    convenience init( urlString: String,album: Album,  context: NSManagedObjectContext){
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entityForName("Picture",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
           
            self.urlString = urlString
            self.album = album
            self.picImage = nil
          
        }else{
            fatalError("Unable to find Entity name!")
        }

        
    }
}
