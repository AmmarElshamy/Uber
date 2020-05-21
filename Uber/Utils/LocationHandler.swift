//
//  LocationHandler.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/20/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import CoreLocation

class LocationHandler: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationHandler()
    
    var locationManager: CLLocationManager!
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
}
