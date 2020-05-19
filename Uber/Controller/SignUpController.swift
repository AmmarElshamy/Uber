//
//  SignUpController.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/19/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit
import Firebase

class SignUpController: UIViewController {
    
    // MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = .white
        return label
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)
    }()
    
    private lazy var emailContainerView: UIView = {
        return UIView().inputContainerView(withImage: UIImage(named: "mail"), textField: self.emailTextField)
    }()
    
    private let fullNameTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Full Name", isSecureTextEntry: false)
    }()
    
    private lazy var fullNameContainerView: UIView = {
        return UIView().inputContainerView(withImage: UIImage(named: "person"), textField: self.fullNameTextField)
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)
    }()
    
    private lazy var passwordContainerView: UIView = {
        return UIView().inputContainerView(withImage: UIImage(named: "lock"), textField: self.passwordTextField)
    }()
    
    private let accountTypeSegmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: ["Rider", "Driver"])
        segmentControl.backgroundColor = .backgroundColor
        segmentControl.tintColor = UIColor(white: 1, alpha: 0.87)
        segmentControl.selectedSegmentIndex = 0
        return segmentControl
    }()
    
    private lazy var accountTypeContainerView: UIView = {
        return UIView().inputContainerView(withImage: UIImage(named: "accountBox"), segmentedControl: self.accountTypeSegmentControl)
    }()
    
    private let signUpButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    private lazy var signUpStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [self.emailContainerView, self.passwordContainerView, self.fullNameContainerView, self.accountTypeContainerView, self.signUpButton])
        stack.axis = .vertical
        stack.distribution = .fill
        stack.spacing = 24
        return stack
    }()
    
    private let haveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Have an account?  ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        attributedTitle.append(NSAttributedString(string: "Login", attributes: [NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .backgroundColor
        
        configureUI()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Helper Functions
    
    func configureUI() {
        
        view.backgroundColor = .backgroundColor

        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, centerX: view.centerXAnchor)
        
        view.addSubview(signUpStackView)
        signUpStackView.anchor(top: titleLabel.bottomAnchor, paddingTop: 40, left: view.leftAnchor, paddingLeft: 16, right: view.rightAnchor, paddingRight: 16)
        
        view.addSubview(haveAccountButton)
        haveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, centerX: view.centerXAnchor, height: 32)
        
}
    
    // MARK: - Selectors
    
    @objc func handleSignUp() {
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        guard let fullName = fullNameTextField.text else {return}
        let accountTypeIndex = accountTypeSegmentControl.selectedSegmentIndex
        
        Auth.auth().createUser(withEmail: email, password: password) { (_, error) in
            if let error = error {
                print("DEBUG: Failed to register user with error ", error)
                return
            }
            
            guard let uid = Auth.auth().currentUser?.uid else {return}
            
            let values = ["email": email, "fullName": fullName, "accountType": accountTypeIndex] as [String: Any]
            
            Database.database().reference().child("users").child(uid).updateChildValues(values) { (error, _) in
                if let error = error {
                    print("DEBUG: Failed to save user data with error ", error)
                    return
                }
                
                print("Successfully Registered user ", fullName)
                guard let homeController = UIApplication.shared.keyWindow?.rootViewController as? HomeController else {return}
                homeController.configureUI()
                self.dismiss(animated: true)
            }
        }
    }
    
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
}
