//
//  TaskCancelingTableViewCell.swift
//  VirtualTourist
//
//  Created by Raphael Neuenschwander on 29.06.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

class TaskCancelingCollectionViewCell: UICollectionViewCell {
    // This property uses a property observer. Any time its value is set , it cancels the previous NSRULSessionTask
    
    var taskToCancelIfCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
