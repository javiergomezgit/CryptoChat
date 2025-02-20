//
//  PasscodeViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 12/27/24.
//

import UIKit
import FirebaseAuth
import SmileLock

class PasscodeViewController: UIViewController {
    
    public var completion: ((Bool) -> (Void))?
    
    @IBOutlet weak var passwordStackView: UIStackView!
    @IBOutlet weak var label: UILabel!
    
    var passwordContainerView: PasswordContainerView!
    var kPasswordDigit = 6
    var generalPasscode = ""
    var tempPasscode: String?
    var verified = false
    
    var statusOfPasscode = status.settingPasscode
    
    enum status {
        case settingPasscode
        case verifyPasscode
        case changePasscode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create PasswordContainerView
        passwordContainerView = PasswordContainerView.create(in: passwordStackView, digit: kPasswordDigit)
        passwordContainerView.delegate = self
        passwordContainerView.deleteButtonLocalizedTitle = "Delete"
        
        
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            //customize password UI
            passwordContainerView.tintColor = UIColor.systemBlue.withAlphaComponent(0.7)
            passwordContainerView.highlightedColor = UIColor.systemBlue.withAlphaComponent(0.7)
            label.textColor = UIColor.label
        case .dark:
            //customize password UI
            passwordContainerView.tintColor = UIColor.systemOrange.withAlphaComponent(0.7)
            passwordContainerView.highlightedColor = UIColor.systemOrange.withAlphaComponent(0.7)
            label.textColor = UIColor.label
        @unknown default:
            //customize password UI
            passwordContainerView.tintColor = UIColor.green.withAlphaComponent(0.7)
            passwordContainerView.highlightedColor = UIColor.green.withAlphaComponent(0.7)
            label.textColor = UIColor.label
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.defineColorMode()
        
        if statusOfPasscode == .verifyPasscode {
            downloadGeneralPasscode()
        }
        if statusOfPasscode == .changePasscode {
            label.text = "Current Passcode"
            downloadGeneralPasscode()
        }
        if statusOfPasscode == .settingPasscode {
            label.text = "Set Passcode"
        }
    }
    
    private func downloadGeneralPasscode() {
        //download from firebase if status is verify or change
        let userID = Auth.auth().currentUser?.uid
        UserDatabaseController.shared.downloadGeneralPasscode(userID: userID!) { passcode, error in
            if error == nil {
                self.generalPasscode = self.encryptPasscode(passcode: passcode!, encrypt: false)
            }
        }
    }
    
    private func updateGeneralPasscode() {
        let encryptedPasscode = encryptPasscode(passcode: generalPasscode, encrypt: true)
        UserDatabaseController.shared.updateGeneralPasscode(userID: Auth.auth().currentUser!.uid, newPasscode: encryptedPasscode) { error in
            if error == nil {
                UserDefaults.standard.setValue(true, forKey: "unlocked")
                UserDefaults.standard.setValue(encryptedPasscode, forKey: "general_passcode")
                
                self.completion!(true)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    private func encryptPasscode(passcode: String, encrypt: Bool) -> String {
        let encryptedNumbers: [Int: String] = [0:"5", 1:"#", 2:"@", 3:"(",4:"B",5:"J",6:"+",7:"!",8:"3",9:">"]
        let passcodeArray = Array(passcode)
        var split1 = ""
        var split2 = ""
        var newPasscode = ""
        
        if encrypt {
            var encryptedPass = [String]()
            for num in passcodeArray {
                let numToInt = num.wholeNumberValue
                encryptedPass.append(encryptedNumbers[numToInt!]!)
            }
            
            for (i, number) in encryptedPass.enumerated() {
                if i < 3 {
                    split1 += String(number)
                } else {
                    split2 += String(number)
                }
            }
            newPasscode = "\(split2)\(split1)"
        } else {
            var found = ""
            for char in passcodeArray {
                for dic in encryptedNumbers {
                    if dic.value == String(char) {
                        found.append(String(dic.key))
                    }
                }
            }
            
            for (i, number) in found.enumerated() {
                if i < 3 {
                    split1 += String(number)
                } else {
                    split2 += String(number)
                }
            }
            newPasscode = "\(split2)\(split1)"
        }
        return newPasscode
    }
    
}

extension PasscodeViewController: PasswordInputCompleteProtocol {
    func passwordInputComplete(_ passwordContainerView: PasswordContainerView, input: String) {
        if validation(input) {
            validationSuccess()
        } else {
            validationFail()
        }
    }
    
    func touchAuthenticationComplete(_ passwordContainerView: PasswordContainerView, success: Bool, error: Error?) {
        if success {
            self.validationSuccess()
        } else {
            passwordContainerView.clearInput()
        }
    }
}

private extension PasscodeViewController {
    func validation(_ input: String) -> Bool {
        var isValid = false
        
        switch statusOfPasscode {
        case .settingPasscode:
            isValid = true
            generalPasscode = input
        case .verifyPasscode:
            if input == generalPasscode {
                isValid = true
            }
        case .changePasscode:
            if input == generalPasscode && !verified {
                passwordContainerView.clearInput()
                label.text = "New Passcode"
                verified = true
                break
            } else {
                if tempPasscode == nil && verified {
                    tempPasscode = input
                    passwordContainerView.clearInput()
                    label.text = "Confirm Passcode"
                } else {
                    if tempPasscode == input {
                        self.generalPasscode = input
                        isValid = true
                    }
                }
            }
        }
        return isValid
    }
    
    func validationSuccess() {
        switch statusOfPasscode {
        case .settingPasscode:
            updateGeneralPasscode()
        case .verifyPasscode:
            UserDefaults.standard.setValue(true, forKey: "unlocked")
            let encryptedPasscode = encryptPasscode(passcode: generalPasscode, encrypt: true)
            UserDefaults.standard.setValue(encryptedPasscode, forKey: "general_passcode")
            
            self.completion!(true)
            dismiss(animated: true, completion: nil)
        case .changePasscode:
            updateGeneralPasscode()
        }
    }
    
    func validationFail() {
        UserDefaults.standard.setValue(false, forKey: "unlocked")
        completion!(false)
        
        passwordContainerView.wrongPassword()
    }
}
