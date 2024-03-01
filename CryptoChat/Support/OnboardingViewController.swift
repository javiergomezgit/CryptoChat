//
//  OnboardingViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 9/17/21.
//

import UIKit
import SwiftyOnboard


class OnboardingViewController: UIViewController {
    
    var swiftyOnboard: SwiftyOnboard!
    
    override func viewWillAppear(_ animated: Bool) {
        swiftyOnboard = SwiftyOnboard(frame: view.frame)
        view.addSubview(swiftyOnboard)
        swiftyOnboard.dataSource = self
        swiftyOnboard.delegate = self
    }
    
    @objc func handleContinue(sender: UIButton) {
        let index = sender.tag
        swiftyOnboard?.goToPage(index: index + 1, animated: true)
        
        if index == 2 {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func handleSkip() {
        swiftyOnboard?.goToPage(index: 2, animated: true)
    }
}

extension OnboardingViewController: SwiftyOnboardDataSource, SwiftyOnboardDelegate {
    
    func swiftyOnboardNumberOfPages(_ swiftyOnboard: SwiftyOnboard) -> Int {
        return 3
    }
    
    func swiftyOnboardPageForIndex(_ swiftyOnboard: SwiftyOnboard, index: Int) -> SwiftyOnboardPage? {
        
        let page = SwiftyOnboardPage()
        
        /*
         Changed original code of SwiftyOnboardPage
         let margin = self.layoutMarginsGuide
         imageView.translatesAutoresizingMaskIntoConstraints = false
         imageView.leftAnchor.constraint(equalTo: margin.leftAnchor, constant: 30).isActive = true
         imageView.rightAnchor.constraint(equalTo: margin.rightAnchor, constant: -5).isActive = true
         imageView.topAnchor.constraint(equalTo: margin.topAnchor, constant: 5).isActive = true
         imageView.heightAnchor.constraint(equalTo: margin.heightAnchor, multiplier: 0.8).isActive = true
         */
        
        page.subTitle.isHidden = true
        page.title.isHidden = true
        
        page.backgroundColor = UIColor(named: "mainOrange")
        
        let nameOfImage = ("page\(index+1)")
        //page.imageView.backgroundColor = UIColor.black
        page.imageView.image = UIImage(named: nameOfImage)
   
        return page
    }
    
    func swiftyOnboardViewForOverlay(_ swiftyOnboard: SwiftyOnboard) -> SwiftyOnboardOverlay? {
        let overlay = SwiftyOnboardOverlay()
        
        //Setup targets for the buttons on the overlay view:
        overlay.skipButton.addTarget(self, action: #selector(handleSkip), for: .touchUpInside)
        overlay.continueButton.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        
        //Setup for the overlay buttons:
        overlay.continueButton.titleLabel?.font = UIFont(name: "Lato-Bold", size: 20)
        overlay.continueButton.setTitleColor(UIColor.white, for: .normal)
        overlay.skipButton.setTitleColor(UIColor.white, for: .normal)
        overlay.skipButton.titleLabel?.font = UIFont(name: "Lato-Heavy", size: 20)
        
        return overlay
    }
    
    func swiftyOnboardOverlayForPosition(_ swiftyOnboard: SwiftyOnboard, overlay: SwiftyOnboardOverlay, for position: Double) {
        let currentPage = round(position)
        overlay.pageControl.currentPage = Int(currentPage)
        print(Int(currentPage))
        overlay.continueButton.tag = Int(position)
        
        if currentPage == 0.0 || currentPage == 1.0 {
            overlay.continueButton.setTitle("Continue", for: .normal)
            overlay.skipButton.setTitle("Skip", for: .normal)
            overlay.skipButton.isHidden = false
        } else {
            overlay.continueButton.setTitle("Get Started!", for: .normal)
            overlay.skipButton.isHidden = true
        }
    }
    
    
}
