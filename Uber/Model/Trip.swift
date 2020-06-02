//
//  Trip.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/22/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import CoreLocation

enum TripState: Int {
    case requested
    case denied
    case accepted
    case driverArrived
    case inProgress
    case arrivedAtDestination
    case completed
}

struct Trip {
    
    let passengerUid: String
    let pickupCoordinates: CLLocationCoordinate2D
    let destinationCoordinates: CLLocationCoordinate2D
    var driverUid: String?
    var state: TripState
    
    init(passengerUid: String, dictionary: [String: Any]) {
        self.passengerUid = passengerUid
        
        let pickupCoordinates = dictionary["pickupCoordinates"] as! [CLLocationDegrees]
        self.pickupCoordinates = CLLocationCoordinate2D(latitude: pickupCoordinates[0], longitude: pickupCoordinates[1])
        
        
        let destinationCoordinates = dictionary["destinationCoordinates"] as! [CLLocationDegrees]
        self.destinationCoordinates = CLLocationCoordinate2D(latitude: destinationCoordinates[0], longitude: destinationCoordinates[1])
        
        
        self.driverUid = dictionary["driverUid"] as? String ?? ""
        
        let state = dictionary["state"] as! Int
        self.state = TripState(rawValue: state)!
    }
}

