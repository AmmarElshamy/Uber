//
//  Service.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/20/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import Firebase
import CoreLocation
import GeoFire

let dbRef = Database.database().reference()
let usersRef = dbRef.child("users")
let driverLocationsRef = dbRef.child("driver-locations")

struct Service {
    
    static let shared = Service()
    
    func fetchUserData(uid: String, completion: @escaping(User) -> Void) {
        usersRef.child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else {return}
            completion(User(uid: uid, dictionary: dictionary))
            
        }) { (error) in
            print("DEBUG: Fialed to fetch user data with error ", error)
        }
    }
    
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
}
