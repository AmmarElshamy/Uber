//
//  SettingsHeader.swift
//  Uber
//
//  Created by Ammar Elshamy on 6/2/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit

class SettingHeader: UIView {
    
    // MARK: - Properties
    
    var user: User?
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .lightGray
        imageView.layer.cornerRadius = 32
        return imageView
    }()
    
    private lazy var fullNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.text = self.user?.fullName
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = self.user?.email
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
    
    init(frame: CGRect, user: User?) {
        super.init(frame: frame)
        self.user = user
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Helper Functions
    
    func configureUI() {
        backgroundColor = .white
        
        addSubview(profileImageView)
        profileImageView.anchor(left: leftAnchor, paddingLeft: 12, centerY: centerYAnchor, width: 64, height: 64)
        
        addSubview(userInfoStackView)
        userInfoStackView.anchor(left: profileImageView.rightAnchor, paddingLeft: 12, centerY: profileImageView.centerYAnchor)
    }
}
