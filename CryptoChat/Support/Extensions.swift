//
//  Extensons.swift
//  CryptoChat
//
//  Created by Javier Gomez on 7/7/21.
//

import Foundation
import UIKit

final class GoTo {
    static func controller(nameController: String, nameStoryboard: String) -> UIViewController{
        let storyBoard : UIStoryboard = UIStoryboard(name: nameStoryboard, bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: nameController)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }
}


final class ShowAlert {
    enum typeAlertCredentials {
        case wrongEmail
        case wrongPassword
        case wrongMatching
        case successRegister
        case firebaseError
        case usernameExists
        case countryCode
        case phoneNumber
        case usernameEmpty
        case usernameNotFound
        case wrongCredentials
        case firebaseSuccess
        case simpleAlert
        case simpleError
    }
    static func alertsCredentials(type: typeAlertCredentials?, error: String?) -> UIAlertController {
        var title = ""
        var message = ""
        var style = UIAlertAction.Style.default
        
        switch type {
        case .wrongEmail:
            title = error!
            message = "Wrong format, fields can not be empty".localized()
            style = .cancel
        case .wrongPassword:
            title = "Password".localized()
            message = "Passwords have to be more than 6 characters".localized()
            style = .cancel
        case .wrongMatching:
            title = "Password".localized()
            message = "Passwords are not matching".localized()
            style = .cancel
        case .successRegister:
            title = "Success".localized()
            message = "User created successfully".localized()
            style = .default
        case .firebaseError:
            title = "Error"
            message = error!
            style = .cancel
        case .none:
            title = "Error"
            message = "Try again later".localized()
            style = .default
        case .usernameExists:
            title = error!
            message = "Username already exists".localized()
            style = .cancel
        case .countryCode:
            title = "Country code".localized()
            message = "Country code shouldn't be empty".localized()
            style = .cancel
        case .phoneNumber:
            title = "Phone number".localized()
            message = "Phone number should be at least 10 digits".localized()
            style = .cancel
        case .usernameEmpty:
            title = "Username".localized()
            message = "Username or email can not be empty".localized()
            style = .cancel
        case .usernameNotFound:
            title = "Username".localized()
            message = "Username not found, try again".localized()
            style = .cancel
        case .wrongCredentials:
            title = "Wrong information".localized()
            message = error!
            style = .cancel
        case .firebaseSuccess:
            title = "Success".localized()
            message = error!
            style = .default
        case .simpleAlert:
            title = "Success".localized()
            message = error!
            style = .default
        case .simpleError:
            title = "Error".localized()
            message = error!
            style = .destructive
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: style, handler: nil))
        return alert
    }

}

extension String {
    func cleanPhoneNumber(stringPhoneToClean: String) -> String {
        var phoneNumber = stringPhoneToClean.replacingOccurrences(of: "(", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: ")", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
        phoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        return phoneNumber
    }
    
    var cleanUsername: String {
            let allowCharacters = Set("abcdefghijklmnopqrstuvwxyz1234567890_")
            return self.filter {allowCharacters.contains($0) }
    }
    
//    func removeSpecialCharsFromString(text: String) -> String {
//        let okayChars = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890_")
//        return text.filter {okayChars.contains($0) }
//    }
    
    var cleanPhoneNumber: String {
        let allowCharacters = Set("1234567890*+#")
        return self.filter {allowCharacters.contains($0) }
    }
    
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}


//Delegate for keyboard
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func defineColorMode() {
        // let currentMode = self.traitCollection.userInterfaceStyle
        
        if let darkMode = UserDefaults.standard.value(forKey: "dark_mode") as? Bool {
            if darkMode {
                self.overrideUserInterfaceStyle = .dark
                self.navigationController?.navigationBar.tintColor = .white
                self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
            } else {
                self.overrideUserInterfaceStyle = .light
                self.navigationController?.navigationBar.tintColor = .black
                self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
            }
        } else {
            self.overrideUserInterfaceStyle = .unspecified
            let currentMode = self.traitCollection.userInterfaceStyle

            if currentMode == .dark {
                self.navigationController?.navigationBar.tintColor = .white
                self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
            } else {
                self.navigationController?.navigationBar.tintColor = .black
                self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
            }
        }
    }
}

extension UITextField {
    func addRoundedShadow(_ textField: UITextField) {
       
        self.borderStyle = .none
        self.backgroundColor = UIColor.systemGroupedBackground
            
        self.layer.cornerRadius = self.frame.size.height / 4
            
        self.layer.borderWidth = 0.25
        self.layer.borderColor = UIColor.white.cgColor
            
        self.layer.shadowOpacity = 0.2
        self.layer.shadowRadius = 4.0
        self.layer.shadowOffset = CGSize.init(width: 10, height: 5)
        self.layer.shadowColor = UIColor.gray.cgColor
    }
}


extension UIButton {
    func roundButton(_ button: UIButton) {
                   
        self.layer.cornerRadius = self.frame.size.height / 2

        self.layer.shadowOpacity = 0.1
        self.layer.shadowRadius = 2.0
        self.layer.shadowOffset = CGSize.init(width: 10, height: 5)
        self.layer.shadowColor = UIColor.lightGray.cgColor
    }
}

extension UIImageView {
    func cornersImage(circleImage: Bool, border: Bool, roundedCorner: CGFloat?) {
        if border {
            self.layer.borderWidth = 0.5
            self.layer.borderColor = UIColor.lightGray.cgColor
        }
        self.layer.masksToBounds = false

        if circleImage {
            self.layer.cornerRadius = self.frame.height / 2
        } else {
            if roundedCorner != nil {
                self.layer.cornerRadius = self.frame.height / roundedCorner!
            } else {
                self.layer.cornerRadius = self.frame.height / 10 //In case that is not round image and user forgets to set the corners
            }
        }
        self.clipsToBounds = true
    }
}

extension String {
    func localized() -> String {
        return NSLocalizedString(
            self,
            tableName: "Localizable",
            bundle: .main,
            value: self,
            comment: self)
    }
}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

