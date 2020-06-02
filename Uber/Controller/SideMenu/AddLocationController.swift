//
//  AddLocationController.swift
//  Uber
//
//  Created by Ammar Elshamy on 6/2/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit
import MapKit

private let cellIdentifier = "LocationCell"

protocol AddLocationControllerDelegate {
    func updateLocation(locationString: String, type: LocationType)
}

class AddLocationController: UITableViewController {

    // MARK: - Properties
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]()
    private var type: LocationType
    private var location: CLLocation
    var delegate: AddLocationControllerDelegate?
    
    private let searchBar = UISearchBar()

    // MARK: - Lifecycle
    
    init(type: LocationType, location: CLLocation) {
        self.type = type
        self.location = location
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .backgroundColor
        
        configureTableView()
        configureSearchBar()
        configureSearchCompleter()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
        
    // MARK: - Helper Functions

    func configureTableView() {
        tableView.backgroundColor = .white
        tableView.rowHeight = 60
        tableView.register(LocationCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.addShadow()
        tableView.keyboardDismissMode = .onDrag
    }
    
    func configureSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Enter Location"
        searchBar.sizeToFit()
        searchBar.searchTextField.backgroundColor = .white
        searchBar.searchTextField.textColor = .black
        searchBar.searchTextField.leftView?.tintColor = .darkGray
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.titleView = searchBar
    
    }
    
    func configureSearchCompleter() {
        searchCompleter.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        searchCompleter.delegate = self
    }
    
}

// MARK: - TableViewDelegate/DataSource

extension AddLocationController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LocationCell
        
        let result = searchResults[indexPath.row]
        cell.titleLabel.text = result.title
        cell.addressLabel.text = result.subtitle
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        var locationString = result.title + " " + result.subtitle
        if let start = locationString.lastIndex(of: ",") {
            locationString.removeSubrange((start..<locationString.endIndex))
        }
        delegate?.updateLocation(locationString: locationString, type: type)
    }
}

// MARK: - UISearchBarDelegate

extension AddLocationController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension AddLocationController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }
}

