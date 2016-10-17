//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 8/1/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var longitude: String?
    @NSManaged var latitude: String?

}
