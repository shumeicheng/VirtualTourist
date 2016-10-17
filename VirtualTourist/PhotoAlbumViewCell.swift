//
//  PhotoAlbumViewCell.swift
//  VirtualTourist
//
//  Created by Shu-Mei Cheng on 7/26/16.
//  Copyright © 2016 Shu-Mei Cheng. All rights reserved.
//

import Foundation
import UIKit
class PhotoAlbumViewCell: UICollectionViewCell{
    
    @IBOutlet weak var imageView: UIImageView! 
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
  
    override var selected: Bool  {
        
        didSet { // controlling highlighting here, it will not work in delegate function!
            if(selected == true){
           
                UIView.animateWithDuration(0.1, animations: {
                    self.imageView.layer.backgroundColor = UIColor.grayColor().CGColor
                    self.imageView.layer.opacity = 0.4
                    
                })

            }else {
                UIView.animateWithDuration(0.1, animations: {
                    self.imageView.layer.backgroundColor = UIColor.clearColor().CGColor
                    self.imageView.layer.opacity = 1.0
                    
                })

                
            }
        }
    }
    
 
 
    
 }