//
//  HomeController.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/19/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit
import Firebase
import MapKit


class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private let reuseIdentifier = "LocationCell"
    private final let locationInputViewHeight: CGFloat = 200
    
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private let locationInpuActivationtView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let locationTableView = UITableView()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationInpuActivationtView.delegate = self
        locationInputView.delegate = self
        
//        signOut()
        checkIfUserISLoggedIn()
        enableLocationSevices()
    }
    
    // MARK: - API
    
    func checkIfUserISLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let navController = UINavigationController(rootViewController: LoginController())
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
        } else {
            configureUI()
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("Signed out successfully")
        } catch let error {
            print("DEBUG: Failed to sign out with error ", error)
        }
    }
    
    // MARK: - Helper Functions
    
    func configureUI() {
        configureMapView()
        
        view.addSubview(locationInpuActivationtView)
        locationInpuActivationtView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32, centerX: view.centerXAnchor, width: view.frame.width - 64, height: 50)
        
        UIView.animate(withDuration: 2) {
            self.locationInpuActivationtView.alpha = 1
        }
    }
    
    func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
    
    func configureLocationIputView() {
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputViewHeight)
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 1
        }) { (_) in
            UIView.animate(withDuration: 0.3) {
                self.locationTableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }
    
    func configureLocationTableView() {
        locationTableView.delegate = self
        locationTableView.dataSource = self
        
        locationTableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        locationTableView.rowHeight = 60
        locationTableView.tableFooterView = UIView()
        
        locationTableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height - locationInputViewHeight)
        view.addSubview(locationTableView)

    }
}

// MARK: - Location Services

extension HomeController: CLLocationManagerDelegate {
    func enableLocationSevices() {
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            print("DEBUG: Location auth: not determined")
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Location auth: Always")
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: Location auth: when in use")
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }
}

// MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        locationInpuActivationtView.alpha = 0
        configureLocationTableView()
        configureLocationIputView()
    }
}

// MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
    func dismissLocationInputView() {
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.locationTableView.frame.origin.y = self.view.frame.height
        }) { (_) in
            self.locationInputView.removeFromSuperview()
            UIView.animate(withDuration: 0.3) {
                self.locationInpuActivationtView.alpha = 1
            }
        }
    }
}

// MARK: - LocationTableViewDelegate/DataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " "
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = locationTableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationCell
        
        return cell
    }
}

