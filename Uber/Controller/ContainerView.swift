//
//  ContainerView.swift
//  Uber
//
//  Created by Ammar Elshamy on 6/1/20.
//  Copyright © 2020 Ammar Elshamy. All rights reserved.
//

import UIKit
import Firebase

class ContainerController: UIViewController {
    
    // MARK: - Properties
    
    var homeController = HomeController()
    private var menuController = MenuController()
    private var menuIsExpanded = false
    private var blackView = UIView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .backgroundColor
        
        configureHomeController()
        configureMenuController()
        configureBlackView()
    }
    
    override var prefersStatusBarHidden: Bool {
        return menuIsExpanded
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    // MARK: - API
    
    func logOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let navController = UINavigationController(rootViewController: LoginController())
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
            print("DEBUG: Signed out successfully")
        } catch let error {
            print("DEBUG: Failed to sign out with error ", error)
        }
    }
        
    // MARK: - Helper Functions
    
    func configureHomeController() {
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
        homeController.delegate = self
    }
    
    func configureMenuController(){
        addChild(menuController)
        menuController.didMove(toParent: self)
        view.insertSubview(menuController.view, at: 0)
        menuController.delegate = self
    }
    
    func configureBlackView() {
        blackView.frame = self.view.frame
        blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        blackView.alpha = 0
        
        view.addSubview(blackView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        blackView.addGestureRecognizer(tap)
    }
    
    func animateMenu(shouldExpand: Bool, completion: ((Bool) -> Void)? = nil) {
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = self.view.frame.width - 80
                self.blackView.frame.origin.x = self.view.frame.width - 80
                self.blackView.alpha = 1
            })
        } else {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = 0
                self.blackView.frame.origin.x = 0
                self.blackView.alpha = 0
            }, completion: completion)
        }
        
        animateStatusBar()
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    // MARK: - Selectors
    
    @objc func dismissMenu() {
        menuIsExpanded.toggle()
        animateMenu(shouldExpand: menuIsExpanded)
    }
}

// MARK: - HomeControllerDelegate

extension ContainerController: HomeControllerDelegate {
    func handleMenuToggle(withUser user: User) {
        menuController.user = user
        menuIsExpanded.toggle()
        animateMenu(shouldExpand: menuIsExpanded)
    }
}

// MARK: - HomeControllerDelegate

extension ContainerController: MenuControllerDelegate {
    func didSelect(option: MenuOptions, user: User?) {
        menuIsExpanded.toggle()
        animateMenu(shouldExpand: menuIsExpanded) { _ in
            switch option {
            case .yourTrips:
                return
                
            case .settings:
                let controller = SettingsController(user: user)
                controller.delegate = self
                let navController = UINavigationController(rootViewController: controller)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
                
            case .logout:
                let alert = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
                    self.logOut()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
                
            }
        }
    }
}

// MARK: - SettingControllerDelegate

extension ContainerController: SettingControllerDelegate {
    func updateUser(_ user: User?) {
        homeController.user = user
    }
}
