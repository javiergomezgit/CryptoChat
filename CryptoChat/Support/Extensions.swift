//
//  Extensions.swift
//  CryptoChat
//
//  Created by Javier Gomez on 12/4/24.
//
import UIKit

final class GoTo {
    static func controller(nameController: String, nameStoryboard: String) -> UIViewController {
        let storyboard = UIStoryboard(name: nameStoryboard, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: nameController)
        
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }
}

final class ShowAlert {
    enum typeAlert {
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
        case paswordsNotMatching
    }
        
    static func alert(type: typeAlert?, error: String?) -> UIAlertController {
        var title = ""
        var message = ""
        var style = UIAlertAction.Style.default
        
        switch type {
        case .wrongEmail:
            title = error!
            message = "Wrong format, fields can not be empty"
            style = .cancel
        case .wrongPassword:
            title = "Password"
            message = "Passwords have to be more than 6 characters"
            style = .cancel
        case .wrongMatching:
            title = "Password"
            message = "Passwords are not matching"
            style = .cancel
        case .successRegister:
            title = "Success"
            message = "User created successfully"
            style = .default
        case .firebaseError:
            title = "Error"
            message = error!
            style = .cancel
        case .none:
            title = "Error"
            message = "Try again later"
            style = .default
        case .usernameExists:
            title = error!
            message = "Username already exists"
            style = .cancel
        case .countryCode:
            title = "Country code"
            message = "Country code shouldn't be empty"
            style = .cancel
        case .phoneNumber:
            title = "Phone number"
            message = "Phone number should be at least 10 digits"
            style = .cancel
        case .usernameEmpty:
            title = "Username"
            message = "Username or email can not be empty"
            style = .cancel
        case .usernameNotFound:
            title = "Username"
            message = "Username not found, try again"
            style = .cancel
        case .wrongCredentials:
            title = "Wrong information"
            message = error!
            style = .cancel
        case .firebaseSuccess:
            title = "Success"
            message = error!
            style = .default
        case .simpleAlert:
            title = "Success"
            message = error!
            style = .default
        case .simpleError:
            title = "Error"
            message = error!
            style = .destructive
        case .paswordsNotMatching:
            title = "Error"
            message = "Passwords are not matching"
            style = .destructive
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: style, handler: nil))
        return alert
    }
}

extension String {
    func removeSymbolPhoneNumber(stringPhoneToClean: String) -> String {
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
    
    var cleanPhoneNumber: String {
        let allowCharacters = Set("1234567890*+#")
        return self.filter {allowCharacters.contains($0) }
    }
    
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    var isEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let valid = emailPred.evaluate(with: self)
        if valid {
            return true
        } else {
            return false
        }
    }
    
    var isValidPassword: Bool {
        let passwordRegEx = "^.*(?=.{6,})(?=.*[A-Z])(?=.*[a-zA-Z])(?=.*\\d)|(?=.*[!#$.%&?]).*$"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        let valid = passwordPred.evaluate(with: self)
        if valid {
            return true
        } else {
            return false
        }
    }
    
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

extension UIButton {

    func roundButton(corner: CGFloat) {
        self.layer.cornerRadius = self.frame.size.height / corner
        self.layer.shadowOpacity = 0.1
        self.layer.shadowRadius = 2.0
        self.layer.shadowOffset = CGSize.init(width: 10, height: 5)
        self.layer.shadowColor = UIColor.lightGray.cgColor
    }
}

extension UITextField {
    fileprivate func setPasswordToggleImage(_ button: UIButton) {
        if (isSecureTextEntry) {
            button.setImage(UIImage(named: "eye"), for: .normal)
            
            if traitCollection.userInterfaceStyle == .light {
                button.tintColor = UIColor(named: "darkblueAccent")!
            } else {
                button.tintColor = UIColor(named: "greenAccent")!
            }
        } else {
            button.setImage(UIImage(named: "eye.slash"), for: .normal)
            if traitCollection.userInterfaceStyle == .light {
                button.tintColor = UIColor(named: "greenAccent")!
            } else {
                button.tintColor = UIColor(named: "mainOrange")!
            }
        }
    }
    
    func enablePasswordToggle() {
        let button = UIButton(type: .custom)
        setPasswordToggleImage(button)

        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.imagePadding = -16 // Adjust padding for left spacing
            button.configuration = config
        } else {
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0) // Fallback for iOS <15
        }

        button.frame = CGRect(x: self.frame.size.width - 25, y: 5, width: 35, height: 35)
        button.addTarget(self, action: #selector(self.togglePasswordView), for: .touchUpInside)
        
        self.rightView = button
        self.rightViewMode = .always
    }
    
    @IBAction func togglePasswordView(_ sender: Any) {
        self.isSecureTextEntry = !self.isSecureTextEntry
        setPasswordToggleImage(sender as! UIButton)
    }
}

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
