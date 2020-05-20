//
//  LocationInputActivationView.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/19/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit

protocol LocationInputActivationViewDelegate {
    func presentLocationInputView()
}

class LocationInputActivationView: UIView {
    
    // MARK: - Properties
    
    var delegate: LocationInputActivationViewDelegate?
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    private let placeholderLaber: UILabel = {
        let label = UILabel()
        label.text = "Where to?"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .darkGray
        return label
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePresentLocationInputView))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helper Functions
    
    func configureUI() {
        backgroundColor = .white
        alpha = 0
        addShadow()
        
        addSubview(indicatorView)
        indicatorView.anchor(left: leftAnchor, paddingLeft: 16, centerY: centerYAnchor, width: 6, height: 6)
        
        addSubview(placeholderLaber)
        placeholderLaber.anchor(left: indicatorView.rightAnchor, paddingLeft: 20, centerY: centerYAnchor)
    }
    
    // MARK: - Selectors
    
    @objc func handlePresentLocationInputView() {
        delegate?.presentLocationInputView()
    }

}
