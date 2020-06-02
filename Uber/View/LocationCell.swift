//
//  LocationCell.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/20/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit
import MapKit

class LocationCell: UITableViewCell {
    
    // MARK: - Properties
    
    var placemark: MKPlacemark? {
        didSet {
            titleLabel.text = self.placemark?.name
            addressLabel.text = self.placemark?.address
        }
    }
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        return label
    }()
    
    let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [self.titleLabel, self.addressLabel])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        return stack
    }()
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helper Functions
    
    func configureUI() {
        addSubview(stackView)
        stackView.anchor(left: leftAnchor, paddingLeft: 12, centerY: centerYAnchor)
    }
}
