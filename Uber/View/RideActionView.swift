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
}

class RideActionView: UIView {
    
    // MARK: - Properties
    
    var delegate: RideActionViewDelegate?
    var destination: MKPlacemark? {
        didSet {
            titleLabel.text = self.destination?.name
            addressLabel.text = self.destination?.address
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 16)
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
    
    private let infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 30
        
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 30)
        label.text = "X"
        
        view.addSubview(label)
        label.anchor(centerX: view.centerXAnchor, centerY: view.centerYAnchor)

        return view
    }()
    
    private let uberXLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "UberX"
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
        button.setTitle("Confirm UBERX", for: .normal)
        button.setTitleColor(.white, for: .normal)
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
        
        addSubview(infoView)
        infoView.anchor(top: titleStackView.bottomAnchor, paddingTop: 20, centerX: centerXAnchor, width: 60, height: 60)
        
        addSubview(uberXLabel)
        uberXLabel.anchor(top: infoView.bottomAnchor, paddingTop: 8, centerX: centerXAnchor)
        
        addSubview(separatorView)
        separatorView.anchor(top: uberXLabel.bottomAnchor, paddingTop: 4, left: leftAnchor, right: rightAnchor, height: 0.75)
        
        addSubview(actionButton)
        actionButton.anchor(top: separatorView.bottomAnchor, paddingTop: 20, left: leftAnchor, paddingLeft: 12, right: rightAnchor, paddingRight: 12, height: 50)
    }
    
    // MARK: - Selectors
    
    @objc func actionButtonPressed() {
        guard let destination = destination else {return}
        delegate?.uploadTrip(destination)
    }
}
