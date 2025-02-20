//
//  PhoneViewController.swift
//  CryptoChat
//
//  Created by Javier Gomez on 12/2/24.
//

import UIKit
import SafariServices
import FirebaseAuth

class PhoneViewController: UIViewController {
    
    var countryCode = "+1"
    var verificationID = ""
    var register = false
    var phoneNumber = ""
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var sendRegisterButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        codeTextField.isHidden = true
        sendRegisterButton.roundButton(corner: 4)
        findCountryCode()
    }
    
    func findCountryCode() {
        var countryRegion = "US"
        if #available(iOS 16, *) {
            countryRegion = Locale.current.region!.identifier
        } else {
            // Fallback on earlier versions
            countryRegion = Locale.current.regionCode!
        }
        
        let countries = Countries()
        
        let countryCode = countries.countries.compactMap{
            $0.countryCode == countryRegion ? $0 : nil
        }
        
        self.countryCode = "+\(countryCode.first!.phoneExtension)"
    }
    
    @IBAction func sendCodeRegisterPressed(_ sender: UIButton) {
        
        if register == false {
            let number = "\(countryCode)\(phoneNumberTextField.text!.cleanPhoneNumber)"
            sendRegisterButton.setTitle("Send Code", for: .normal)
            sendCode(phoneNumber: number)
        } else {
            registerPhoneNumber()
        }
    }
    
    
    private func sendCode(phoneNumber: String) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if error == nil {
                print (verificationID!)
                self.verificationID = verificationID!
                self.codeTextField.isHidden = false
                self.register = true
                self.sendRegisterButton.setTitle("Verify Code", for: .normal)
            } else {
                print ("alert user")
                self.register = false
                self.codeTextField.isHidden = true
            }
        }
    }
    
    func registerPhoneNumber() {
        let code = codeTextField.text
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code!)
        
        Auth.auth().signIn(with: credential) { result, error in
            if error == nil {
                print ("success")
                guard let isNewUser = result!.additionalUserInfo?.isNewUser else {
                    return
                }
                self.phoneNumber = result!.user.phoneNumber!
                
                if isNewUser == true {
                    //go to register the a new user place
                    let characters = "abcdefghijklmnopqrstuvwxyz"
                    let randomString = String((0..<4).compactMap { _ in characters.randomElement() })
                    let lastFourDigits = String(self.phoneNumber.suffix(4))
                    
                    let username = "\(randomString)_\(lastFourDigits)"
                    let newUser = UserInformation(idUser: result!.user.uid, fullname: "", username: username, emailAddress: "", phoneNumber: self.phoneNumber, profileImageUrl: nil)
                    UserDatabaseController.shared.createNewUser(with: newUser, signUpMethod: .phoneNumber) { createdUser in
                        if createdUser == true {
                            print ("User created successfully")
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "UsernameViewController") as! UsernameViewController
                            
                            vc.modalPresentationStyle = .fullScreen
                            vc.modalTransitionStyle = .crossDissolve
                            
                            vc.username = username
                            vc.newUser = true
                            vc.methodSignup = 2
                            
                            self.show(vc, sender: nil)
                            
                        } else {
                            print("Error creating user")
                        }
                    }
                } else {
                    //if no new user then go  to ssimply sign in
                    self.present(GoTo.controller(nameController: "MainCryptoChat", nameStoryboard: "Main"), animated: true)
                }
            } else {
                print ("alert user")
                self.present(ShowAlert.alert(type: .simpleError, error: "ERROR something went wrong"), animated: true)
            }
        }
    }
    
    
    
    
    @IBAction func openTerms(_ sender: Any) {
        if let url = URL(string: "https://www.locknkey.app/terms-of-service/") {
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
    }
    
    @IBAction func openPrivacy(_ sender: Any) {
        if let url = URL(string: "https://www.locknkey.app/privacy-policy/") {
            let svc = SFSafariViewController(url: url)
            present(svc, animated: true, completion: nil)
        }
    }
    
}
