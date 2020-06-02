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

struct RiderService {
    
    static let shared = RiderService()
    
    func fetchDrivers(location: CLLocation, completion: @escaping(User) -> Void) {
        let geoFire = GeoFire(firebaseRef: driverLocationsRef)
        
        driverLocationsRef.observe(.value, with: { (snapshot) in
            geoFire.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in
                Service.shared.fetchUserData(uid: uid) { (user) in
                    var driver = user
                    driver.location = location
                    completion(driver)
                }
            })
        }) { (error) in
            print("Failed to fetch driver location")
        }
    }
    
    func uploadTrip(from pickupCoordinates: CLLocationCoordinate2D, to destinationCoordintes: CLLocationCoordinate2D, completion: @escaping() -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordintes.latitude, destinationCoordintes.longitude]
        
        let values = ["pickupCoordinates": pickupArray, "destinationCoordinates": destinationArray, "state": TripState.requested.rawValue] as [String: Any]
        
        tripsRef.child(uid).updateChildValues(values) { (error, _) in
            if let error = error {
                print("DEBUG: Failed to uplaod trip with error ", error)
                return
            }
            completion()
        }
    }
    
    func observeCurrentTrip(completion: @escaping(Trip) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        
        tripsRef.child(uid).observe(.value) { (snapshot) in
            guard let dicitonary = snapshot.value as? [String: Any] else {return}
            
            let trip = Trip(passengerUid: uid, dictionary: dicitonary)
            completion(trip)
        }
    }
    
    func deleteTrip(completion: @escaping() -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        tripsRef.child(uid).removeValue{ (error, _) in
            if let error = error {
                print("DEBUG: Faild to cancel current trip ", error)
                return
            }
            completion()
        }
    }
    
    func saveLocation(type: LocationType, locationString: String, completion: @escaping() -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        usersRef.child(uid).child(type.desctiption.lowercased()).setValue(locationString) { (error, _) in
            if let error = error {
                print("Faild to save ", type.desctiption, " location with error ", error)
                return
            }
            completion()
        }
    }
}
