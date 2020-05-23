//
//  Service.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/20/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import Firebase

let dbRef = Database.database().reference()
let usersRef = dbRef.child("users")
let driverLocationsRef = dbRef.child("driver-locations")
let tripsRef = dbRef.child("trips")

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

}
