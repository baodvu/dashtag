//
//  Location.swift
//  dashtag
//
//  Created by Bao Vu on 10/22/16.
//  Copyright © 2016 Dashtag. All rights reserved.
//

struct Location {
    var title: String
    var owner: String
    var info: String
    var latitude: Double
    var longitude: Double
    var type: Int
    
    init(title: String, owner: String, info: String, latitude: Double, longitude: Double, type: Int) {
        self.title = title
        self.owner = owner
        self.info = info
        self.latitude = latitude
        self.longitude = longitude
        self.type = type
    }
}
