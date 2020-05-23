//
//  RiderService.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/22/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import Firebase
import GeoFire
import CoreLocation

extension Service {
    func fetchDrivers(location: CLLocation, completion: @escaping(User) -> Void) {
        let geoFire = GeoFire(firebaseRef: driverLocationsRef)
        
        driverLocationsRef.observe(.value, with: { (snapshot) in
            geoFire.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in
                self.fetchUserData(uid: uid) { (user) in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
        }) { (error) in
            print("Failed to fetch driver location")
        }
    }
    
    func uploadTrip(from pickupCoordinates: CLLocationCoordinate2D, to destinationCoordintes: CLLocationCoordinate2D, completion: @escaping(DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordintes.latitude, destinationCoordintes.longitude]
        
        let values = ["pickupCoordinates": pickupArray, "destinationCoordinates": destinationArray, "state": TripState.requested.rawValue] as [String: Any]
        
        tripsRef.child(uid).updateChildValues(values) { (error, ref) in
            if let error = error {
                print("DEBUG: Failed to uplaod trip with error ", error)
                return
            }
            completion(ref)
        }
    }
}
