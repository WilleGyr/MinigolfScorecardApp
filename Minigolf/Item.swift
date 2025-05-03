//
//  Item.swift
//  Minigolf
//
//  Created by William Gyrulf on 2025-05-04.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
