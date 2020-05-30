//
//  DriverService.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/22/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import Firebase

extension Service {
    
    func observeTrips(completion: @escaping(Trip) -> Void) {
        tripsRef.observe(.childAdded) { (snapshot) in
            guard let dicitonary = snapshot.value as? [String: Any] else {return}
            
            let trip = Trip(passengerUid: snapshot.key, dictionary: dicitonary)
            completion(trip)
        }
    }
    
    func acceptTrip(trip: Trip, completion: @escaping() -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let values = ["driverUid": uid,
                      "state": TripState.accepted.rawValue] as [String: Any]
        
        tripsRef.child(trip.passengerUid).updateChildValues(values) { (error, _) in
            if let error = error {
                print("DEBUG: failed to accept trip with error ", error)
                return
            }
            completion()
        }
    }
    
    func observeTripCancelled(trip: Trip, completion: @escaping() -> Void) {
        tripsRef.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { (_) in
            completion()
        }
    }
}
