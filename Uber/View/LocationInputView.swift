//
//  LocationInputView.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/19/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit

protocol LocationInputViewDelegate {
    func returnBack()
    func excuteSearch(query: String)
}

class LocationInputView: UIView {

    // MARK: - Properties
    
    var delegate: LocationInputViewDelegate?
    var userFullName: String? {
        didSet {
            titleLabel.text = userFullName
        }
    }
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "backArrow")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .darkGray
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let startLocationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Current Location"
        tf.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
        tf.font = .systemFont(ofSize: 14)
        tf.isEnabled = false
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 35))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        
        return tf
    }()
    
    private let destinationLocationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter a destination.."
        tf.backgroundColor = .lightGray
        tf.returnKeyType = .search
        tf.font = .systemFont(ofSize: 14)
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 35))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        
        return tf
    }()
    
    private let startIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 3
        return view
    }()
    
    private let destinationIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 3
        return view
    }()
    
    private let linkingView: UIView = {
        let view = UIView()
        view.backgroundColor = .darkGray
        return view
    }()
    
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureView()
        destinationLocationTextField.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helper Functions
    
    func configureView() {
        backgroundColor = .white
        alpha = 0
        addShadow()
        
        addSubview(backButton)
        backButton.anchor(top: topAnchor, paddingTop: 42, left: leftAnchor, paddingLeft: 12, width: 24, height: 24)
        
        addSubview(titleLabel)
        titleLabel.anchor(centerX: centerXAnchor, centerY: backButton.centerYAnchor)
        
        addSubview(startLocationTextField)
        startLocationTextField.anchor(top: backButton.bottomAnchor, paddingTop: 4, left: leftAnchor, paddingLeft: 40, right: rightAnchor, paddingRight: 40, height: 35)
        
        addSubview(destinationLocationTextField)
        destinationLocationTextField.anchor(top: startLocationTextField.bottomAnchor, paddingTop: 12, left: leftAnchor, paddingLeft: 40, right: rightAnchor, paddingRight: 40, height: 35)
        
        addSubview(startIndicatorView)
        startIndicatorView.anchor(left: leftAnchor, paddingLeft: 20, centerY: startLocationTextField.centerYAnchor, width: 6, height: 6)
        
        addSubview(destinationIndicatorView)
        destinationIndicatorView.anchor(left: leftAnchor, paddingLeft: 20, centerY: destinationLocationTextField.centerYAnchor, width: 6, height: 6)
        
        addSubview(linkingView)
        linkingView.anchor(top: startIndicatorView.bottomAnchor, paddingTop: 4, bottom: destinationIndicatorView.topAnchor, paddingBottom: 4, centerX: startIndicatorView.centerXAnchor, width: 0.5)
    }
   
    // MARK: - Selectors
    
    @objc func handleBackTapped() {
        delegate?.returnBack()
    }
}

// MARK: - TextFieldDelegate

extension LocationInputView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = textField.text else {return false}
        delegate?.excuteSearch(query: query)
        return true
    }
}
