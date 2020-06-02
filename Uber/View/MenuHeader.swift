//
//  MenuHeader.swift
//  Uber
//
//  Created by Ammar Elshamy on 6/1/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit

class MenuHeader: UIView {
    
    // MARK: - Properties
    
    var user: User? {
        didSet {
            self.fullNameLabel.text = user?.fullName
            self.emailLabel.text = user?.email
        }
    }
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .lightGray
        imageView.layer.cornerRadius = 32
        return imageView
    }()
    
    private let fullNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private lazy var userInfoStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.fullNameLabel, self.emailLabel])
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        return stackView
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Helper Functions
    
    func configureUI() {
        backgroundColor = .backgroundColor
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, paddingTop: 4, left: leftAnchor, paddingLeft: 12, width: 64, height: 64)
        
        addSubview(userInfoStackView)
        userInfoStackView.anchor(left: profileImageView.rightAnchor, paddingLeft: 12, centerY: profileImageView.centerYAnchor)
    }
}
