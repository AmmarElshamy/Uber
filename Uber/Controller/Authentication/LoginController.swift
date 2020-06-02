//
//  LoginController.swift
//  Uber
//
//  Created by Ammar Elshamy on 5/18/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit
import Firebase

class LoginController: UIViewController{
    
    // MARK: - Properties
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = .white
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)
        textField.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return textField
    }()
    
    private lazy var emailContainerView: UIView = {
        return UIView().inputContainerView(withImage: UIImage(named: "mail"), textField: self.emailTextField)
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)
        textField.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return textField
    }()
    
    private lazy var passwordContainerView: UIView = {
        return UIView().inputContainerView(withImage: UIImage(named: "lock"), textField: self.passwordTextField)
    }()
    
    private let loginButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()
    
    private lazy var loginStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [self.emailContainerView, self.passwordContainerView, self.loginButton])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 24
        return stack
    }()
    
    private let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    // MARK: - Helper Functions
    
    func configureUI() {
        configureNavigationBar()
        
        view.backgroundColor = .backgroundColor

        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, centerX: view.centerXAnchor)
        
        view.addSubview(loginStackView)
        loginStackView.anchor(top: titleLabel.bottomAnchor, paddingTop: 40, left: view.leftAnchor, paddingLeft: 16, right: view.rightAnchor, paddingRight: 16)
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, centerX: view.centerXAnchor, height: 32)
        
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
    
    // MARK: - Selectors
    
    @objc func handleLogin() {
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        
        loginButton.isEnabled = false
        
        Auth.auth().signIn(withEmail: email, password: password) { (_, error) in
            if let error = error {
                print("DEBUG: Failed to login with error ", error)
                self.loginButton.isEnabled = true
                return
            }
            
            print("Successfully logged user in..")
            guard let containerController = UIApplication.shared.keyWindow?.rootViewController as? ContainerController else {return}
            containerController.homeController.handleLoggedIn()
            self.dismiss(animated: true)

        }
    }
    
    @objc func handleShowSignUp() {
        navigationController?.pushViewController(SignUpController(), animated: true)
    }
    
    @objc func handleTextInputChange() {
        let isFormValid = emailTextField.text?.count ?? 0 > 0 && passwordTextField.text?.count ?? 0 > 0
        
        if isFormValid {
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.mainBlueTint
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        }
        
    }
}
