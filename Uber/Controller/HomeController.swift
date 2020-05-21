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
    
    private let cellIdentifier = "LocationCell"
    private let annotationIdentifier = "DriverAnnotation"
    private final let locationInputViewHeight: CGFloat = 200
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let locationInpuActivationtView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let locationTableView = UITableView()
    
    private var user: User? {
        didSet {
            locationInputView.userFullName = user?.fullName
        }
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        locationInpuActivationtView.delegate = self
        locationInputView.delegate = self
        
//        signOut()
        checkIfUserIsLoggedIn()
    }
    
    // MARK: - API
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let navController = UINavigationController(rootViewController: LoginController())
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
        } else {
            handleLoggedIn()
        }
    }
    
    func handleLoggedIn() {
        enableLocationSevices()
        fetchUserData()
        fetchDrivers()
    }
    
    func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        Service.shared.fetchUserData(uid: currentUid) { (user) -> (Void) in
            self.user = user
            self.configureUI()
        }
    }
    
    func fetchDrivers() {
        guard let myLocation = locationManager?.location else {return}
        Service.shared.fetchDrivers(location: myLocation) { (driver) in
            guard let driverCoordinate = driver.location?.coordinate else {return}
            let driverAnnotation = DriverAnnotation(uid: driver.uid, coordinate: driverCoordinate)
            self.addDriverAnnotation(driverAnnotation: driverAnnotation)
        }
    }
    
    func addDriverAnnotation(driverAnnotation: DriverAnnotation) {
        let annotationExists = mapView.annotations.contains { (annotation) -> Bool in
            guard let annotation = annotation as? DriverAnnotation else {return false}
            if annotation.uid == driverAnnotation.uid {
                annotation.updateAnnotationPosition(withCoordinate: driverAnnotation.coordinate)
                return true
            }
            return false
        }
        
        if !annotationExists {
            mapView.addAnnotation(driverAnnotation)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let navController = UINavigationController(rootViewController: LoginController())
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
            print("DEBUG: Signed out successfully")
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
        mapView.delegate = self
        
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
        
        locationTableView.register(LocationCell.self, forCellReuseIdentifier: cellIdentifier)
        
        locationTableView.rowHeight = 60
        locationTableView.tableFooterView = UIView()
        
        locationTableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height - locationInputViewHeight)
        view.addSubview(locationTableView)

    }
}

// MARK: - Location Services

extension HomeController {
    
    func enableLocationSevices() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            print("DEBUG: Location auth: not determined")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Location auth: Always")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: Location auth: when in use")
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager?.requestAlwaysAuthorization()
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
        let cell = locationTableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LocationCell
        
        return cell
    }
}

// MARK: - MKMpViewDelegate

extension HomeController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? DriverAnnotation else { return nil }
        let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        view.image = #imageLiteral(resourceName: "annotation")
        return view
    }
}

