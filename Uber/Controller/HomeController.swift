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

enum ActionButtonState {
    case showSideMenu
    case dismissAction
    
    init() {
        self = .showSideMenu
    }
}

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private var searchResults = [MKPlacemark]()
    private var route: MKRoute?
    private var user: User? {
        didSet {
            locationInputView.userFullName = user?.fullName
        }
    }
    private var trip: Trip?
    
    private let cellIdentifier = "LocationCell"
    private let annotationIdentifier = "DriverAnnotation"
    private let locationInputViewHeight: CGFloat = 200
    private let locationManager = LocationHandler.shared.locationManager
    private var actionButtonState = ActionButtonState()
    
    // UI Views
    private let mapView = MKMapView()
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "menu")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    private let locationInpuActivationtView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let locationTableView = UITableView()
    private let rideActionView = RideActionView()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        locationInpuActivationtView.delegate = self
        
//         signOut()
        enableLocationSevices()
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
        self.fetchUserData() {
            self.configureUI()
            if self.user?.accountType == .rider {
                self.fetchDrivers()
            } else {
                self.observeTrips()
            }
        }
    }
        
    func fetchUserData(completion: @escaping() -> Void) {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        Service.shared.fetchUserData(uid: currentUid) { (user) -> (Void) in
            self.user = user
            completion()
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
    
    func observeTrips() {
        Service.shared.observeTrips() { trip in
            self.trip = trip
            self.configurePickupController()
        }
    }
    
    func observeCurrentTrip(completion: @escaping() -> Void) {
        Service.shared.observeCurrentTrip() { trip in
            self.trip = trip
            completion()
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
    
    // MARK: - UI Helper Functions
    
    func configureUI() {
        configureMapView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 16, left: view.leftAnchor, paddingLeft: 16, width: 30, height: 30)
        
        guard user?.accountType == .rider else {return}
        
        view.addSubview(locationInpuActivationtView)
        locationInpuActivationtView.anchor(top: actionButton.bottomAnchor, paddingTop: 32, centerX: view.centerXAnchor, width: view.frame.width - 64, height: 50)
        
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
    
    func configureActionButton(state: ActionButtonState) {
        switch state {
        case .dismissAction:
            self.actionButton.setImage(UIImage(named: "backArrow")?.withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonState = .dismissAction
        case .showSideMenu:
            self.actionButton.setImage(UIImage(named: "menu")?.withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonState = .showSideMenu
        }
    }
    
    func configureLocationIputView() {
        locationInputView.delegate = self
        
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
        
        view.addSubview(locationTableView)
        locationTableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: view.frame.height - locationInputViewHeight)
    }
    
    func dismissLocationInputView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.locationTableView.frame.origin.y = self.view.frame.height
        }, completion: completion)
        
        locationInputView.removeFromSuperview()
    }
    
    func configureRideActionView(destintion: MKPlacemark) {
        rideActionView.delegate = self
        rideActionView.destination = destintion
        
        view.addSubview(rideActionView)
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: 300)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.rideActionView.frame.origin.y = self.view.frame.height - self.rideActionView.frame.height
        })
    }
    
    func dismissRideActionView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.rideActionView.frame.origin.y = self.view.frame.height
        }, completion: completion)
        
        rideActionView.removeFromSuperview()
    }
    
    func configurePickupController() {
        let controller = PickupController(trip: self.trip!)
        controller.modalPresentationStyle = .fullScreen
        controller.delegate = self
        self.present(controller, animated: true)
    }
    
    // MARK: - Map Helper Functions
    
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
    
    func searchBy(naturalLanguageQuery: String, completion: @escaping ([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, _) in
            guard let response = response else {return}
            
            response.mapItems.forEach { (item) in
                results.append(item.placemark)
            }
            
            completion(results)
        }
    }
    
    func generatePolyline(to destintion: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destintion
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { (response, _) in
            guard let response = response else {return}
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else {return}
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { (annotation) in
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
        
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed() {
        switch actionButtonState {
        case .showSideMenu:
            print("DEBUG: Menu")
            
        case .dismissAction:
            removeAnnotationsAndOverlays()
            dismissRideActionView()
            self.mapView.showAnnotations(mapView.annotations, animated: true)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.locationInpuActivationtView.alpha = 1
                self.configureActionButton(state: .showSideMenu)
            })
        }
    }
    
}

// MARK: - Location Services

extension HomeController: CLLocationManagerDelegate {
    
    func enableLocationSevices() {
        
        locationManager?.delegate = self
        
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
        if status != .authorizedAlways {
            locationManager?.requestAlwaysAuthorization()
            enableLocationSevices()
        }
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let route = self.route else {return MKOverlayRenderer()}
        let polyline = route.polyline
        let lineRenderer = MKPolylineRenderer(polyline: polyline)
        lineRenderer.strokeColor = .mainBlueTint
        lineRenderer.lineWidth = 3
        return lineRenderer
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
    
    func excuteSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { (results) in
            self.searchResults = results
            self.locationTableView.reloadData()
        }
    }
    
    func returnBack() {
        dismissLocationInputView { _ in
            self.locationInputView.removeFromSuperview()
            UIView.animate(withDuration: 0.3, animations: {
                self.locationInpuActivationtView.alpha = 1
            })
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
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = locationTableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LocationCell
        
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        configureActionButton(state: .dismissAction)
        
        dismissLocationInputView { _ in
            let placemark = self.searchResults[indexPath.row]
            let annotation = MKPointAnnotation()
            annotation.coordinate = placemark.coordinate
            annotation.title = placemark.title
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)
                        
            self.generatePolyline(to: MKMapItem(placemark: placemark))
            self.configureRideActionView(destintion: placemark)
            self.mapView.zoomToFit(annotations: [annotation, self.mapView.userLocation])
        }
    }
}

// MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ destination: MKPlacemark) {
        guard let currentCoordinates = locationManager?.location?.coordinate else {return}
        let destinationCoordinates = destination.coordinate
        
        Service.shared.uploadTrip(from: currentCoordinates, to: destinationCoordinates) { (ref) in
            self.dismissRideActionView()
            self.shouldPresentLoadingView(true, message: "Finding you a ride...")
            self.observeCurrentTrip() {
                if self.trip?.state == .accepted {
                    self.shouldPresentLoadingView(false, message: nil)
                }
            }
        }
    }
}

// MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(trip: Trip) {
        self.trip = trip
        self.dismiss(animated: true, completion: nil)
    }
}
