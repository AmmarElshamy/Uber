//
//  RideActionView.swift
//  Uber
//
//  Created by Ammar Elshamy on 1/1/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit
import MapKit

protocol RideActionViewDelegate {
    func uploadTrip(_: MKPlacemark)
    func cancelTrip()
    func pickupPassenger()
    func dropOffPassenger()
}

enum RideActionViewState {
    case requestRide
    case tripAccepted
    case driverArrived
    case pickupPassenger
    case tripInProgress
    case endTrip
    
    init() {
        self = .requestRide
    }
}

enum RideActionButtonState {
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropOff
    
    var description: String {
        switch self {
        case .requestRide:
            return "CONFIRM UBERX"
        case .cancel:
            return "CANCEL RIDE"
        case .getDirections:
            return "GET DIRECTIONS"
        case .pickup:
            return "PICKUP PASSENGER"
        case .dropOff:
            return "DROP OFF PASSENGER"
        }
    }
    
    init() {
        self = .requestRide
    }
}

class RideActionView: UIView {
    
    // MARK: - Properties
    
    var currentState = RideActionViewState()
    var actionButtonState = RideActionButtonState()
    var delegate: RideActionViewDelegate?
    var user: User?
    var destination: MKPlacemark?
    var state = RideActionViewState() {
        didSet{
            configureUI(withState: state)
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var titleStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [self.titleLabel, self.addressLabel])
        sv.axis = .vertical
        sv.spacing = 4
        sv.distribution = .fillEqually
        return sv
    }()
    
    private let symbolView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 30
        return view
    }()
    
    private let symbolViewLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30)
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18)
        label.textAlignment = .center
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private lazy var actionButton: UIButton = {
        let button  = UIButton(type: .system)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helper Fuctions
    
    func configureUI() {
        backgroundColor = .white
        addShadow()
        
        addSubview(titleStackView)
        titleStackView.anchor(top: topAnchor, paddingTop: 18, centerX: centerXAnchor)
        
        addSubview(symbolView)
        symbolView.anchor(top: titleStackView.bottomAnchor, paddingTop: 20, centerX: centerXAnchor, width: 60, height: 60)
        
        symbolView.addSubview(symbolViewLabel)
        symbolViewLabel.anchor(centerX: symbolView.centerXAnchor, centerY: symbolView.centerYAnchor)
        
        addSubview(infoLabel)
        infoLabel.anchor(top: symbolView.bottomAnchor, paddingTop: 8, centerX: centerXAnchor)
        
        addSubview(separatorView)
        separatorView.anchor(top: infoLabel.bottomAnchor, paddingTop: 4, left: leftAnchor, right: rightAnchor, height: 0.75)
        
        addSubview(actionButton)
        actionButton.anchor(top: separatorView.bottomAnchor, paddingTop: 20, left: leftAnchor, paddingLeft: 12, right: rightAnchor, paddingRight: 12, height: 50)
    }
    
    func configureUI(withState state: RideActionViewState) {
        switch state {
            
        case .requestRide:
            guard let destination = destination else {return}
            titleLabel.text = destination.name
            addressLabel.text = destination.address
            symbolViewLabel.text = "X"
            infoLabel.text = "UberX"
            actionButtonState = .requestRide
            actionButton.setTitle(actionButtonState.description, for: .normal)
            
        case .tripAccepted:
            guard let user = user else {return}
            
            if user.accountType == .passenger {                 // Driver Side
                titleLabel.text = "En Route To Passenger"
                actionButtonState = .getDirections
                actionButton.setTitle(actionButtonState.description, for: .normal)
            } else {                                           // Passenger Side
                titleLabel.text = "Driver En Route"
                actionButtonState = .cancel
                actionButton.setTitle(actionButtonState.description, for: .normal)
            }
            
            addressLabel.text = ""
            symbolViewLabel.text = String(user.fullName.first ?? " ")
            infoLabel.text = user.fullName
        
        case .driverArrived:
            titleLabel.text = "Driver Has Arrived"
            addressLabel.text = "Please meet the driver at pickup location"
            
        case .pickupPassenger:
            titleLabel.text = "Arrived At Passenger Location"
            actionButtonState = .pickup
            actionButton.setTitle(actionButtonState.description, for: .normal)
            
        case .tripInProgress:
            guard let user = user else {return}
            
            if user.accountType == .passenger {                 // Driver Side
                actionButtonState = .getDirections
                actionButton.setTitle(actionButtonState.description, for: .normal)
            } else {                                           // Passenger Side
                actionButton.setTitle("TRIP IN PROGRESS", for: .normal)
                actionButton.isEnabled = false
            }
            
            titleLabel.text = "En Route To Destination"
            addressLabel.text = ""
            
        case .endTrip:
            guard let user = user else {return}
            
            if user.accountType == .passenger {                // Driver Side
                actionButtonState = .dropOff
                actionButton.setTitle(actionButtonState.description, for: .normal)
            } else {                                           // Passenger Side
                actionButton.setTitle("TRIP COMPLETED", for: .normal)
                actionButton.isEnabled = false
            }
            
            titleLabel.text = "Arrived At Destination"
        }
    }
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed() {
        switch actionButtonState {
        case .requestRide:
            guard let destination = destination else {return}
            delegate?.uploadTrip(destination)
        case .cancel:
            delegate?.cancelTrip()
        case .getDirections:
            print("DEBUG: handle getDirections")
        case .pickup:
            delegate?.pickupPassenger()
        case .dropOff:
            delegate?.dropOffPassenger()
        }
    }
}
