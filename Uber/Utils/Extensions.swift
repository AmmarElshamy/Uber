//
//  Extensions.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/18/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit
import MapKit

extension UIView {
    
    func anchor(top: NSLayoutYAxisAnchor? = nil, paddingTop: CGFloat = 0, bottom: NSLayoutYAxisAnchor? = nil, paddingBottom: CGFloat = 0, left: NSLayoutXAxisAnchor? = nil, paddingLeft: CGFloat = 0, right: NSLayoutXAxisAnchor? = nil, paddingRight: CGFloat = 0, centerX: NSLayoutXAxisAnchor? = nil, centerY: NSLayoutYAxisAnchor? = nil, width: CGFloat = 0, height: CGFloat = 0) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if let centerX = centerX {
            centerXAnchor.constraint(equalTo: centerX).isActive = true
        }
        
        if let centerY = centerY {
            centerYAnchor.constraint(equalTo: centerY).isActive = true
        }
        
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    func inputContainerView(withImage image: UIImage?, textField: UITextField? = nil, segmentedControl: UISegmentedControl? = nil) -> UIView {
        let view = UIView()
        
        let imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.image = image
            imageView.alpha = 0.87
            return imageView
        }()
        
        if let textField = textField {
            view.anchor(height: 50)
            
            view.addSubview(imageView)
            imageView.anchor(left: view.leftAnchor, paddingLeft: 8, centerY: view.centerYAnchor, width: 24, height: 24)

            view.addSubview(textField)
            textField.anchor(left: imageView.rightAnchor, paddingLeft: 8, right: view.rightAnchor, paddingRight: 0, centerY: view.centerYAnchor)
        }
        
        if let segmentedControl = segmentedControl {
            view.anchor(height: 70)

            view.addSubview(imageView)
            imageView.anchor(top: view.topAnchor, left: view.leftAnchor, paddingLeft: 8, width: 24, height: 24)
            
            view.addSubview(segmentedControl)
            segmentedControl.anchor(top: imageView.bottomAnchor, paddingTop: 8, bottom: view.bottomAnchor, paddingBottom: 8, left: view.leftAnchor, paddingLeft: 8, right: view.rightAnchor, paddingRight: 8)
        }
        
        let separatorView: UIView = {
            let view = UIView()
            view.backgroundColor = .lightGray
            return view
        }()
        
        view.addSubview(separatorView)
        separatorView.anchor(bottom: view.bottomAnchor, left: view.leftAnchor, paddingLeft: 8, right: view.rightAnchor, height: 0.75)
        
        return view
    }
    
    func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.55
        layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        layer.masksToBounds = false
    }
}

extension UIColor {
    
    static let backgroundColor = UIColor.rgb(red: 25, green: 25, blue: 25)
    static let mainBlueTint = UIColor.rgb(red: 17, green: 154, blue: 232)
    static let disabledButtonColor = UIColor.rgb(red: 149, green: 204, blue: 244)
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
}

extension UITextField {
    func textField(withPlaceholder placeholder: String, isSecureTextEntry: Bool) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .white
        textField.keyboardAppearance = .dark
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        textField.isSecureTextEntry = isSecureTextEntry
        return textField
    }
}

extension MKPlacemark {
    var address: String? {
        get {
            guard let subThoroughfare = subThoroughfare else {return nil}
            guard let thoroughfare = thoroughfare else {return nil}
            guard let locality = locality else {return nil}
            guard let adminArea = administrativeArea else {return nil}
            
            return subThoroughfare + " " + thoroughfare + ", " + locality + ", " + adminArea
        }
    }
}

extension MKMapView {
    func zoomToFit(annotations: [MKAnnotation]) {
        var zoomRect = MKMapRect.null
        
        annotations.forEach { (annotation) in
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.01, height: 0.01)
            zoomRect = zoomRect.union(pointRect)
        }
        
        let insets = UIEdgeInsets(top: 100, left: 100, bottom: 300, right: 100)
        setVisibleMapRect(zoomRect, edgePadding: insets, animated: true)
    }
}

extension UIViewController {
    
    func presentAlertController(withTitle title: String, withMessage message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func shouldPresentLoadingView(_ present: Bool, message: String? = nil) {
        present ? presentLoadingView(message: message) : dismissLoadingView()
    }
    
    fileprivate func presentLoadingView(message: String? = nil) {
        let loadingView = UIView()
        loadingView.frame = view.frame
        loadingView.backgroundColor = .black
        loadingView.alpha = 0
        loadingView.tag = 1
        
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.color = .white
        indicator.center = view.center
        
        let label = UILabel()
        label.text = message
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .white
        label.alpha = 0.7
        
        view.addSubview(loadingView)
        loadingView.addSubview(indicator)
        loadingView.addSubview(label)
        label.anchor(top: indicator.bottomAnchor, paddingTop: 32, centerX: loadingView
            .centerXAnchor)
        
        indicator.startAnimating()
        UIView.animate(withDuration: 0.3) {
            loadingView.alpha = 0.7
        }
    }
    
    fileprivate func dismissLoadingView() {
        view.subviews.forEach { (subView) in
            if subView.tag == 1 {
                UIView.animate(withDuration: 0.3, animations: {
                    subView.alpha = 0
                }) { _ in
                    subView.removeFromSuperview()
                }
            }
        }
    }
}
