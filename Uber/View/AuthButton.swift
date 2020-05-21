//
//  AuthButton.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/19/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit

class AuthButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setTitleColor(.white, for: .normal)
        backgroundColor = .disabledButtonColor
        layer.cornerRadius = 5
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 50).isActive = true
        isEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
