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

protocol HomeControllerDelegate {
    func handleMenuToggle(withUser user: User)
}

private enum HomeActionButtonState {
    case sideMenu
    case dismissAction
    
    init() {
        self = .sideMenu
    }
}

private enum RegionType: String {
    case pickup
    case destination
}

private let locationCellIdentifier = "LocationCell"
private let defaultCellIdentifier = "Cell"

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private var searchResults = [MKPlacemark]()
    private var savedLocations = [String: MKPlacemark]()
    private var route: MKRoute?
    var user: User? {
        didSet {
            locationInputView.userFullName = user?.fullName
            configureSavedLocations()
        }
    }
    private var trip: Trip?
    var delegate: HomeControllerDelegate?
    
    private let annotationIdentifier = "DriverAnnotation"
    private let locationInputViewHeight: CGFloat = 200
    private let locationManager = LocationHandler.shared.locationManager
    private var actionButtonState = HomeActionButtonState()
    
    // UI Views
    private let mapView = MKMapView()
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "menu")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    private let locationInputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let locationTableView = UITableView()
    private let rideActionView = RideActionView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        locationInputActivationView.delegate = self
        
        enableLocationSevices()
        checkIfUserIsLoggedIn()
    }
    
    // MARK: - Shared API
    
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
            if self.user?.accountType == .passenger {
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
    
    // MARK: - Passenger API
    
    func fetchDrivers() {
        guard let myLocation = locationManager?.location else {return}
        RiderService.shared.fetchDrivers(location: myLocation) { (driver) in
            guard let driverCoordinate = driver.location?.coordinate else {return}
            let driverAnnotation = DriverAnnotation(uid: driver.uid, coordinate: driverCoordinate)
            self.addDriverAnnotation(driverAnnotation: driverAnnotation)
        }
    }
    
    func observeCurrentTrip() {
        RiderService.shared.observeCurrentTrip() { trip in
            self.trip = trip
            
            switch trip.state {
            case .requested:
                break
                
            case .denied:
                RiderService.shared.deleteTrip {
                    self.actionButton.sendActions(for: .touchUpInside) // return to the initial state
                    self.shouldPresentLoadingView(false)
                    self.presentAlertController(withTitle: "Oops", withMessage: "It looks like we couldn't find you a driver, please try again")
                }
                
            case .accepted:
                self.shouldPresentLoadingView(false, message: nil)
                
                var annotations = [MKAnnotation]()
                self.mapView.annotations.forEach { (annotation) in
                    if let driverAnnotation = annotation as? DriverAnnotation {
                        if driverAnnotation.uid == trip.driverUid {
                            annotations.append(driverAnnotation)
                        }
                    } else if let userAnnotation = annotation as? MKUserLocation {
                        annotations.append(userAnnotation)
                    }
                }
                self.mapView.zoomToFit(annotations: annotations)
                
                guard let driverUid = trip.driverUid else {return}
                Service.shared.fetchUserData(uid: driverUid) { driver in
                    self.configureRideActionView(user: driver, state: .tripAccepted)
                }
                
            case .driverArrived:
                self.rideActionView.state = .driverArrived
                
            case .inProgress:
                self.rideActionView.state = .tripInProgress
                
                var annotations = [MKAnnotation]()
                self.mapView.annotations.forEach { (annotation) in
                    if let destinationAnnotation = annotation as? MKPointAnnotation {
                        annotations.append(destinationAnnotation)
                    } else if let userAnnotation = annotation as? MKUserLocation {
                        annotations.append(userAnnotation)
                    }
                }
                self.mapView.zoomToFit(annotations: annotations)
                
            case .arrivedAtDestination:
                self.rideActionView.state = .endTrip
                
            case .completed:
                RiderService.shared.deleteTrip {
                    self.actionButton.sendActions(for: .touchUpInside) // return to the initial state
                    self.presentAlertController(withTitle: "Trip Completed", withMessage: "We hope you enjoyed your trip")
                }
            }
        }
    }
    
    // MARK: - Driver API
    
    func observeTrips() {
        DriversService.shared.observeTrips() { trip in
            self.trip = trip
            self.configurePickupController()
        }
    }
    
    func observeCancelledTrip(_ trip: Trip) {
        DriversService.shared.observeTripCancelled(trip: trip){
            self.dismissRideActionView()
            self.removeAnnotationsAndOverlays()
            self.centerMapOnUserLocation()
            self.stopMonitoringRegion(withType: .pickup, coordinates: trip.pickupCoordinates)
            self.presentAlertController(withTitle: "Oops",
                                        withMessage: "The passenger has cancelled this trip.")
        }
    }
    
    // MARK: - UI Helper Functions
    
    func configureUI() {
        configureMapView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 16, left: view.leftAnchor, paddingLeft: 16, width: 30, height: 30)
        
        guard user?.accountType == .passenger else {return}
        
        view.addSubview(locationInputActivationView)
        locationInputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32, centerX: view.centerXAnchor, width: view.frame.width - 64, height: 50)
        
        UIView.animate(withDuration: 2) {
            self.locationInputActivationView.alpha = 0.9
        }
    }
    
    func configureMapView() {
        mapView.delegate = self
        
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
    
    fileprivate func configureActionButton(state: HomeActionButtonState) {
        switch state {
        case .dismissAction:
            self.actionButton.setImage(UIImage(named: "backArrow")?.withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonState = .dismissAction
        case .sideMenu:
            self.actionButton.setImage(UIImage(named: "menu")?.withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonState = .sideMenu
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
        
        locationTableView.register(LocationCell.self, forCellReuseIdentifier: locationCellIdentifier)
        locationTableView.register(UITableViewCell.self, forCellReuseIdentifier: defaultCellIdentifier)
        
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
    
    func configureRideActionView(user: User? = nil, destination: MKPlacemark? = nil, state: RideActionViewState) {
        rideActionView.delegate = self
        rideActionView.user = user
        rideActionView.destination = destination
        rideActionView.state = state
        
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
    
    func configureSavedLocations() {
        guard let user = user else {return}
        
        if let homeLoction = user.homeLocation {
            geocodeAddressString(homeLoction) { placemark in
                self.savedLocations["Home"] = placemark
                self.locationTableView.reloadData()
            }
        }
        
        if let workLocation = user.workLocation {
            geocodeAddressString(workLocation) { placemark in
                self.savedLocations["Work"] = placemark
                self.locationTableView.reloadData()
            }
        }
    }
    
    func geocodeAddressString(_ addressString: String, completion: @escaping(MKPlacemark) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            guard let clPlacemark = placemarks?.first else {return}
            let placemark = MKPlacemark(placemark: clPlacemark)
            completion(placemark)
        }
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
            if let annotation = annotation as? MKPointAnnotation{
                mapView.removeAnnotation(annotation)
            }
        }
        
        if mapView.overlays.count > 0 {
            mapView.overlays.forEach { (overlay) in
                mapView.removeOverlay(overlay)
            }
        }
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager?.location?.coordinate else {return}
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 2000,
                                        longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func startMonitorRegion(withType type: RegionType, coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
        locationManager?.startMonitoring(for: region)
    }
    
    fileprivate func stopMonitoringRegion(withType type: RegionType, coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
        locationManager?.stopMonitoring(for: region)
    }
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed() {
        switch actionButtonState {
        case .sideMenu:
            delegate?.handleMenuToggle(withUser: self.user!)
            
        case .dismissAction:
            removeAnnotationsAndOverlays()
            dismissRideActionView()
            self.centerMapOnUserLocation()
            
            UIView.animate(withDuration: 0.3, animations: {
                self.locationInputActivationView.alpha = 0.9
                self.configureActionButton(state: .sideMenu)
            })
        }
    }
    
}

// MARK: - CLLocationManagerDelegate

extension HomeController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region.identifier == RegionType.pickup.rawValue {
            print("DEBUG: Start monitoring passenger region ", region)
        } else if region.identifier == RegionType.destination.rawValue {
            print("DEBUG: Start monitoring destination region ", region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        locationManager?.stopMonitoring(for: region)
        guard let trip = self.trip else {return}
        
        if region.identifier == RegionType.pickup.rawValue {
            print("DEBUG: Entered passenger region")
            rideActionView.state = .pickupPassenger
            DriversService.shared.updateTripState(trip: trip, state: .driverArrived)
            
        } else if region.identifier == RegionType.destination.rawValue {
            print("DEBUG: Entered destination region")
            rideActionView.state = .endTrip
            DriversService.shared.updateTripState(trip: trip, state: .arrivedAtDestination)
        }
        
    }
    
    // Location Authorization
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

// MARK: - MKMapViewDelegate

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
    
    // Update driver location
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user else {return}
        guard user.accountType == .driver else {return}
        guard let location = userLocation.location else {return}
        DriversService.shared.updateDriverLocation(location: location)
        centerMapOnUserLocation()
    }
}


// MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        locationInputActivationView.alpha = 0
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
                self.locationInputActivationView.alpha = 0.9
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
        return section == 0 ? (savedLocations.count > 0 ? "Saved Locations" : "") : (searchResults.count > 0 ? "Results" : "")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? savedLocations.count : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = locationTableView.dequeueReusableCell(withIdentifier: defaultCellIdentifier, for: indexPath)
            
            if indexPath.row == 0, savedLocations["Home"] != nil {
                cell.textLabel?.text = "Home"
            } else {
                cell.textLabel?.text = "Work"
            }
            return cell
        }
        
        let cell = locationTableView.dequeueReusableCell(withIdentifier: locationCellIdentifier, for: indexPath) as! LocationCell
        
        cell.placemark = searchResults[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        configureActionButton(state: .dismissAction)
        
        dismissLocationInputView { _ in
            var placemark: MKPlacemark
            if indexPath.section == 0 {
                guard let locationType = self.locationTableView.cellForRow(at: indexPath)?.textLabel?.text else {return}
                placemark = self.savedLocations[locationType]!
            } else {
                placemark = self.searchResults[indexPath.row]
            }
            self.mapView.addAndSelectAnnotation(forPlacemark: placemark)
            self.generatePolyline(to: MKMapItem(placemark: placemark))
            self.configureRideActionView(destination: placemark, state: .requestRide)
            self.mapView.zoomToFit(annotations: [placemark, self.mapView.userLocation])
        }
        
        locationTableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ destination: MKPlacemark) {
        guard let currentCoordinates = locationManager?.location?.coordinate else {return}
        let destinationCoordinates = destination.coordinate
        
        RiderService.shared.uploadTrip(from: currentCoordinates, to: destinationCoordinates) {
            self.dismissRideActionView()
            self.shouldPresentLoadingView(true, message: "Finding you a ride...")
            self.observeCurrentTrip()
        }
    }
    
    func cancelTrip() {
        RiderService.shared.deleteTrip {
            self.actionButton.sendActions(for: .touchUpInside)
        }
    }
    
    func pickupPassenger() {
        guard let trip = self.trip else {return}
        DriversService.shared.updateTripState(trip: trip, state: .inProgress) {
            self.rideActionView.state = .tripInProgress
            self.removeAnnotationsAndOverlays()
            
            let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
            self.mapView.addAndSelectAnnotation(forPlacemark: placemark)
            self.generatePolyline(to: MKMapItem(placemark: placemark))
            self.mapView.zoomToFit(annotations: [placemark, self.mapView.userLocation])
            
            self.startMonitorRegion(withType: .destination, coordinates: trip.destinationCoordinates)
        }
    }
    
    func dropOffPassenger() {
        guard let trip = self.trip else {return}
        DriversService.shared.updateTripState(trip: trip, state: .completed) {
            self.removeAnnotationsAndOverlays()
            self.centerMapOnUserLocation()
            self.dismissRideActionView()
        }
    }
}

// MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(trip: Trip) {
        self.trip = trip
        
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        mapView.addAndSelectAnnotation(forPlacemark: placemark)
        generatePolyline(to: MKMapItem(placemark: placemark))
        
        mapView.zoomToFit(annotations: mapView.annotations)
        
        startMonitorRegion(withType: .pickup, coordinates: trip.pickupCoordinates)
        
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { passenger in
                self.configureRideActionView(user: passenger, state: .tripAccepted)
                self.observeCancelledTrip(trip)
            }
        }
    }
}
