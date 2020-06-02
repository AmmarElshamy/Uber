//
//  SettingsController.swift
//  Uber
//
//  Created by Ammar Elshamy on 6/2/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit

private let cellIdentifier = "LocationCell"

enum LocationType: Int, CaseIterable {
    case home
    case work
    
    var desctiption: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        }
    }
}

protocol SettingControllerDelegate {
    func updateUser(_ user: User?)
}

class SettingsController: UITableViewController {

    // MARK: - Properties
        
    var user: User?
    var delegate: SettingControllerDelegate?
    
    private lazy var header: SettingHeader = {
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 100)
        let view = SettingHeader(frame: frame, user: user)
        return view
    }()
        
    // MARK: - Lifecycle

    init(user: User?) {
        super.init(nibName: nil, bundle: nil)
        self.user = user
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .backgroundColor
        
        configureNavigationBar()
        configureTableView()
    }
        
    // MARK: - Helper Functions

    func configureTableView() {
        tableView.backgroundColor = .white
        tableView.isScrollEnabled = false
        tableView.rowHeight = 60
        tableView.register(LocationCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableHeaderView = header
        tableView.tableFooterView = UIView()
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.backgroundColor = .black
        navigationController?.navigationBar.tintColor = .white
        navigationItem.title = "Settings"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "exit")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismissal))
    }
    
    func locationText(type: LocationType) -> String {
        switch type {
        case .home:
            return user?.homeLocation ?? "Add Home"
        case .work:
            return user?.workLocation ?? "Add Work"
        }
    }
    
    // MARK: - Selectors

    @objc func handleDismissal() {
        self.dismiss(animated: true)
    }
}

// MARK: - TableViewDelegate/DataSource

extension SettingsController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocationType.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LocationCell
        
        guard let type = LocationType(rawValue: indexPath.row) else { return cell }
        
        cell.titleLabel.text = type.desctiption
        cell.addressLabel.text = locationText(type: type)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        view.backgroundColor = .black
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.text = "Favourites"
        
        view.addSubview(titleLabel)
        titleLabel.anchor(left: view.leftAnchor, paddingLeft: 16, centerY: view.centerYAnchor)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let type = LocationType(rawValue: indexPath.row) else {return}
        guard let location = LocationHandler.shared.locationManager.location else {return}
        let controller = AddLocationController(type: type, location: location)
        controller.delegate = self
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - AddLocationControllerDelegate

extension SettingsController: AddLocationControllerDelegate {
    func updateLocation(locationString: String, type: LocationType) {
        RiderService.shared.saveLocation(type: type, locationString: locationString) {
            self.navigationController?.popViewController(animated: true)
            
            switch type {
            case .home:
                self.user?.homeLocation = locationString
            case .work:
                self.user?.workLocation = locationString
            }
            
            self.delegate?.updateUser(self.user)
            self.tableView.reloadData()
        }
    }
}
