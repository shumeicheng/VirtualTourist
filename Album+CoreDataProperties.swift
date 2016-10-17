//
//  Album+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 8/12/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Album {

    @NSManaged var pageNo: NSNumber?
    @NSManaged var location: Location?
    @NSManaged var pictures: NSOrderedSet?

}
